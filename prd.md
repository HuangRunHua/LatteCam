
# Project LatteCam (MVP 版本)

## 1. 项目概述

**1.1 目标**
开发一款基于 iOS 平台的极简工具类 App，将闲置的 iPhone 改造为局域网内的实时音视频采集与推流节点。App 负责采集摄像头与麦克风数据，并通过带认证的 RTMPS 推送到局域网内的 Mac 主机。Mac 主机负责将该流转换为仅本机可访问的 RTSP，并通过 Scrypted 桥接接入 Apple HomeKit 智能家居生态。

**1.2 核心场景**
旧 iPhone 将长期固定在室内某处（如猫抓板或食盆附近），接电并保持 App 前台运行。App 持续向局域网内的 Mac 主机推送低延迟 H.264/AAC 音视频流。用户最终通过家庭 App 查看拿铁的实时动态，录像与远程访问能力由 HomeKit / HKSV 处理。

**1.3 不做的事 (Out of Scope)**

* MVP 阶段不包含本地 AI 声音识别或图像检测。
* 不包含滤镜、美颜或多镜头切换。
* 不包含 App 内的录像保存功能（全权交由 HKSV 处理）。
* 不要求 iPhone 在锁屏或后台状态下继续摄像头采集；MVP 仅支持 App 前台常亮运行。

---

## 2. 系统架构描述

整个监控闭环采用四层架构，本 PRD 的主要开发范围仍然是**边缘采集层**。

1. **边缘采集层 (本项目开发范围)**：运行在旧 iPhone 上的 SwiftUI App。负责拉取摄像头与麦克风数据，使用 `HaishinKit.swift` 进行 H.264/AAC 编码，并作为 RTMPS 客户端主动推流到 Mac 主机。
2. **本地媒体中转层 (本地部署)**：当前阶段部署在 MacBook Pro 上，未来可迁移到 Mac mini。建议使用 `MediaMTX` 接收 iPhone 推来的 RTMPS 流，并只在 Mac 本机回环地址暴露标准 RTSP 地址。
3. **协议桥接层 (本地部署)**：运行在同一台 Mac 主机上的 Scrypted。它拉取 `MediaMTX` 暴露的 RTSP 流，并转换为 HomeKit 可识别的视频流。
4. **中枢与云端层 (Apple 托管)**：局域网内的 HomePod mini 作为 Home Hub 接管视频流，负责边缘加密和 HKSV 的 iCloud 录像上传。

推荐 MVP 链路：

`旧 iPhone App` -> `rtmps://YOUR_MAC_HOST.local:1936/live/lattecam` -> `MediaMTX` -> `rtsp://127.0.0.1:8554/live/lattecam` -> `Scrypted` -> `HomeKit / HKSV`

---

## 3. 功能需求矩阵 (MVP)

| 模块 | 功能项 | 优先级 | 详细说明与技术要求 |
| --- | --- | --- | --- |
| **基础采集** | 音视频权限请求 | P0 | 首次启动必须拦截并请求相机与麦克风的系统级权限。 |
| **基础采集** | 硬件调用 | P0 | 默认调用**后置广角摄像头**及机身麦克风，无需对焦功能。 |
| **流媒体核心** | 推流编码配置 | P0 | **视频**：使用 H.264 硬件编码。MVP 默认 720p / 30fps，关键帧间隔 (GOP) 设定为 1-2 秒以保证桥接秒开；1080p 作为后续可选配置。<br>

<br>**音频**：使用 AAC 编码，比特率 64kbps 或 128kbps。 |
| **流媒体核心** | RTMPS 推流客户端 | P0 | App 作为 RTMPS 客户端主动推流到 Mac 主机上的 `MediaMTX`，默认地址格式为 `rtmps://[Mac主机名或IP]:1936/live/lattecam`，发布用户名与密码由用户本机生成。 |
| **流媒体核心** | 自动重连 | P0 | 当 Mac 主机不可达、网络切换或推流连接断开时，App 自动重试连接，并在 UI 中展示连接中、推流中、重连中、失败等状态。 |
| **本地中转** | MediaMTX 服务 | P0 | 在 MacBook Pro 上运行 `MediaMTX`，接收 iPhone 的 RTMPS 流，并仅在 `127.0.0.1:8554` 输出标准 RTSP URL 给同机 Scrypted。 |
| **系统守护** | 屏幕常亮控制 | P0 | `UIApplication.shared.isIdleTimerDisabled = true`，禁止系统自动锁屏或息屏。 |
| **系统守护** | 极简节能模式 | P1 | 提供一个“黑屏伪装”功能，降低屏幕功耗以防止 OLED 烧屏和过热。该模式仍要求 App 保持前台运行，不承诺锁屏或后台推流。 |

---

## 4. 用户界面 (UI/UX) 规范

