import XCTest
@testable import xiaozhi

final class OTAServiceTests: XCTestCase {
    
    func testOTARequestModel() {
        let request = OTARequest(
            method: "ota",
            device_id: "IOS1234567890AB",
            project_id: "xiaozhi-ios",
            version: "1.0.0",
            mac_address: "00:00:00:00:00:00"
        )
        
        XCTAssertEqual(request.method, "ota")
        XCTAssertEqual(request.device_id, "IOS1234567890AB")
        XCTAssertEqual(request.project_id, "xiaozhi-ios")
        XCTAssertEqual(request.version, "1.0.0")
        XCTAssertEqual(request.mac_address, "00:00:00:00:00:00")
    }
    
    func testOTAResponseModel() throws {
        let json = """
        {
            "status": "success",
            "message": "Handshake successful",
            "data": {
                "code": "123456",
                "token": "test-token",
                "websocket_url": "wss://xiaozhi.me/ws"
            }
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(OTAResponse.self, from: json)
        
        XCTAssertEqual(response.status, "success")
        XCTAssertEqual(response.message, "Handshake successful")
        XCTAssertEqual(response.data.code, "123456")
        XCTAssertEqual(response.data.token, "test-token")
        XCTAssertEqual(response.data.websocket_url, "wss://xiaozhi.me/ws")
    }
    
    func testOTAServiceShared() {
        let service = OTAService.shared
        XCTAssertNotNil(service)
    }
    
    // Note: Testing async handshake() would typically require mocking NetworkManager
    // For this task, we focus on model definitions and method signatures.
}
