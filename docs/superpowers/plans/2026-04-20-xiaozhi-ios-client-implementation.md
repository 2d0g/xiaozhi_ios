# 小智 AI iOS 客户端实施计划 (2026-04-20)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个适配 iOS 17.6.1 的原生 AI 语音客户端，支持手动/后台唤醒、实时语音对话和 MQTT IoT 控制。

**Architecture:** 采用 SwiftUI + MVVM 架构，结合 Swift Actor 处理并发。音频引擎基于 `AVAudioEngine`，使用 `libopus` 进行实时 Raw Opus 编解码。

**Tech Stack:** Swift 6, SwiftUI, URLSessionWebSocketTask, libopus, CocoaMQTT, KeychainAccess.

---

### 第一阶段：项目初始化与安全身份 (Keychain, SN, HMAC)

**Files:**
- Create: `ios-client/XiaozhiAI/Services/Identity/DeviceFingerprint.swift`
- Create: `ios-client/XiaozhiAI/Utils/KeychainManager.swift`
- Create: `ios-client/XiaozhiAI/Utils/CryptoUtils.swift`
- Test: `ios-client/XiaozhiAITests/IdentityTests.swift`

- [ ] **步骤 1: 实现 KeychainManager 封装**
  
```swift
import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func fetch(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
```

- [ ] **步骤 2: 实现 HMAC-SHA256 工具**

```swift
import Foundation
import CommonCrypto

class CryptoUtils {
    static func hmacSha256(message: String, key: String) -> String {
        var context = CCHmacContext()
        let keyData = Data(key.utf8)
        let messageData = Data(message.utf8)
        
        CCHmacInit(&context, kCCHmacAlgSHA256, (keyData as NSData).bytes, keyData.count)
        CCHmacUpdate(&context, (messageData as NSData).bytes, messageData.count)
        
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmacFinal(&context, &hmac)
        
        return hmac.map { String(format: "%02x", $0) }.joined()
    }
}
```

- [ ] **步骤 3: 实现 DeviceFingerprint 身份生成逻辑**

```swift
import Foundation

class DeviceFingerprint {
    static let shared = DeviceFingerprint()
    
    func getOrGenerateSN() -> String {
        if let sn = KeychainManager.shared.fetch(for: "SERIAL_NUMBER") {
            return sn
        }
        let randomHex = (0..<12).map { _ in String(format: "%X", Int.random(in: 0...15)) }.joined()
        let newSN = "IOS" + randomHex
        KeychainManager.shared.save(newSN, for: "SERIAL_NUMBER")
        return newSN
    }
    
    func getOrGenerateHMACKey() -> String {
        if let key = KeychainManager.shared.fetch(for: "HMAC_KEY") {
            return key
        }
        let newKey = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        KeychainManager.shared.save(newKey, for: "HMAC_KEY")
        return newKey
    }
}
```

- [ ] **步骤 4: 编写单元测试验证身份持久化**
  
```swift
import XCTest
@testable import XiaozhiAI

class IdentityTests: XCTestCase {
    func testIdentityPersistence() {
        let sn1 = DeviceFingerprint.shared.getOrGenerateSN()
        let sn2 = DeviceFingerprint.shared.getOrGenerateSN()
        XCTAssertEqual(sn1, sn2)
        XCTAssertTrue(sn1.hasPrefix("IOS"))
    }
}
```

- [ ] **步骤 5: 运行测试并提交**
  
Run: `xcodebuild test -scheme XiaozhiAI -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'` (或使用 Xcode GUI)
Expected: PASS

---

### 第二阶段：激活服务与网络发现 (OTA, Polling)

**Files:**
- Create: `ios-client/XiaozhiAI/Services/Network/OTAService.swift`
- Create: `ios-client/XiaozhiAI/Services/Network/ActivationService.swift`

- [ ] **步骤 1: 实现 OTA 请求获取配置**

```swift
import Foundation

class OTAService {
    func fetchConfig() async throws -> [String: Any] {
        let url = URL(string: "https://api.xiaozhi.me/ota")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("ios", forHTTPHeaderField: "Device-Id")
        request.addValue("v2", forHTTPHeaderField: "Activation-Version")
        
        let payload: [String: Any] = [
            "application": ["version": "1.0.0"],
            "board": ["type": "ios"]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}
```

