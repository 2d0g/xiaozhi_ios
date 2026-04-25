import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.xd0g.xiaozhi"
    
    // For testing in environments where Keychain is unavailable (like unsigned simulator tests)
    private var isMockEnabled: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    func save(_ value: String, for key: String) {
        if isMockEnabled {
            UserDefaults.standard.set(value, forKey: "mock_keychain_\(key)")
            return
        }
        
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain add error: \(status)")
        }
    }
    
    func fetch(for key: String) -> String? {
        if isMockEnabled {
            return UserDefaults.standard.string(forKey: "mock_keychain_\(key)")
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
}
