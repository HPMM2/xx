import SwiftUI

struct ChatView: View {
    @StateObject private var vm = ChatViewModel()
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                clientHeader; Divider(); messageList; Divider(); inputBar
            }
            .navigationTitle("Churn Hunters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Limpiar") { vm.clearConversation() }.disabled(vm.messages.isEmpty) } }
        }
    }
    private var clientHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.badge.shield.checkmark").font(.title2).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("ID del Cliente").font(.caption).foregroundStyle(.secondary)
                TextField("Ej. C001", text: $vm.clientID).textFieldStyle(.plain).font(.body.weight(.semibold)).autocorrectionDisabled().textInputAutocapitalization(.characters)
            }
        }
        .padding(.horizontal).padding(.vertical, 10).background(Color(.systemGroupedBackground))
    }
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if vm.messages.isEmpty { emptyState }
                    ForEach(vm.messages) { msg in MessageBubble(message: msg).id(msg.id) }
                    if vm.isLoading { TypingIndicator().id("typing") }
                    if let err = vm.errorMessage { ErrorBanner(message: err) }
                }.padding(.horizontal).padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _ in scroll(proxy) }
            .onChange(of: vm.isLoading) { _ in scroll(proxy) }
        }
    }
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle").font(.system(size: 52)).foregroundStyle(.blue.opacity(0.6))
            Text("Ingresa el ID de un cliente y\npregunta al agente de retención.").multilineTextAlignment(.center).foregroundStyle(.secondary).font(.callout)
        }.frame(maxWidth: .infinity).padding(.top, 60)
    }
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("¿Por qué está en riesgo el cliente?", text: $vm.inputText, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(1...4).onSubmit { vm.sendMessage() }
            Button(action: vm.sendMessage) { Image(systemName: "arrow.up.circle.fill").font(.system(size: 32)).foregroundStyle(vm.canSend ? .blue : .gray) }.disabled(!vm.canSend)
        }.padding(.horizontal).padding(.vertical, 8).background(Color(.systemBackground))
    }
    private func scroll(_ proxy: ScrollViewProxy) {
        if vm.isLoading { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
        else if let last = vm.messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }
    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(message.text).padding(.horizontal, 14).padding(.vertical, 10)
                .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18)).textSelection(.enabled)
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

struct TypingIndicator: View {
    @State private var opacity = 0.3
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in Circle().frame(width: 8, height: 8).foregroundStyle(.secondary).opacity(opacity).animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: opacity) }
            Spacer()
        }.onAppear { opacity = 1.0 }
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red); Text(message).font(.caption).foregroundStyle(.red) }
        .padding(10).background(Color.red.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview { ChatView() }
