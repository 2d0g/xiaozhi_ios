import Foundation

class DeviceFingerprint {
    static let shared = DeviceFingerprint()
    
    func getOrGenerateMAC() -> String {
        if let mac = KeychainManager.shared.fetch(for: "MAC_ADDRESS") { return mac }
        let hex = "0123456789abcdef"
        let clean = (0..<12).map { _ in String(hex.randomElement()!) }.joined()
        let formatted = stride(from: 0, to: 12, by: 2).map { 
            String(clean[clean.index(clean.startIndex, offsetBy: $0)..<clean.index(clean.startIndex, offsetBy: $0+2)]) 
        }.joined(separator: ":")
        KeychainManager.shared.save(formatted, for: "MAC_ADDRESS")
        return formatted
    }
    
    func getOrGenerateSN() -> String {
        if let sn = KeychainManager.shared.fetch(for: "SERIAL_NUMBER") { return sn }
        let mac = getOrGenerateMAC().replacingOccurrences(of: ":", with: "").lowercased()
        let sn = "SN-\(String(UUID().uuidString.prefix(8)).lowercased())-\(mac)"
        KeychainManager.shared.save(sn, for: "SERIAL_NUMBER")
        return sn
    }
    
    func getOrGenerateClientID() -> String {
        if let id = KeychainManager.shared.fetch(for: "CLIENT_ID") { return id }
        let newID = UUID().uuidString.lowercased()
        KeychainManager.shared.save(newID, for: "CLIENT_ID")
        return newID
    }
}
