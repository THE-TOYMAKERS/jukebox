import SwiftUI
import AuthenticationServices

struct SpotifyConnectView: View {
    @ObservedObject var spotify: SpotifyService

    @State private var isAuthenticating = false
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    var body: some View {
        VStack(spacing: 24) {
            // Spotify Logo Area
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                JukeboxTheme.spotifyGreen.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(JukeboxTheme.spotifyGreen)
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }

            VStack(spacing: 8) {
                Text("Connect to Spotify")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(JukeboxTheme.textPrimary)

                Text("Link your Spotify Premium account to\ncontrol playback on the jukebox")
                    .font(.subheadline)
                    .foregroundStyle(JukeboxTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                authenticateWithSpotify()
            } label: {
                HStack(spacing: 10) {
                    if isAuthenticating {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "link")
                            .fontWeight(.semibold)
                    }

                    Text(isAuthenticating ? "Connecting..." : "Connect Spotify")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(JukeboxTheme.spotifyGreen)
                .clipShape(Capsule())
                .shadow(color: JukeboxTheme.spotifyGreen.opacity(0.4), radius: 12, y: 4)
            }
            .disabled(isAuthenticating)
            .padding(.horizontal, 40)

            Text("Requires Spotify Premium for playback")
                .font(.caption)
                .foregroundStyle(JukeboxTheme.textTertiary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .glassCard()
        .padding(.horizontal)
    }

    private func authenticateWithSpotify() {
        guard let authURL = spotify.getAuthURL() else { return }
        isAuthenticating = true

        Task {
            do {
                let callbackURL = try await webAuthenticationSession.authenticate(
                    using: authURL,
                    callbackURLScheme: SpotifyConfig.urlScheme
                )
                await spotify.handleCallback(url: callbackURL)
            } catch {
                print("Auth cancelled or failed: \(error)")
            }
            isAuthenticating = false
        }
    }
}
