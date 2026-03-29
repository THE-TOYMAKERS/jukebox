import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: String
    let spotifyURI: String
    let title: String
    let artist: String
    let albumName: String
    let albumArtURL: URL?
    let durationMs: Int
    let addedBy: String
    let addedAt: Date

    var durationFormatted: String {
        let totalSeconds = durationMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}

extension Song {
    static let preview = Song(
        id: "preview-1",
        spotifyURI: "spotify:track:4uLU6hMCjMI75M1A2tKUQC",
        title: "Never Gonna Give You Up",
        artist: "Rick Astley",
        albumName: "Whenever You Need Somebody",
        albumArtURL: URL(string: "https://i.scdn.co/image/ab67616d0000b273"),
        durationMs: 213000,
        addedBy: "DJ",
        addedAt: Date()
    )
}
