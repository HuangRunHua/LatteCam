import SwiftUI

struct StreamConfigurationSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var host: String
    @State private var applicationName: String
    @State private var streamName: String
    @State private var publishUsername: String
    @State private var publishPassword: String

    let isEditingDisabled: Bool
    let onSave: (String, String, String, String, String) -> Void
    let onReset: () -> Void

    init(
        configuration: StreamConfiguration,
        isEditingDisabled: Bool,
        onSave: @escaping (String, String, String, String, String) -> Void,
        onReset: @escaping () -> Void
    ) {
        _host = State(initialValue: configuration.host)
        _applicationName = State(initialValue: configuration.applicationName)
        _streamName = State(initialValue: configuration.streamName)
        _publishUsername = State(initialValue: configuration.publishUsername)
        _publishPassword = State(initialValue: configuration.publishPassword)
        self.isEditingDisabled = isEditingDisabled
        self.onSave = onSave
        self.onReset = onReset
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Mac 主机名或 IP", text: $host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("RTMPS 应用名", text: $applicationName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("流名称", text: $streamName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("推流目标")
                } footer: {
                    Text("默认推流地址会生成 rtmps://host:1936/live/lattecam；Scrypted 应从 Mac 本机读取 rtsp://127.0.0.1:8554/live/lattecam。推流中不能修改配置。")
                }

                Section {
                    TextField("发布用户名", text: $publishUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("发布密码", text: $publishPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("MediaMTX 发布认证")
                } footer: {
                    Text("密码会保存到 iOS Keychain；推流时会通过 RTMPS 查询参数传给 MediaMTX。")
                }

                Section {
                    Button("恢复默认地址", role: .destructive) {
                        onReset()
                        dismiss()
                    }
                    .disabled(isEditingDisabled)
                }
            }
            .navigationTitle("地址配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(host, applicationName, streamName, publishUsername, publishPassword)
                        dismiss()
                    }
                    .disabled(isEditingDisabled || host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
