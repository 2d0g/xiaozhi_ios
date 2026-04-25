# 小智 AI iOS 实时语音对讲实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现与 WebSocket 服务器的实时语音数据传输，包括 Opus 压缩上传和服务器回复的解码播放。

**Architecture:** 
- `AudioStreamer`: 处理 PCM 数据的分片（每 20ms 一帧），并调用 Opus 编码。
- `WebSocketManager (Enhanced)`: 支持二进制数据发送，并能区分 JSON 指令和音频流。
- `OpusCodec`: C 库桥接，实现 16k 采样率的单声道压缩/解压。

**Tech Stack:** Swift 6 (Concurrency), AVAudioEngine, libopus (via SPM), URLSessionWebSocketTask.

---

### Task 9: 集成 Opus 编解码库 (Dependency Integration)

**目标**: 在项目中引入 Opus 编解码支持，这是语音对讲的物理基础。

- [ ] **Step 1: 添加 SwiftOpus 依赖**
  - 操作建议：在 Xcode 项目设置中添加 Swift Package: `https://github.com/n-p-m/SwiftOpus.git`。
- [ ] **Step 2: 验证编解码通路**
  - 在 `IdentityTests.swift` 中增加测试用例，尝试对一小段随机 PCM 数据进行 Encode 再 Decode，验证数据完整性。

---

### Task 10: 实时音频分片与 WebSocket 上传

**目标**: 将麦克风捕获的 16k PCM 实时切片并发送给云端。

- [ ] **Step 1: 更新 WebSocketManager**
  - 增加 `sendAudio(_ data: Data)` 方法。
  - 实现状态切换逻辑：发送 `type: listen`, `state: start`。
- [ ] **Step 2: 连接 AudioEngine 与 WebSocket**
  - 在 `AudioEngineManager` 的 `installTap` 回调中，将 PCM 数据送入 `OpusEncoder`。
  - 每收集满 320 个采样点（20ms @ 16k）发送一次二进制包。

---

### Task 11: 接收 AI 语音并解码播放

**目标**: 处理服务器下发的音频数据流并利用 `AVAudioEngine` 播放。

- [ ] **Step 1: 建立播放队列**
  - 实现 `AVAudioSourceNode` 或使用 `AVAudioPlayerNode` 配合缓冲区。
- [ ] **Step 2: 实现实时解码**
  - 在 WebSocket 的 `receive` 闭包中，将收到的 Data 送入 `OpusDecoder`。
  - 将解码后的 PCM 压入播放队列。
- [ ] **Step 3: UI 状态反馈**
  - 根据服务器下发的 `type: tts, state: start/stop` 消息，在 UI 上显示“小智正在说话”。
