import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var spotify: SpotifyService
    @ObservedObject var jukebox: JukeboxService

    @State private var isExpanded = false
    @State private var artworkRotation: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            if let song = jukebox.nowPlaying {
                expandedPlayer(song: song)
            } else {
                emptyState
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: jukebox.nowPlaying?.id)
    }

    // MARK: - Expanded Player

    private func expandedPlayer(song: Song) -> some View {
        VStack(spacing: 20) {
            // Album Art
            albumArt(url: song.albumArtURL)
                .frame(width: 260, height: 260)
                .padding(.top, 8)

            // Track Info
            VStack(spacing: 6) {
                Text(song.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(JukeboxTheme.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.subheadline)
                    .foregroundStyle(JukeboxTheme.textSecondary)
                    .lineLimit(1)
            }

            // Progress Bar
            progressBar

            // Controls
            playbackControls

            // Queue Info
            HStack(spacing: 16) {
                Label("\(jukebox.listenerCount)", systemImage: "headphones")
                    .font(.caption)
                    .foregroundStyle(JukeboxTheme.textTertiary)

                Label("\(jukebox.queue.count) in queue", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(JukeboxTheme.textTertiary)
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .glassCard()
        .padding(.horizontal)
    }

    // MARK: - Album Art

    private func albumArt(url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        artworkPlaceholder
                    case .empty:
                        artworkPlaceholder
                            .overlay(ProgressView().tint(.white))
                    @unknown default:
                        artworkPlaceholder
                    }
                }
            } else {
                artworkPlaceholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: JukeboxTheme.spotifyGreen.opacity(0.3), radius: 20, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1A1A2E"), Color(hex: "16213E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: 60))
                .foregroundStyle(JukeboxTheme.textTertiary)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(JukeboxTheme.spotifyGreen)
                        .frame(width: geo.size.width * spotify.playbackProgress, height: 4)
                        .animation(.linear(duration: 1), value: spotify.playbackProgress)
                }
            }
            .frame(height: 4)

            HStack {
                Text(formatTime(Int(spotify.playbackProgress * Double(spotify.currentTrackDuration))))
                    .font(.caption2)
                    .foregroundStyle(JukeboxTheme.textTertiary)
                    .monospacedDigit()

                Spacer()

                Text(formatTime(spotify.currentTrackDuration))
                    .font(.caption2)
                    .foregroundStyle(JukeboxTheme.textTertiary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button {
                Task { await spotify.skipToPrevious() }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundStyle(JukeboxTheme.textPrimary)
            }

            Button {
                Task {
                    if spotify.isPlaying {
                        await spotify.pause()
                        jukebox.setPlayingState(false)
                    } else if let song = jukebox.nowPlaying {
                        await spotify.play(uri: song.spotifyURI)
                        jukebox.setPlayingState(true)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(JukeboxTheme.spotifyGreen)
                        .frame(width: 64, height: 64)
                        .shadow(color: JukeboxTheme.spotifyGreen.opacity(0.5), radius: 12)

                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.black)
                        .offset(x: spotify.isPlaying ? 0 : 2)
                }
            }

            Button {
                Task {
                    await spotify.skipToNext()
                    jukebox.advanceQueue()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(JukeboxTheme.textPrimary)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)

                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 40))
                    .foregroundStyle(JukeboxTheme.textTertiary)
                    .symbolEffect(.pulse, options: .repeating)
            }

            VStack(spacing: 4) {
                Text("Nothing Playing")
                    .font(.headline)
                    .foregroundStyle(JukeboxTheme.textPrimary)

                Text("Add songs to the queue to get started")
                    .font(.subheadline)
                    .foregroundStyle(JukeboxTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard()
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func formatTime(_ ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
