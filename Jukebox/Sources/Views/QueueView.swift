import SwiftUI

struct QueueView: View {
    @ObservedObject var jukebox: JukeboxService
    @ObservedObject var spotify: SpotifyService

    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if jukebox.queue.isEmpty {
                emptyQueue
            } else {
                queueList
            }
        }
        .glassCard()
        .padding(.horizontal)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Label("Up Next", systemImage: "list.bullet")
                .font(.headline)
                .foregroundStyle(JukeboxTheme.textPrimary)

            Spacer()

            if !jukebox.queue.isEmpty {
                Text("\(jukebox.queue.count) songs")
                    .font(.caption)
                    .foregroundStyle(JukeboxTheme.textTertiary)

                Button {
                    showingClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(JukeboxTheme.destructive)
                }
                .confirmationDialog(
                    "Clear the queue?",
                    isPresented: $showingClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) {
                        withAnimation { jukebox.clearQueue() }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Queue List

    private var queueList: some View {
        LazyVStack(spacing: 2) {
            ForEach(Array(jukebox.queue.enumerated()), id: \.element.id) { index, song in
                QueueRow(
                    song: song,
                    index: index + 1,
                    onPlay: {
                        jukebox.setNowPlaying(song)
                        Task {
                            let uris = [song.spotifyURI] + jukebox.queue.map(\.spotifyURI)
                            await spotify.playQueue(uris: uris)
                        }
                    },
                    onRemove: {
                        withAnimation(.spring(response: 0.3)) {
                            jukebox.removeFromQueue(song)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Empty State

    private var emptyQueue: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.title2)
                .foregroundStyle(JukeboxTheme.textTertiary)

            Text("Queue is empty")
                .font(.subheadline)
                .foregroundStyle(JukeboxTheme.textSecondary)

            Text("Search for songs to add")
                .font(.caption)
                .foregroundStyle(JukeboxTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.bottom, 8)
    }
}

// MARK: - Queue Row

struct QueueRow: View {
    let song: Song
    let index: Int
    let onPlay: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .foregroundStyle(JukeboxTheme.textTertiary)
                .frame(width: 20)

            // Album Art Thumbnail
            AsyncImage(url: song.albumArtURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption2)
                            .foregroundStyle(JukeboxTheme.textTertiary)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(JukeboxTheme.textPrimary)
                    .lineLimit(1)

                Text(song.artist)
                    .font(.caption)
                    .foregroundStyle(JukeboxTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(song.durationFormatted)
                .font(.caption2)
                .foregroundStyle(JukeboxTheme.textTertiary)
                .monospacedDigit()

            // Quick Actions
            HStack(spacing: 4) {
                Button(action: onPlay) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(JukeboxTheme.spotifyGreen)
                }
                .buttonStyle(.plain)

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(JukeboxTheme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onPlay()
            } label: {
                Label("Play Now", systemImage: "play.fill")
            }
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}