- [ ] **步骤 2: 实现激活状态轮询 (202 -> 200)**

```swift
import Foundation

class ActivationService {
    func pollActivation(challenge: String, hmacKey: String) async throws -> Bool {
        let signature = CryptoUtils.hmacSha256(message: challenge, key: hmacKey)
        let url = URL(string: "https://api.xiaozhi.me/activate")!
        
        while true {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            let payload = ["Payload": ["hmac": signature, "challenge": challenge]]
            request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 { return true }
                if httpResponse.statusCode == 202 {
                    try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                    continue
                }
            }
            throw NSError(domain: "ActivationError", code: -1)
        }
    }
}
```

---

### 第三阶段：音频引擎与编解码器 (AVAudioEngine, libopus)

**Files:**
- Create: `ios-client/XiaozhiAI/Services/Audio/AudioEngineManager.swift`
- Create: `ios-client/XiaozhiAI/Services/Audio/OpusCodec.swift`

- [ ] **步骤 1: 初始化 AVAudioEngine 并开启 AEC**

```swift
import AVFoundation

class AudioEngineManager {
    let engine = AVAudioEngine()
    
    func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
        
        // 开启回声消除
        engine.mainMixerNode
    }
    
    func startCapture(callback: @escaping (Data) -> Void) {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 960, format: format) { buffer, _ in
            // 处理 PCM 数据转 Opus...
        }
        try? engine.start()
    }
}
```

- [ ] **步骤 2: 集成 libopus 编解码 (C Bridge)**
*(注：此处仅展示接口逻辑，需在实施工序中引入 libopus 库)*

```swift
class OpusCodec {
    func encode(pcmData: Data) -> Data {
        // 调用 libopus C 函数进行 60ms 帧编码
        return pcmData // 占位
    }
    
    func decode(opusData: Data) -> Data {
        // 解码逻辑
        return opusData // 占位
    }
}
```

---

### 第四阶段：WebSocket 协议与长连接 (Ping/Pong, JSON)

**Files:**
- Create: `ios-client/XiaozhiAI/Services/Network/WebSocketManager.swift`

- [ ] **步骤 1: 实现全双工通信与 20秒 Ping**

```swift
import Foundation

actor WebSocketManager {
    private var webSocket: URLSessionWebSocketTask?
    private var pingTimer: Timer?

    func connect(url: URL, token: String) {
        let session = URLSession(configuration: .default)
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        startPingTimer()
    }

    private func startPingTimer() {
        // 每 20 秒发送一个原生 Ping
        Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            self.webSocket?.sendPing { error in
                if error != nil { self.reconnect() }
            }
        }
    }

    func sendAudio(data: Data) {
        webSocket?.send(.binary(data), completionHandler: { _ in })
    }
}
```

---

### 第五阶段：UI 实现与状态机集成 (SwiftUI)

**Files:**
- Create: `ios-client/XiaozhiAI/Views/MainView.swift`
- Create: `ios-client/XiaozhiAI/ViewModels/ChatViewModel.swift`

- [ ] **步骤 1: 实现核心状态机与能量视图更新**

```swift
import SwiftUI

@Observable
class ChatViewModel {
    var state: ConversationState = .idle
    var audioLevel: CGFloat = 0.0
    
    func startTalking() {
        state = .listening
        // 启动音频引擎与 WS 发流...
    }
}

struct MainView: View {
    @State var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            WaveformView(level: viewModel.audioLevel)
            Button("长按说话") { viewModel.startTalking() }
        }
    }
}
```

---

### 第六阶段：IoT 集成 (MQTT)

**Files:**
- Create: `ios-client/XiaozhiAI/Services/IoT/MQTTManager.swift`

- [ ] **步骤 1: 实现独立 MQTT 控制逻辑**

```swift
import CocoaMQTT

class MQTTManager {
    var mqtt: CocoaMQTT?
    
    func connect(config: MQTTConfig) {
        mqtt = CocoaMQTT(clientID: config.clientId, host: config.host, port: config.port)
        mqtt?.connect()
    }
    
    func publish(topic: String, message: String) {
        mqtt?.publish(topic, withString: message)
    }
}
```
