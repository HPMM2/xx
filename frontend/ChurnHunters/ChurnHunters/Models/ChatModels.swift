import Foundation

struct ChatRequest: Encodable {
    let session_id: String
    let client_id: String
    let message: String
}
struct ChatResponse: Decodable {
    let session_id: String
    let client_id: String
    let reply: String
}
struct APIError: Decodable { let detail: String }
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let text: String
    let timestamp = Date()
    enum Role { case user, agent }
}
