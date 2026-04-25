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
