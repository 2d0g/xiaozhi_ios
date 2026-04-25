import Foundation

class OTAService {
    static let shared = OTAService()
    
    func handshake() async throws -> OTAResponse {
        let mac = DeviceFingerprint.shared.getOrGenerateMAC()
        let payload = OTAPayload(
            application: .init(version: "2.0.0", elf_sha256: ""),
            board: .init(type: "bread-compact-wifi", name: "ios-client", ip: "127.0.0.1", mac: mac)
        )
        
        guard let url = URL(string: "https://api.tenclass.net/xiaozhi/ota/") else {
            throw NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(mac, forHTTPHeaderField: "Device-Id")
        request.addValue(DeviceFingerprint.shared.getOrGenerateClientID(), forHTTPHeaderField: "Client-Id")
        request.addValue("bread-compact-wifi/py-xiaozhi-2.0.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // 增加打印，方便在 Xcode 控制台直接看原始回包
        if let jsonStr = String(data: data, encoding: .utf8) {
            print("OTA 原始回包: \(jsonStr)")
        }
        
        return try JSONDecoder().decode(OTAResponse.self, from: data)
    }
}
