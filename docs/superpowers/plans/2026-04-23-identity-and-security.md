# 小智 AI iOS 身份与安全实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 iOS 客户端的唯一身份标识 (SN) 生成、基于 Keychain 的安全存储以及用于激活校验的 HMAC-SHA256 加密工具。

**Architecture:** 
- `KeychainManager`: 封装 `Security.framework` 提供简单的字符串读写接口。
- `CryptoUtils`: 使用 `CommonCrypto` 实现 HMAC-SHA256。
- `DeviceFingerprint`: 协调器，负责首次启动时生成 SN (IOS + 12位十六进制) 和 32位 HMAC Key，并确保其持久化。

**Tech Stack:** Swift 6, Security Framework, CommonCrypto.

---

### Task 1: 实现 KeychainManager 封装

**Files:**
- Create: `xiaozhi/Utils/KeychainManager.swift`
- Test: `xiaozhiTests/KeychainManagerTests.swift`

- [ ] **Step 1: 编写测试验证 Keychain 读写**

```swift
import XCTest
@testable import xiaozhi

class KeychainManagerTests: XCTestCase {
    func testSaveAndFetch() {
        let key = "test_key_\(UUID().uuidString)"
        let value = "test_value"
        KeychainManager.shared.save(value, for: key)
        let fetchedValue = KeychainManager.shared.fetch(for: key)
        XCTAssertEqual(value, fetchedValue)
    }
}
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `xcodebuild test -scheme xiaozhi -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:xiaozhiTests/KeychainManagerTests`
Expected: FAIL (Compilation error: KeychainManager not found)

- [ ] **Step 3: 实现 KeychainManager**

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

- [ ] **Step 4: 运行测试并确认通过**

Expected: PASS

- [ ] **Step 5: 提交代码**

```bash
git add xiaozhi/Utils/KeychainManager.swift xiaozhiTests/KeychainManagerTests.swift
git commit -m "feat: add KeychainManager for secure storage"
```

---

### Task 2: 实现 HMAC-SHA256 工具

**Files:**
- Create: `xiaozhi/Utils/CryptoUtils.swift`
- Test: `xiaozhiTests/CryptoUtilsTests.swift`

- [ ] **Step 1: 编写测试验证 HMAC 签名结果**

```swift
import XCTest
@testable import xiaozhi

class CryptoUtilsTests: XCTestCase {
    func testHmacSha256() {
        let message = "hello"
        let key = "secret"
        // Expected HMAC for "hello" with key "secret"
        let expected = "88a52fcca9302e30dd34a98c764abc39cd452d733055460595808bcd31229792"
        let result = CryptoUtils.hmacSha256(message: message, key: key)
        XCTAssertEqual(result, expected)
    }
}
```

- [ ] **Step 2: 运行测试并确认失败**

Expected: FAIL

- [ ] **Step 3: 实现 CryptoUtils**

```swift
import Foundation
import CommonCrypto

class CryptoUtils {
    static func hmacSha256(message: String, key: String) -> String {
        let keyData = Data(key.utf8)
        let messageData = Data(message.utf8)
        
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        keyData.withUnsafeBytes { keyBytes in
            messageData.withUnsafeBytes { messageBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256),
                       keyBytes.baseAddress, keyData.count,
                       messageBytes.baseAddress, messageData.count,
                       &hmac)
            }
        }
        
        return hmac.map { String(format: "%02x", $0) }.joined()
    }
}
```

- [ ] **Step 4: 运行测试并确认通过**

Expected: PASS

- [ ] **Step 5: 提交代码**

```bash
git add xiaozhi/Utils/CryptoUtils.swift xiaozhiTests/CryptoUtilsTests.swift
git commit -m "feat: add CryptoUtils for HMAC-SHA256 signatures"
```

---

### Task 3: 实现 DeviceFingerprint 身份生成逻辑

**Files:**
- Create: `xiaozhi/Services/Identity/DeviceFingerprint.swift`
- Test: `xiaozhiTests/IdentityTests.swift`

- [ ] **Step 1: 编写测试验证身份持久化**

```swift
import XCTest
@testable import xiaozhi

class IdentityTests: XCTestCase {
    func testIdentityPersistence() {
        let sn1 = DeviceFingerprint.shared.getOrGenerateSN()
        let sn2 = DeviceFingerprint.shared.getOrGenerateSN()
        XCTAssertEqual(sn1, sn2)
        XCTAssertTrue(sn1.hasPrefix("IOS"))
        XCTAssertEqual(sn1.count, 15) // "IOS" + 12 chars
        
        let key1 = DeviceFingerprint.shared.getOrGenerateHMACKey()
        let key2 = DeviceFingerprint.shared.getOrGenerateHMACKey()
        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1.count, 32)
    }
}
```

- [ ] **Step 2: 运行测试并确认失败**

Expected: FAIL

- [ ] **Step 3: 实现 DeviceFingerprint**

```swift
import Foundation

class DeviceFingerprint {
    static let shared = DeviceFingerprint()
    
    func getOrGenerateSN() -> String {
        if let sn = KeychainManager.shared.fetch(for: "SERIAL_NUMBER") {
            return sn
        }
        let alphabet = "0123456789ABCDEF"
        let randomHex = (0..<12).map { _ in String(alphabet.randomElement()!) }.joined()
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

- [ ] **Step 4: 运行测试并确认通过**

Expected: PASS

- [ ] **Step 5: 提交代码**

```bash
git add xiaozhi/Services/Identity/DeviceFingerprint.swift xiaozhiTests/IdentityTests.swift
git commit -m "feat: add DeviceFingerprint for SN and HMAC key generation"
```
