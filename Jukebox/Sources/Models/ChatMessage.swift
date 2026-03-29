import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let senderName: String
    let senderColor: String
    let timestamp: Date

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        return "\(Int(interval / 3600))h"
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

extension ChatMessage {
    static let preview = ChatMessage(
        id: UUID().uuidString,
        text: "This song slaps 🔥",
        senderName: "DJ",
        senderColor: "#FF6B6B",
        timestamp: Date()
    )
}
