import Foundation
import Combine
import FirebaseDatabase

@MainActor
final class ChatService: ObservableObject {

    // MARK: - Published State

    @Published var messages: [ChatMessage] = []

    // MARK: - Private

    private let db = Database.database().reference().child("chat")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var handle: DatabaseHandle?

    /// Each user gets a random display name and color for the session
    let sessionName: String
    let sessionColor: String

    private static let adjectives = [
        "Cosmic", "Electric", "Neon", "Velvet", "Crystal",
        "Lunar", "Solar", "Mystic", "Golden", "Phantom",
        "Turbo", "Hyper", "Ultra", "Mega", "Astral"
    ]
    private static let nouns = [
        "DJ", "Vibe", "Beat", "Wave", "Pulse",
        "Flow", "Groove", "Rhythm", "Echo", "Sonic",
        "Bass", "Treble", "Chord", "Melody", "Tempo"
    ]

    init() {
        sessionName = "\(Self.adjectives.randomElement()!) \(Self.nouns.randomElement()!)"
        sessionColor = JukeboxTheme.randomChatColor()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        decoder.dateDecodingStrategy = .millisecondsSince1970
        observeMessages()
        cleanupOnDisconnect()
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.removeObserver()
        }
    }

    // MARK: - Send

    func send(_ text: String) {
        let message = ChatMessage(
            id: UUID().uuidString,
            text: text,
            senderName: sessionName,
            senderColor: sessionColor,
            timestamp: Date()
        )

        guard let data = try? encoder.encode(message),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        db.child(message.id).setValue(dict)

        // Auto-expire messages after 5 minutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) { [weak self] in
            self?.db.child(message.id).removeValue()
        }
    }

    // MARK: - Observe

    private func observeMessages() {
        // Only keep the last 50 messages
        let query = db.queryOrdered(byChild: "timestamp").queryLimited(toLast: 50)
        handle = query.observe(.value) { [weak self] snapshot in
            guard let self else { return }
            var msgs: [ChatMessage] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any],
                      let data = try? JSONSerialization.data(withJSONObject: dict),
                      let message = try? self.decoder.decode(ChatMessage.self, from: data) else { continue }
                msgs.append(message)
            }
            Task { @MainActor [weak self] in
                self?.messages = msgs.sorted { $0.timestamp < $1.timestamp }
            }
        }
    }

    private func cleanupOnDisconnect() {
        // Firebase onDisconnect to clean up user's messages
        // For simplicity we don't track per-user messages here,
        // but messages auto-expire after 5 minutes anyway
    }

    private func removeObserver() {
        if let handle {
            db.removeObserver(withHandle: handle)
        }
    }

    func clearAllMessages() {
        db.removeValue()
    }
}
