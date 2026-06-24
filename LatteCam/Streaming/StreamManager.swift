import AVFoundation
import HaishinKit
import RTMPHaishinKit
import SwiftUI
import UIKit
import VideoToolbox

@MainActor
final class StreamManager: ObservableObject {
    @Published private(set) var status: StreamStatus = .stopped
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var configuration: StreamConfiguration

    private let mixer = MediaMixer()
    private var connection: RTMPConnection?
    private var stream: RTMPStream?
    private var runTask: Task<Void, Never>?
    private var isCapturePrepared = false
    private var shouldReconnect = false
    private var isStopping = false
    private var shouldResumeAfterForeground = false

    init(configuration: StreamConfiguration = .load()) {
        self.configuration = configuration
    }

    var isStartButtonEnabled: Bool {
        runTask == nil && !status.isRunning
    }

    var isStopButtonEnabled: Bool {
        runTask != nil || status.isRunning
    }

    var canEditConfiguration: Bool {
        runTask == nil && !status.isRunning
    }

    func updateConfiguration(
        host: String,
        applicationName: String,
        streamName: String,
        publishUsername: String,
        publishPassword: String
    ) {
        guard canEditConfiguration else {
            return
        }

        var newConfiguration = configuration
        newConfiguration.host = host
        newConfiguration.applicationName = applicationName
        newConfiguration.streamName = streamName
        newConfiguration.publishUsername = publishUsername
        newConfiguration.publishPassword = publishPassword
        newConfiguration = newConfiguration.sanitized()
        newConfiguration.save()
        configuration = newConfiguration
    }

    func resetConfiguration() {
        guard canEditConfiguration else {
            return
        }

        let defaultConfiguration = StreamConfiguration.default
        defaultConfiguration.save()
        configuration = defaultConfiguration
    }

    func start() {
        guard runTask == nil else {
            return
        }
        lastErrorMessage = nil
        shouldReconnect = true
        isStopping = false
        shouldResumeAfterForeground = false
        setIdleTimerDisabled(true)
        runTask = Task { [weak self] in
            await self?.runPublishingLoop()
        }
    }

    func stop() {
        shouldReconnect = false
        shouldResumeAfterForeground = false
        isStopping = true
        runTask?.cancel()
        runTask = nil
        setIdleTimerDisabled(false)
        Task { [weak self] in
            await self?.stopCurrentSession(updateStatus: true)
        }
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .active:
            if shouldResumeAfterForeground {
                shouldResumeAfterForeground = false
                start()
            } else if status.isRunning {
                setIdleTimerDisabled(true)
            }
        case .background:
            pauseForBackground()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func runPublishingLoop() async {
        var attempt = 0
        var shouldMarkStoppedOnExit = true

        defer {
            runTask = nil
            isStopping = false
        }

        while shouldReconnect && !Task.isCancelled {
            do {
                if attempt == 0 {
                    status = .preparing
                } else {
                    status = .reconnecting(attempt: attempt)
                }

                try await prepareCaptureIfNeeded()
                try await startCurrentSession()
                status = .streaming
                attempt = 0

                await waitForDisconnect()
                if shouldReconnect && !Task.isCancelled && !isStopping {
                    attempt += 1
                    try await reconnectDelay(for: attempt)
                }
            } catch is CancellationError {
                break
            } catch {
                lastErrorMessage = error.localizedDescription

                if shouldReconnect && !Task.isCancelled && !isStopping {
                    attempt += 1
                    status = .reconnecting(attempt: attempt)
                    try? await stopCurrentSession(updateStatus: false)
                    try? await reconnectDelay(for: attempt)
                } else {
                    status = .failed(error.localizedDescription)
                    shouldMarkStoppedOnExit = false
                    break
                }
            }
        }

        await stopCurrentSession(updateStatus: shouldMarkStoppedOnExit && !Task.isCancelled)
    }

    private func prepareCaptureIfNeeded() async throws {
        guard !isCapturePrepared else {
            return
        }

        status = .requestingPermissions
        try await requestCapturePermissions()
        try configureAudioSession()

        status = .preparing
        if #available(tvOS 17.0, *) {
            await mixer.setSessionPreset(.hd1280x720)
        }
        await mixer.setVideoOrientation(.portrait)

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(for: .video) else {
            throw StreamManagerError.videoDeviceUnavailable
        }

        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw StreamManagerError.audioDeviceUnavailable
        }

        let frameRate = configuration.frameRate
        try await mixer.attachVideo(videoDevice, track: 0) { videoUnit in
            try videoUnit.setFrameRate(frameRate)
        }
        try await mixer.attachAudio(audioDevice, track: 0)
        try await mixer.setFrameRate(frameRate)
        await mixer.startRunning()

