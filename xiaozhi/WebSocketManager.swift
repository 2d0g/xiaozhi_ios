import Foundation

class WebSocketManager: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = WebSocketManager()
    @Published var isConnected = false
    @Published var userText: String = ""
    @Published var aiText: String = ""
    private var sessionId: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }()
    
    func connect(url: String, token: String) {
        var cleanURL = url
        if cleanURL.hasSuffix("/") { cleanURL.removeLast() }
        guard let serverURL = URL(string: cleanURL) else { return }
        
        var request = URLRequest(url: serverURL)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("1", forHTTPHeaderField: "Protocol-Version")
        request.addValue(DeviceFingerprint.shared.getOrGenerateMAC(), forHTTPHeaderField: "Device-Id")
        request.addValue(DeviceFingerprint.shared.getOrGenerateClientID(), forHTTPHeaderField: "Client-Id")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        sendHello()
    }
    
    private func sendHello() {
        // 对标参考项目：16000Hz + 60ms 帧长
        let hello: [String: Any] = [
            "type": "hello", "version": 1, "transport": "websocket",
            "audio_params": ["format": "opus", "sample_rate": 16000, "channels": 1, "frame_duration": 60]
        ]
        sendJson(hello)
    }
    
    func sendListenStart() {
        var msg: [String: Any] = ["type": "listen", "state": "start", "mode": "auto"]
        if let sid = sessionId { msg["session_id"] = sid }
        sendJson(msg)
    }
    
    func sendListenStop() {
        var msg: [String: Any] = ["type": "listen", "state": "stop"]
        if let sid = sessionId { msg["session_id"] = sid }
        sendJson(msg)
    }
    
    func sendAudioData(_ data: Data) {
        webSocketTask?.send(.data(data)) { _ in }
    }
    
    private func sendJson(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let str = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(str)) { _ in }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            if case .success(let message) = result {
                switch message {
                case .string(let text): self.handleJson(text)
                case .data(let data): AudioEngineManager.shared.playAIResponse(data: data)
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
            if let sid = json["session_id"] as? String { self.sessionId = sid }
            if type == "hello" { self.isConnected = true }
            if type == "stt", let content = json["text"] as? String { self.userText = content }
            if type == "tts", let content = json["text"] as? String { self.aiText = content }
        }
    }
}
