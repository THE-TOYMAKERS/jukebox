import SwiftUI

struct ChatView: View {
    @ObservedObject var chat: ChatService

    @State private var messageText = ""
    @State private var isExpanded = true
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Chat Header / Toggle
            chatHeader

            if isExpanded {
                // Messages
                messagesArea

                // Input
                chatInput
            }
        }
        .glassCard()
        .padding(.horizontal)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }

    // MARK: - Header

    private var chatHeader: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline)
                    .foregroundStyle(JukeboxTheme.spotifyGreen)

                Text("Live Chat")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(JukeboxTheme.textPrimary)

                if !chat.messages.isEmpty {
                    Text("\(chat.messages.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(JukeboxTheme.spotifyGreen)
                        .clipShape(Capsule())
                }

                Spacer()

                Text(chat.sessionName)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: chat.sessionColor))

                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.caption)
                    .foregroundStyle(JukeboxTheme.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Messages Area

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(chat.messages) { message in
                        ChatBubble(
                            message: message,
                            isOwnMessage: message.senderName == chat.sessionName
                        )
                        .id(message.id)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 200)
            .onChange(of: chat.messages.count) {
                withAnimation(.spring(response: 0.3)) {
                    if let lastID = chat.messages.last?.id {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input

    private var chatInput: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: chat.sessionColor))
                    .frame(width: 8, height: 8)

                TextField("Say something...", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(JukeboxTheme.textPrimary)
                    .focused($isInputFocused)
                    .submitLabel(.send)
                    .onSubmit { sendMessage() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.05))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isInputFocused ? JukeboxTheme.spotifyGreen.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )

            if !messageText.isEmpty {
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(JukeboxTheme.spotifyGreen)
                        .symbolEffect(.bounce, value: messageText)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .animation(.spring(response: 0.3), value: messageText.isEmpty)
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        chat.send(text)
        messageText = ""

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    let isOwnMessage: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if isOwnMessage { Spacer(minLength: 40) }

            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 2) {
                if !isOwnMessage {
                    Text(message.senderName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: message.senderColor))
                }

                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(JukeboxTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isOwnMessage
                            ? JukeboxTheme.spotifyGreen.opacity(0.2)
                            : Color.white.opacity(0.08)
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )

                Text(message.timeAgo)
                    .font(.caption2)
                    .foregroundStyle(JukeboxTheme.textTertiary)
            }

            if !isOwnMessage { Spacer(minLength: 40) }
        }
    }
}