        isCapturePrepared = true
    }

    private func startCurrentSession() async throws {
        await stopCurrentSession(updateStatus: false)

        let connection = RTMPConnection()
        let stream = RTMPStream(connection: connection)

        try await configure(stream)
        await mixer.addOutput(stream)

        self.connection = connection
        self.stream = stream

        status = .connecting
        _ = try await connection.connect(configuration.rtmpConnectionURL)
        _ = try await stream.publish(configuration.rtmpPublishStreamName)
    }

    private func configure(_ stream: RTMPStream) async throws {
        var videoSettings = VideoCodecSettings(
            videoSize: configuration.videoSize,
            bitRate: configuration.videoBitRate,
            profileLevel: kVTProfileLevel_H264_Baseline_3_1 as String,
            maxKeyFrameIntervalDuration: configuration.keyFrameInterval,
            allowFrameReordering: false,
            isLowLatencyRateControlEnabled: true,
            expectedFrameRate: configuration.frameRate
        )
        videoSettings.frameInterval = (1 / configuration.frameRate) - 0.001

        let audioSettings = AudioCodecSettings(
            bitRate: configuration.audioBitRate,
            downmix: true,
            sampleRate: 0,
            format: .aac
        )

        try await stream.setVideoSettings(videoSettings)
        try await stream.setAudioSettings(audioSettings)
    }

    private func waitForDisconnect() async {
        guard let connection, let stream else {
            return
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                for await status in await connection.status {
                    await self?.handleRTMPStatus(code: status.code, level: status.level, description: status.description)
                    if status.level == "error" || status.code == RTMPConnection.Code.connectClosed.rawValue {
                        break
                    }
                }
            }

            group.addTask { [weak self] in
                for await status in await stream.status {
                    await self?.handleRTMPStatus(code: status.code, level: status.level, description: status.description)
                    if status.level == "error" ||
                        status.code == RTMPStream.Code.connectClosed.rawValue ||
                        status.code == RTMPStream.Code.unpublishSuccess.rawValue {
                        break
                    }
                }
            }

            await group.next()
            group.cancelAll()
        }
    }

    private func handleRTMPStatus(code: String, level: String, description: String) {
        if level == "error" {
            lastErrorMessage = "\(code): \(description)"
        }
    }

    private func stopCurrentSession(updateStatus: Bool) async {
        let stream = stream
        let connection = connection

        self.stream = nil
        self.connection = nil

        if let stream {
            await mixer.removeOutput(stream)
            try? await stream.close()
        }

        if let connection {
            try? await connection.close()
        }

        if updateStatus {
            status = .stopped
            setIdleTimerDisabled(false)
        }
    }

    private func pauseForBackground() {
        guard runTask != nil || status.isRunning else {
            setIdleTimerDisabled(false)
            return
        }

        shouldResumeAfterForeground = shouldReconnect
        shouldReconnect = false
        isStopping = true
        runTask?.cancel()
        runTask = nil
        setIdleTimerDisabled(false)

        Task { [weak self] in
            await self?.pauseCaptureForBackground()
        }
    }

    private func pauseCaptureForBackground() async {
        await stopCurrentSession(updateStatus: false)
        await mixer.stopRunning()
        isCapturePrepared = false
        status = .suspended("App 进入后台后 iOS 会暂停摄像头采集；回到前台将自动恢复推流。")
    }

    private func reconnectDelay(for attempt: Int) async throws {
        let seconds = min(Double(attempt * 2), 10)
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func requestCapturePermissions() async throws {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        let microphoneGranted = await AVCaptureDevice.requestAccess(for: .audio)

        guard cameraGranted else {
            status = .permissionDenied("相机权限未开启")
            throw StreamManagerError.cameraPermissionDenied
        }

        guard microphoneGranted else {
            status = .permissionDenied("麦克风权限未开启")
            throw StreamManagerError.microphonePermissionDenied
        }
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
    }

    private func setIdleTimerDisabled(_ isDisabled: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isDisabled
    }
}

extension StreamManager: MTHKViewRepresentable.PreviewSource {
    nonisolated func connect(to view: MTHKView) {
        Task {
            await mixer.addOutput(view)
        }
    }
}

private enum StreamManagerError: LocalizedError {
    case cameraPermissionDenied
    case microphonePermissionDenied
    case videoDeviceUnavailable
    case audioDeviceUnavailable

    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            "相机权限未开启，请在系统设置中允许 LatteCam 使用相机。"
        case .microphonePermissionDenied:
            "麦克风权限未开启，请在系统设置中允许 LatteCam 使用麦克风。"
        case .videoDeviceUnavailable:
            "未找到可用的后置摄像头。"
        case .audioDeviceUnavailable:
            "未找到可用的麦克风。"
        }
    }
}
