import CoreGraphics
import Foundation

struct StreamConfiguration: Equatable {
    var host: String
    var applicationName: String
    var streamName: String
    var publishUsername: String
    var publishPassword: String
    var videoSize: CGSize
    var videoBitRate: Int
    var audioBitRate: Int
    var frameRate: Double
    var keyFrameInterval: Int32

    static let `default` = StreamConfiguration(
        host: "YOUR_MAC_HOST.local",
        applicationName: "live",
        streamName: "lattecam",
        publishUsername: "lattecam_publish",
        publishPassword: "",
        videoSize: CGSize(width: 1280, height: 720),
        videoBitRate: 2_000_000,
        audioBitRate: 64_000,
        frameRate: 30,
        keyFrameInterval: 2
    )

    static func load(from defaults: UserDefaults = .standard) -> StreamConfiguration {
        var configuration = StreamConfiguration.default
        configuration.host = defaults.string(forKey: StorageKey.host) ?? configuration.host
        configuration.applicationName = defaults.string(forKey: StorageKey.applicationName) ?? configuration.applicationName
        configuration.streamName = defaults.string(forKey: StorageKey.streamName) ?? configuration.streamName
        configuration.publishUsername = defaults.string(forKey: StorageKey.publishUsername) ?? configuration.publishUsername
        configuration.publishPassword = SecureCredentialStore.password(for: configuration.publishUsername)
        return configuration.sanitized()
    }

    func save(to defaults: UserDefaults = .standard) {
        let configuration = sanitized()
        defaults.set(configuration.host, forKey: StorageKey.host)
        defaults.set(configuration.applicationName, forKey: StorageKey.applicationName)
        defaults.set(configuration.streamName, forKey: StorageKey.streamName)
        defaults.set(configuration.publishUsername, forKey: StorageKey.publishUsername)
        SecureCredentialStore.savePassword(configuration.publishPassword, for: configuration.publishUsername)
    }

    func sanitized() -> StreamConfiguration {
        var configuration = self
        configuration.host = Self.sanitizedHost(host)
        configuration.applicationName = Self.sanitizedPathSegment(applicationName, fallback: StreamConfiguration.default.applicationName)
        configuration.streamName = Self.sanitizedPathSegment(streamName, fallback: StreamConfiguration.default.streamName)
        configuration.publishUsername = publishUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        configuration.publishPassword = publishPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return configuration
    }

    var rtmpConnectionURL: String {
        "rtmps://\(host):1936/\(applicationName)"
    }

    var rtmpPublishURL: String {
        let baseURL = "rtmps://\(host):1936/\(applicationName)/\(streamName)"
        guard hasPublishCredentials else {
            return baseURL
        }
        return "\(baseURL)?user=\(Self.percentEncoded(publishUsername))&pass=••••••••"
    }

    var rtmpPublishStreamName: String {
        guard hasPublishCredentials else {
            return streamName
        }
        return "\(streamName)?user=\(Self.percentEncoded(publishUsername))&pass=\(Self.percentEncoded(publishPassword))"
    }

    var rtspPlaybackURL: String {
        "rtsp://127.0.0.1:8554/\(applicationName)/\(streamName)"
    }

    var hasPublishCredentials: Bool {
        !publishUsername.isEmpty && !publishPassword.isEmpty
    }

    private static func sanitizedHost(_ value: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "rtmps://", with: "")
            .replacingOccurrences(of: "rtmp://", with: "")
            .replacingOccurrences(of: "rtsp://", with: "")

        let host = trimmed
            .split(separator: "/")
            .first
            .map(String.init) ?? ""

        return host.isEmpty ? StreamConfiguration.default.host : host
    }

    private static func sanitizedPathSegment(_ value: String, fallback: String) -> String {
        let segment = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        return segment.isEmpty ? fallback : segment
    }

    private static func percentEncoded(_ value: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? value
    }
}

private enum StorageKey {
    static let host = "stream.configuration.host"
    static let applicationName = "stream.configuration.applicationName"
    static let streamName = "stream.configuration.streamName"
    static let publishUsername = "stream.configuration.publishUsername"
}
