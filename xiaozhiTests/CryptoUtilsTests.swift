import XCTest
@testable import xiaozhi

class CryptoUtilsTests: XCTestCase {
    func testHmacSha256() {
        let message = "hello"
        let key = "secret"
        let expected = "88aab3ede8d3adf94d26ab90d3bafd4a2083070c3bcce9c014ee04a443847c0b"
        let result = CryptoUtils.hmacSha256(message: message, key: key)
        XCTAssertEqual(result, expected)
    }
}
