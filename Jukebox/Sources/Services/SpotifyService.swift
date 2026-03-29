import Foundation
import Combine
import AuthenticationServices

@MainActor
final class SpotifyService: ObservableObject {

    // MARK: - Configuration

    /// Set these in SpotifyConfig.swift or via environment
    static var clientID: String { SpotifyConfig.clientID }
    static var redirectURI: String { SpotifyConfig.redirectURI }
    private static let scopes = [
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "streaming",
        "playlist-read-private",
        "user-library-read"
    ].joined(separator: " ")

    private static let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
    private static let apiBase = "https://api.spotify.com/v1"

    // MARK: - Published State

    @Published var isConnected = false
    @Published var isPlaying = false
    @Published var currentTrackName: String?
    @Published var currentArtistName: String?
    @Published var currentAlbumArtURL: URL?
    @Published var playbackProgress: Double = 0
    @Published var currentTrackDuration: Int = 0

    // MARK: - Private State

    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiry: Date?
    private var codeVerifier: String?
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Auth (PKCE Flow)

    func getAuthURL() -> URL? {
        let verifier = generateCodeVerifier()
        codeVerifier = verifier
        guard let challenge = generateCodeChallenge(from: verifier) else { return nil }

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: Self.redirectURI),
            URLQueryItem(name: "scope", value: Self.scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "show_dialog", value: "true")
        ]
        return components.url
    }

    func handleCallback(url: URL) async {
        guard let code = URLComponents(string: url.absoluteString)?
            .queryItems?.first(where: { $0.name == "code" })?.value else { return }
        await exchangeCode(code)
    }

    private func exchangeCode(_ code: String) async {
        guard let verifier = codeVerifier else { return }

        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": Self.redirectURI,
            "client_id": Self.clientID,
            "code_verifier": verifier
        ]

        await performTokenRequest(params: params)
    }

    func refreshAccessToken() async {
        guard let refreshToken else { return }

        let params: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": Self.clientID
        ]

        await performTokenRequest(params: params)
    }

    private func performTokenRequest(params: [String: String]) async {
        var request = URLRequest(url: Self.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = params
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TokenResponse.self, from: data)
            accessToken = response.accessToken
            if let rt = response.refreshToken { refreshToken = rt }
            tokenExpiry = Date().addingTimeInterval(TimeInterval(response.expiresIn - 60))
            isConnected = true
            startPlaybackPolling()
        } catch {
            print("Token error: \(error)")
        }
    }

    // MARK: - API Calls

    func search(query: String) async -> [SpotifyTrack] {
        guard let token = await validToken() else { return [] }

        var components = URLComponents(string: "\(Self.apiBase)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components.url else { return [] }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            return result.tracks?.items ?? []
        } catch {
            print("Search error: \(error)")
            return []
        }
    }

    func play(uri: String) async {
        guard let token = await validToken() else { return }

        let url = URL(string: "\(Self.apiBase)/me/player/play")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["uris": [uri]])

        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            isPlaying = true
        } catch {
            print("Play error: \(error)")
        }
    }

    func playQueue(uris: [String], offset: Int = 0) async {
        guard let token = await validToken() else { return }

        let url = URL(string: "\(Self.apiBase)/me/player/play")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "uris": uris,
            "offset": ["position": offset]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            isPlaying = true
        } catch {
            print("PlayQueue error: \(error)")
        }
    }

    func pause() async {
        guard let token = await validToken() else { return }

        let url = URL(string: "\(Self.apiBase)/me/player/pause")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            isPlaying = false
        } catch {
            print("Pause error: \(error)")
        }
    }

    func skipToNext() async {
        guard let token = await validToken() else { return }

        let url = URL(string: "\(Self.apiBase)/me/player/next")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do { let (_, _) = try await URLSession.shared.data(for: request) }
        catch { print("Skip error: \(error)") }
    }

    func skipToPrevious() async {
        guard let token = await validToken() else { return }

        let url = URL(string: "\(Self.apiBase)/me/player/previous")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do { let (_, _) = try await URLSession.shared.data(for: request) }
        catch { print("Previous error: \(error)") }
    }

    // MARK: - Playback Polling

    private func startPlaybackPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchPlaybackState()
            }
        }
    }

    private func fetchPlaybackState() async {
        guard let token = await validToken() else { return }

        let url = URL(string: "\(Self.apiBase)/me/player/currently-playing")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isPlaying = false
                return
            }
            let state = try JSONDecoder().decode(PlaybackState.self, from: data)
            isPlaying = state.isPlaying
            currentTrackName = state.item?.name
            currentArtistName = state.item?.artists.map(\.name).joined(separator: ", ")
            currentAlbumArtURL = state.item?.album.bestImageURL
            currentTrackDuration = state.item?.durationMs ?? 0
            if currentTrackDuration > 0 {
                playbackProgress = Double(state.progressMs ?? 0) / Double(currentTrackDuration)
            }
        } catch {
            // Silently handle - polling will retry
        }
    }

    // MARK: - Token Management

    private func validToken() async -> String? {
        if let expiry = tokenExpiry, Date() >= expiry {
            await refreshAccessToken()
        }
        return accessToken
    }

    func disconnect() {
        accessToken = nil
        refreshToken = nil
        tokenExpiry = nil
        isConnected = false
        isPlaying = false
        pollingTimer?.invalidate()
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(128)
            .description
    }

    private func generateCodeChallenge(from verifier: String) -> String? {
        guard let data = verifier.data(using: .ascii) else { return nil }
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Token Response

private struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

// MARK: - Playback State

private struct PlaybackState: Codable {
    let isPlaying: Bool
    let progressMs: Int?
    let item: SpotifyTrack?

    enum CodingKeys: String, CodingKey {
        case isPlaying = "is_playing"
        case progressMs = "progress_ms"
        case item
    }
}
