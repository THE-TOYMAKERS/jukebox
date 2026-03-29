import Foundation

/// Configure your Spotify app credentials here.
/// Create an app at https://developer.spotify.com/dashboard
enum SpotifyConfig {
    /// Your Spotify App Client ID
    static let clientID = "YOUR_SPOTIFY_CLIENT_ID"

    /// Your registered redirect URI (must match Spotify Dashboard settings)
    /// Format: "jukebox://callback"
    static let redirectURI = "jukebox://callback"

    /// The URL scheme used for deep linking (derived from redirectURI)
    static var urlScheme: String {
        URL(string: redirectURI)?.scheme ?? "jukebox"
    }
}
