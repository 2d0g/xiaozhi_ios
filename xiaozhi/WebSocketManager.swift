import Foundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: String // "user" or "ai"
    var text: String
}

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()
    @Published var isConnected = false
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    @Published var messages: [ChatMessage] = []
    private var sessionId: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    
    func connect(url: String, token: String) {
        var cleanURL = url
        if cleanURL.hasSuffix("/") { cleanURL.removeLast() }
        
        guard let serverURL = URL(string: cleanURL) else { return }
        if isConnected || isConnecting { return }
        
        isConnecting = true
        errorMessage = nil
        print(">>> 正在建立 WebSocket 连接: \(cleanURL)")
        
        var request = URLRequest(url: serverURL)
        request.timeoutInterval = 10
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("1", forHTTPHeaderField: "Protocol-Version")
        request.addValue(DeviceFingerprint.shared.getOrGenerateMAC(), forHTTPHeaderField: "Device-Id")
        request.addValue(DeviceFingerprint.shared.getOrGenerateClientID(), forHTTPHeaderField: "Client-Id")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
        setupPing()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("✅ WebSocket 链路已成功升级 (HTTP 101)")
        self.sendHello()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
            
            print("!!! WebSocket 链路异常 [Code \(nsError.code)]: \(nsError.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isConnected = false
                self.isConnecting = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func setupPing() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.webSocketTask?.sendPing { error in
                if let _ = error { print("!!! Ping 失败，链路可能已断开") }
            }
        }
    }

    private func sendHello() {
        print(">>> 发送业务 hello 报文...")
        let hello: [String: Any] = [
            "type": "hello",
            "version": 1,
            "transport": "websocket",
            "audio_params": ["format": "opus", "sample_rate": 24000, "channels": 1, "frame_duration": 20]
        ]
        sendJson(hello)
    }
    
    func sendListenStart() {
        guard isConnected else { print("!!! 警告：尚未握手成功，拒绝发送 listen.start"); return }
        sendJson(["type": "listen", "state": "start", "mode": "auto"])
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(role: "user", text: "..."))
        }
    }
    
    func sendText(_ text: String) {
        guard isConnected else { return }
        let msg: [String: Any] = [
            "type": "listen",
            "state": "detect",
            "text": text,
            "source": "text"
        ]
        sendJson(msg)
        DispatchQueue.main.async {
            self.messages.append(ChatMessage(role: "user", text: text))
        }
    }
    
    func sendListenStop() {
        guard isConnected else { return }
        sendJson(["type": "listen", "state": "stop"])
    }
    
    func sendAudioData(_ data: Data) {
        guard isConnected else { return }
        webSocketTask?.send(.data(data)) { error in
            if let error = error { print("!!! 音频发送失败: \(error.localizedDescription)") }
        }
    }
    
    private func sendJson(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let str = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(str)) { error in
                if let error = error { print("!!! JSON 发送失败: \(error)") }
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            if case .success(let message) = result {
                switch message {
                case .string(let text): self.handleJson(text)
                case .data(let data): self.handleAudio(data)
                @unknown default: break
                }
                self.receiveMessage()
            }
        }
    }
    
    private func handleJson(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
              
        DispatchQueue.main.async {
            if let sid = json["session_id"] as? String {
                self.sessionId = sid
            }
            
            if type == "hello" {
                print("🎉 小智业务握手成功，现在可以开始对话了！")
                self.isConnected = true
                self.isConnecting = false
            } else if type == "stt" {
                if let content = json["text"] as? String {
                    if let lastIndex = self.messages.lastIndex(where: { $0.role == "user" }) {
                        self.messages[lastIndex].text = content
                    } else {
                        self.messages.append(ChatMessage(role: "user", text: content))
                    }
                }
            } else if type == "tts" {
                let state = json["state"] as? String
                if state == "start" || state == "sentence_start" {
                    AudioEngineManager.shared.resetPlayback()
                }
                
                if (state == "sentence_start" || state == "sentence_end"), let content = json["text"] as? String, !content.isEmpty {
                    if let last = self.messages.last, last.role == "ai", last.text == content {
                        // ignore duplicate
                    } else if let last = self.messages.last, last.role == "ai", state == "sentence_end" {
                        self.messages[self.messages.count - 1].text = content
                    } else {
                        self.messages.append(ChatMessage(role: "ai", text: content))
                    }
                }
                
                if state == "stop" || state == "sentence_end" {
                    AudioEngineManager.shared.flushPlayback()
                }
            }
        }
    }
    
    private func handleAudio(_ data: Data) {
        AudioEngineManager.shared.playAIResponse(data: data)
    }
}
