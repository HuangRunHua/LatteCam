import HaishinKit
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var streamManager = StreamManager()
    @State private var isShowingConfiguration = false
    @State private var isEnergySaverPresented = false
    @State private var copiedMessage: String?

    var body: some View {
        ZStack {
            MTHKViewRepresentable(previewSource: streamManager, videoGravity: .resizeAspectFill)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35).ignoresSafeArea())

            VStack {
                statusCard

                Spacer()

                controlPanel
            }
            .padding()

            if isEnergySaverPresented {
                EnergySaverOverlay(isPresented: $isEnergySaverPresented)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { newPhase in
            streamManager.handleScenePhase(newPhase)
        }
        .sheet(isPresented: $isShowingConfiguration) {
            StreamConfigurationSheet(
                configuration: streamManager.configuration,
                isEditingDisabled: !streamManager.canEditConfiguration,
                onSave: { host, applicationName, streamName, publishUsername, publishPassword in
                    streamManager.updateConfiguration(
                        host: host,
                        applicationName: applicationName,
                        streamName: streamName,
                        publishUsername: publishUsername,
                        publishPassword: publishPassword
                    )
                },
                onReset: {
                    streamManager.resetConfiguration()
                }
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isEnergySaverPresented)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                Text(streamManager.status.title)
                    .font(.headline)

                Spacer()

                Button {
                    isShowingConfiguration = true
                } label: {
                    Image(systemName: "gearshape")
                        .imageScale(.medium)
                }
                .buttonStyle(.bordered)
                .disabled(!streamManager.canEditConfiguration)
            }

            addressRow(title: "RTMPS 推流", value: streamManager.configuration.rtmpPublishURL)
            addressRow(title: "RTSP 拉流", value: streamManager.configuration.rtspPlaybackURL)

            if let statusMessage = streamManager.status.message {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.yellow)
                    .lineLimit(3)
            }

            if let lastErrorMessage = streamManager.lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .lineLimit(3)
            }

            if let copiedMessage {
                Text(copiedMessage)
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var controlPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    streamManager.start()
                } label: {
                    Label("开始推流", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!streamManager.isStartButtonEnabled)

                Button(role: .destructive) {
                    streamManager.stop()
                } label: {
                    Label("停止", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!streamManager.isStopButtonEnabled)
            }

            Button {
                isEnergySaverPresented = true
            } label: {
                Label("节能黑屏模式", systemImage: "moon.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
        .foregroundStyle(.white)
    }

    private func addressRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                copy(value, label: title)
            } label: {
                Image(systemName: "doc.on.doc")
                    .imageScale(.small)
            }
            .buttonStyle(.borderless)
        }
    }

    private func copy(_ value: String, label: String) {
        UIPasteboard.general.string = value
        copiedMessage = "已复制 \(label)"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if copiedMessage == "已复制 \(label)" {
                copiedMessage = nil
            }
        }
    }

    private var statusColor: Color {
        switch streamManager.status {
        case .streaming:
            .green
        case .connecting, .preparing, .requestingPermissions, .reconnecting:
            .yellow
        case .failed, .permissionDenied:
            .red
        case .suspended:
            .orange
        case .stopped:
            .gray
        }
    }
}

#Preview {
    ContentView()
}
