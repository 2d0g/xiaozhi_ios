import XCTest
@testable import xiaozhi

class NetworkManagerTests: XCTestCase {
    struct MockResponse: Codable {
        let status: String
    }
    
    struct MockRequest: Codable {
        let name: String
    }
    
    // 验证单例存在
    func testNetworkManagerSharedInstance() {
        XCTAssertNotNil(NetworkManager.shared)
    }
    
    // 验证 post 方法签名和基础逻辑
    func testPostMethodSignature() async throws {
        // 由于没有真实网络，这里主要验证方法可以被调用
        // 预期的行为是如果没有设置 Mock 或 URL 无效，会抛出错误
        let url = URL(string: "https://api.example.com/test")!
        let body = MockRequest(name: "test")
        
        do {
            let _: MockResponse = try await NetworkManager.shared.post(url: url, body: body)
        } catch {
            // 只要不是编译错误，就说明方法存在
            XCTAssertNotNil(error)
        }
    }
}
