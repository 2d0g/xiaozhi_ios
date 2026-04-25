# 小智 AI (iOS) 客户端设计规格说明书 (2026-04-20)

## 1. 项目背景
将原 Python 版“小智 AI”核心能力迁移至 iOS 平台，实现一个适配 iOS 17.6.1 的原生客户端。应用通过 WebSocket 与服务器建立全双工实时语音长连接，支持手动唤醒及后台语音唤醒，并独立控制 MQTT 智能家居设备。

---

## 2. 核心架构 (MVVM + Actor)

### 2.1 UI 与 视图模型 (SwiftUI)
- **SwiftUI 驱动**：使用 `@Observable` 模式驱动视图更新，确保在 iOS 17+ 上的流畅性能。
- **主视图 (MainView)**：
  - **动态波形 (Waveform Canvas)**：反映实时采集和播放的音量能量。
  - **表情包图层 (Emotion Layer)**：在波形中心叠加动态 GIF 或图片序列，对应 AI 的 `happy`, `thinking`, `speaking` 情绪。
  - **控制栏 (Control Bar)**：包含录音按钮（支持长按与点击切换）和设置入口。
- **ViewModel (ChatViewModel)**：
  - 管理对话生命周期状态机：`IDLE` -> `LISTENING` -> `THINKING` -> `SPEAKING`。
  - 监听 `AudioService` 的能量波动，实时更新 UI。

### 2.2 线程安全与并发 (Swift Concurrency)
- **WebSocketActor**：使用 Swift `actor` 封装长连接逻辑，防止网络消息与音频流并发处理时的竞争。
- **Async/Await**：所有 HTTP 请求（OTA、激活）和异步信令处理均使用现代并发语法。

---

## 3. 音频处理逻辑 (AVAudioEngine)

### 3.1 采集链路 (Input)
- **配置**：`AVAudioSession` 类别设为 `.playAndRecord`，开启 `.defaultToSpeaker`。
- **回声消除 (AEC)**：通过 `AVAudioUnit` 的 `VoiceProcessingIO` 开启硬件级回声消除，防止播放的 AI 语音再次被麦克风录入。
- **采样参数**：统一 16,000 Hz, 单声道, 16-bit PCM。
- **编码**：累积 60ms (960 采样点) 的 PCM 数据后，通过 `libopus` 编码为 **Raw Opus** 帧。

### 3.2 播放链路 (Output)
- **解码**：收到服务器返回的二进制帧后，解码回 PCM。
- **抖动缓冲 (Jitter Buffer)**：实现 **120ms - 180ms 的播放队列缓冲**，抵消不稳定的网络到达间隔，确保语音连续。
- **打断处理**：监听 `AVAudioSession.interruptionNotification`。当收到来电或闹钟（`.began`）时，立即发送 `abort` 指令并停止音频引擎。

---

## 4. 通信协议 (WebSocket & HTTP)

### 4.1 握手与保活 (WebSocket)
- **握手信令**：连接成功后立即发送 `hello` 包，声明音频参数（Opus, 16k, 60ms）。
- **心跳保活**：每 **20 秒**由客户端主动发起 **Native WS Ping Frame**，并在 20 秒内等待 Pong 响应。
- **信令路由**：解析 JSON（`stt`, `text`, `tts:start/stop`）分发至 `ChatViewModel`。

### 4.2 设备激活流程 (HTTP)
- **身份生成**：首次启动生成 12 位 SN (前缀 `IOS`) 和 32 字节 `hmac_key`，存入 **Keychain**。
- **轮询策略**：POST 请求 `/activate`。收到 **202** 状态码时，以 5 秒/次的频率轮询；收到 **200** 状态码时，本地激活状态置为 True。
- **HMAC 签名**：使用 `CommonCrypto` 实现 HMAC-SHA256，对服务器的 `challenge` 签名。

---

## 5. IoT 控制 (MQTT)
- **独立管理**：集成 `CocoaMQTT` 库，作为独立的控制终端。
- **交互逻辑**：当 AI 响应中包含设备控制意图时，由 `MQTTService` 直接向 Broker 发送 Topic 和 Payload，保持与原 Python 系统逻辑一致，不经过 HomeKit。

---

## 6. 隐私与存储 (Persistence)

### 6.1 权限与后台
- **隐私申请**：在 `Info.plist` 中明确 `NSMicrophoneUsageDescription`。
- **后台模式**：开启 `Audio` 后台运行权限。
- **唤醒词设置**：在 App 设置中提供 Toggle，由用户决定是否在后台维持音频监听。

### 6.2 极简存储
- **UserDefaults**：存储唤醒词开关、UI 主题等轻量偏好。
- **Keychain**：安全存储 **AccessToken**, **SN**, **HMAC Key**, **DeviceID** 及 **MQTT 凭据**。

---

## 7. 验收标准
- [ ] 1. 成功向 `xiaozhi.me` 获取 OTA 并展示激活码。
- [ ] 2. 在网站输入激活码后，App 自动检测并进入主界面。
- [ ] 3. 按下录音后，实时看到波形跳动且服务器返回文字内容。
- [ ] 4. AI 回复语音时，波形展示且声音连贯（无抖动）。
- [ ] 5. 支持喊出“唤醒词”即刻开始对话。
- [ ] 6. 收到来电时，App 自动停止录音并断开连接。
