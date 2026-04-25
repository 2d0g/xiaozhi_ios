import XCTest
@testable import xiaozhi

class IdentityTests: XCTestCase {
    func testIdentityPersistence() {
        let sn1 = DeviceFingerprint.shared.getOrGenerateSN()
        let sn2 = DeviceFingerprint.shared.getOrGenerateSN()
        XCTAssertEqual(sn1, sn2)
        XCTAssertTrue(sn1.hasPrefix("IOS"))
        XCTAssertEqual(sn1.count, 15)
        
        let key1 = DeviceFingerprint.shared.getOrGenerateHMACKey()
        let key2 = DeviceFingerprint.shared.getOrGenerateHMACKey()
        XCTAssertEqual(key1, key2)
        XCTAssertEqual(key1.count, 32)
    }

    func testProjectInfrastructure() {
        // 检查 Bundle ID 是否符合预期，防止 pbxproj 被改坏
        let bundleID = Bundle.main.bundleIdentifier
        XCTAssertNotNil(bundleID, "Bundle Identifier 缺失，项目配置已损坏")
        XCTAssertEqual(bundleID, "com.xd0g.xiaozhi", "Bundle ID 与设计不符")
    }
}
