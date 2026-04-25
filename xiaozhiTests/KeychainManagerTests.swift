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
