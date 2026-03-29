import Foundation

struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTrackList?
}

struct SpotifyTrackList: Codable {
    let items: [SpotifyTrack]
}

struct SpotifyTrack: Codable, Identifiable {
    let id: String
    let uri: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let durationMs: Int

    enum CodingKeys: String, CodingKey {
        case id, uri, name, artists, album
        case durationMs = "duration_ms"
    }

    var artistNames: String {
        artists.map(\.name).joined(separator: ", ")
    }

    func toSong(addedBy: String) -> Song {
        Song(
            id: UUID().uuidString,
            spotifyURI: uri,
            title: name,
            artist: artistNames,
            albumName: album.name,
            albumArtURL: album.bestImageURL,
            durationMs: durationMs,
            addedBy: addedBy,
            addedAt: Date()
        )
    }
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]

    var bestImageURL: URL? {
        let preferred = images.first { ($0.width ?? 0) >= 300 } ?? images.first
        return preferred.flatMap { URL(string: $0.url) }
    }
}

struct SpotifyImage: Codable {
    let url: String
    let width: Int?
    let height: Int?
}
