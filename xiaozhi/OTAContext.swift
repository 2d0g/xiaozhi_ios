import Foundation

struct OTAPayload: Codable {
    struct Application: Codable {
        let version: String
        let elf_sha256: String
    }
    struct Board: Codable {
        let type: String
        let name: String
        let ip: String
        let mac: String
    }
    let application: Application
    let board: Board
}

struct OTAResponse: Codable {
    let activation: ActivationData?
    let websocket: WebSocketConfig?
    
    struct ActivationData: Codable {
        let code: String
        let challenge: String
    }
    
    struct WebSocketConfig: Codable {
        let url: String
        let token: String
    }
}
