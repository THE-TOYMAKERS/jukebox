import Foundation
import Combine
import FirebaseDatabase

@MainActor
final class JukeboxService: ObservableObject {

    // MARK: - Published State

    @Published var queue: [Song] = []
    @Published var nowPlaying: Song?
    @Published var isPlaying = false
    @Published var listenerCount: Int = 0

    // MARK: - Private

    private let db = Database.database().reference()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var handles: [DatabaseHandle] = []

    init() {
        encoder.dateEncodingStrategy = .millisecondsSince1970
        decoder.dateDecodingStrategy = .millisecondsSince1970
        observeQueue()
        observeNowPlaying()
        observeListenerCount()
        incrementListenerCount()
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.decrementListenerCount()
            self?.removeObservers()
        }
    }

    // MARK: - Queue Management

    func addToQueue(_ song: Song) {
        guard let data = try? encoder.encode(song),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        db.child("queue").child(song.id).setValue(dict)
    }

    func removeFromQueue(_ song: Song) {
        db.child("queue").child(song.id).removeValue()
    }

    func moveInQueue(from source: IndexSet, to destination: Int) {
        var updated = queue
        updated.move(fromOffsets: source, toOffset: destination)
        // Re-write order by updating addedAt timestamps
        let now = Date()
        for (index, song) in updated.enumerated() {
            let reordered = Song(
                id: song.id,
                spotifyURI: song.spotifyURI,
                title: song.title,
                artist: song.artist,
                albumName: song.albumName,
                albumArtURL: song.albumArtURL,
                durationMs: song.durationMs,
                addedBy: song.addedBy,
                addedAt: now.addingTimeInterval(Double(index))
            )
            if let data = try? encoder.encode(reordered),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                db.child("queue").child(reordered.id).setValue(dict)
            }
        }
    }

    func setNowPlaying(_ song: Song?) {
        if let song {
            if let data = try? encoder.encode(song),
               let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                db.child("nowPlaying").setValue(dict)
                db.child("isPlaying").setValue(true)
            }
            removeFromQueue(song)
        } else {
            db.child("nowPlaying").removeValue()
            db.child("isPlaying").setValue(false)
        }
    }

    func setPlayingState(_ playing: Bool) {
        db.child("isPlaying").setValue(playing)
    }

    func advanceQueue() {
        guard let next = queue.first else {
            setNowPlaying(nil)
            return
        }
        setNowPlaying(next)
    }

    func clearQueue() {
        db.child("queue").removeValue()
    }

    // MARK: - Observers

    private func observeQueue() {
        let handle = db.child("queue").observe(.value) { [weak self] snapshot in
            guard let self else { return }
            var songs: [Song] = []
            for child in snapshot.children {
                guard let snap = child as? DataSnapshot,
                      let dict = snap.value as? [String: Any],
                      let data = try? JSONSerialization.data(withJSONObject: dict),
                      let song = try? self.decoder.decode(Song.self, from: data) else { continue }
                songs.append(song)
            }
            Task { @MainActor [weak self] in
                self?.queue = songs.sorted { $0.addedAt < $1.addedAt }
            }
        }
        handles.append(handle)
    }

    private func observeNowPlaying() {
        let handle = db.child("nowPlaying").observe(.value) { [weak self] snapshot in
            guard let self else { return }
            guard let dict = snapshot.value as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: dict),
                  let song = try? self.decoder.decode(Song.self, from: data) else {
                Task { @MainActor [weak self] in
                    self?.nowPlaying = nil
                }
                return
            }
            Task { @MainActor [weak self] in
                self?.nowPlaying = song
            }
        }
        handles.append(handle)

        let playingHandle = db.child("isPlaying").observe(.value) { [weak self] snapshot in
            let playing = snapshot.value as? Bool ?? false
            Task { @MainActor [weak self] in
                self?.isPlaying = playing
            }
        }
        handles.append(playingHandle)
    }

    private func observeListenerCount() {
        let handle = db.child("listeners").observe(.value) { [weak self] snapshot in
            let count = snapshot.value as? Int ?? 0
            Task { @MainActor [weak self] in
                self?.listenerCount = max(0, count)
            }
        }
        handles.append(handle)
    }

    private func incrementListenerCount() {
        db.child("listeners").runTransactionBlock { data in
            let current = data.value as? Int ?? 0
            data.value = current + 1
            return TransactionResult.success(withValue: data)
        }
    }

    private func decrementListenerCount() {
        db.child("listeners").runTransactionBlock { data in
            let current = data.value as? Int ?? 0
            data.value = max(0, current - 1)
            return TransactionResult.success(withValue: data)
        }
    }

    private func removeObservers() {
        for handle in handles {
            db.removeObserver(withHandle: handle)
        }
        handles.removeAll()
    }
}