作为一款纯工具属性的软件，UI 采用 SwiftUI 原生组件，强调“状态可视”和“一键操作”。整体设计遵循“暗黑模式 (Dark Mode)”以降低屏幕发热。

### 4.1 核心 Dashboard 视图

整个 App 仅需一个主屏幕，包含以下元素：

* **背景层**：一个 `VideoPreviewLayer` 的 SwiftUI 封装，占据全屏，实时显示摄像头采集到的暗色调预览画面（用于确认镜头没被遮挡）。
* **状态卡片 (半透明悬浮)**：
* **推流状态**：醒目的红/绿圆点指示灯（🔴 推流停止 / 🟢 推流中），并区分连接中、重连中、失败等状态文案。
* **推流目标地址**：使用大字号、等宽字体展示当前 RTMPS 推流目标（例如 `rtmps://YOUR_MAC_HOST.local:1936/live/lattecam`），支持长按复制。
* **桥接 RTSP 地址**：展示由 Mac 主机暴露给同机 Scrypted 的 RTSP 地址（`rtsp://127.0.0.1:8554/live/lattecam`），便于验收测试。


* **交互按钮区 (底部)**：
* **主控开关**：巨大的 `Toggle` 或 `Button`，控制 RTMPS 推流的启动与停止。
* **节能模式按钮**：点击后触发 4.2 描述的视图。



### 4.2 节能黑屏视图

* 点击“节能模式”后，整体视图被一个纯黑色的 `Color.black` 全屏覆盖，屏幕亮度强制通过 `UIScreen.main.brightness` 降至最低值。
* 屏幕上仅保留一个极暗灰色的“双击退出节能模式”提示文本，防止误触。
* 节能模式仅改变前台 UI 与屏幕亮度，不会让 App 进入后台或锁屏状态。

---

## 5. 技术选型建议

* **界面框架**：`SwiftUI`。
* **语言**：`Swift 5.x` 以上。
* **iOS 推流库**：强烈建议使用 **`HaishinKit.swift`**。这是一个成熟的 iOS 相机流媒体库，适合处理 `AVFoundation` 采集、硬件编码以及 RTMP/RTMPS 推流。MVP 阶段默认使用 RTMPS。
* **Mac 本地媒体服务**：建议使用 **`MediaMTX`**。它负责接收 iPhone 推来的 RTMPS 流，并向同机 Scrypted 输出 localhost RTSP。
* **HomeKit 桥接服务**：使用 **`Scrypted`**。当前阶段运行在 MacBook Pro 上，未来可迁移到 Mac mini 长期托管。
* **当前测试主机**：MacBook Pro。需要保持接电、避免睡眠，并确保防火墙允许 RTMPS 与 Scrypted/HomeKit 必要端口通信。不要把 MediaMTX 或 Scrypted 端口映射到公网。

---

## 6. 开发与验收工作流

1. **MacBook Pro 本地服务准备**：在 MacBook Pro 上运行 `MediaMTX`，确认其可接收 RTMPS 并向同机输出 RTSP。随后运行 Scrypted，准备用于接入 RTSP 摄像头。
2. **AI 辅助生成 iOS App**：在 Cursor IDE 中创建 SwiftUI 新项目，将本 PRD 的核心诉求（特别是依赖 HaishinKit 进行 RTMPS 推流的部分）作为 Master Prompt，生成核心推流单例 (`StreamManager`) 和主视图 (`ContentView`)。
3. **真机部署**：通过 Xcode 编包，直接灌入旧 iPhone 进行真机调试（由于涉及相机与麦克风，模拟器无法完成此阶段测试）。
4. **RTMPS 推流验证**：在 iPhone App 中配置推流目标，例如 `rtmps://YOUR_MAC_HOST.local:1936/live/lattecam`，启动推流后确认 `MediaMTX` 收到流。
* **验收标准 1**：MacBook Pro 上的 `MediaMTX` 能稳定接收到 iPhone 推来的音视频流，App 断线后能自动重连。

5. **本机 RTSP 验流**：在运行 MediaMTX 的 Mac 本机上，用 VLC、ffprobe 或 Scrypted 读取 `rtsp://127.0.0.1:8554/live/lattecam`。
* **验收标准 2**：Scrypted 能成功读取画面和声音，延迟在可接受范围内，且 iPhone 发热量不至于导致系统降频。

6. **接入生态**：确认 VLC 拉流无误后，登录 MacBook Pro 上的 Scrypted 后台，将该 RTSP 地址填入摄像头插件。最后用主用手机的家庭 App 完成接入。
* **验收标准 3**：能在家庭 App 中看到实时监控；断开局域网 Wi-Fi 使用蜂窝网络时，依然能通过 HomeKit 拉取画面。

7. **未来迁移**：当 Mac mini 可用后，将 `MediaMTX` 与 Scrypted 从 MacBook Pro 迁移到 Mac mini。iPhone App 仅需修改推流目标地址，无需改变核心采集与推流逻辑。