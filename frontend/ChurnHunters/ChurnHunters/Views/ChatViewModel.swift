import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var clientID = ""
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    private let sessionID = UUID().uuidString
    var canSend: Bool { !clientID.trimmingCharacters(in: .whitespaces).isEmpty && !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading }
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        let cid = clientID.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !cid.isEmpty else { return }
        messages.append(ChatMessage(role: .user, text: text))
        inputText = ""; isLoading = true; errorMessage = nil
        Task {
            defer { isLoading = false }
            do {
                let r = try await NetworkManager.shared.sendMessage(sessionID: sessionID, clientID: cid, message: text)
                messages.append(ChatMessage(role: .agent, text: r.reply))
            } catch { errorMessage = error.localizedDescription }
        }
    }
    func clearConversation() { messages = []; errorMessage = nil; Task { try? await NetworkManager.shared.clearSession(sessionID: sessionID) } }
}
