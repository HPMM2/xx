import Foundation

enum NetworkError: LocalizedError {
    case invalidURL, requestFailed(statusCode: Int, detail: String), decodingFailed(String), unknown(Error)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida."
        case .requestFailed(let c, let d): return "Error \(c): \(d)"
        case .decodingFailed(let m): return "Error al decodificar: \(m)"
        case .unknown(let e): return e.localizedDescription
        }
    }
}

final class NetworkManager {
    static let baseURL = "http://localhost:8000/api/v1"
    static let shared = NetworkManager()
    private init() {}
    private let session: URLSession = { let c = URLSessionConfiguration.default; c.timeoutIntervalForRequest = 60; return URLSession(configuration: c) }()
    func sendMessage(sessionID: String, clientID: String, message: String) async throws -> ChatResponse {
        guard let url = URL(string: "\(Self.baseURL)/chat") else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(ChatRequest(session_id: sessionID, client_id: clientID, message: message))
        let (data, res) = try await session.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw NetworkError.unknown(URLError(.badServerResponse)) }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.requestFailed(statusCode: http.statusCode, detail: (try? JSONDecoder().decode(APIError.self, from: data))?.detail ?? "Sin detalles")
        }
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }
    func clearSession(sessionID: String) async throws {
        guard let url = URL(string: "\(Self.baseURL)/session/clear") else { throw NetworkError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["session_id": sessionID])
        _ = try await session.data(for: req)
    }
}
