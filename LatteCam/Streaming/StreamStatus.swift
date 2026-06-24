import Foundation

enum StreamStatus: Equatable {
    case stopped
    case requestingPermissions
    case permissionDenied(String)
    case preparing
    case connecting
    case streaming
    case reconnecting(attempt: Int)
    case suspended(String)
    case failed(String)

    var title: String {
        switch self {
        case .stopped:
            "推流停止"
        case .requestingPermissions:
            "请求权限中"
        case .permissionDenied:
            "权限缺失"
        case .preparing:
            "准备采集中"
        case .connecting:
            "连接中"
        case .streaming:
            "推流中"
        case .reconnecting(let attempt):
            "重连中 \(attempt)"
        case .suspended:
            "已暂停"
        case .failed:
            "推流失败"
        }
    }

    var isRunning: Bool {
        switch self {
        case .requestingPermissions, .preparing, .connecting, .streaming, .reconnecting:
            true
        case .stopped, .permissionDenied, .suspended, .failed:
            false
        }
    }

    var message: String? {
        switch self {
        case .permissionDenied(let message), .suspended(let message), .failed(let message):
            message
        case .stopped, .requestingPermissions, .preparing, .connecting, .streaming, .reconnecting:
            nil
        }
    }
}
