import SwiftUI

struct SearchView: View {
    @ObservedObject var spotify: SpotifyService
    @ObservedObject var jukebox: JukeboxService
    @ObservedObject var chat: ChatService

    @State private var query = ""
    @State private var results: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var addedTrackIDs: Set<String> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                JukeboxTheme.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    resultsList
                }
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(JukeboxTheme.spotifyGreen)
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(JukeboxTheme.textTertiary)

            TextField("Search songs, artists...", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(JukeboxTheme.textPrimary)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { performSearch() }
                .onChange(of: query) {
                    debounceSearch()
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(JukeboxTheme.textTertiary)
                }
            }

            if isSearching {
                ProgressView()
                    .tint(JukeboxTheme.spotifyGreen)
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(JukeboxTheme.cardBorder, lineWidth: 0.5)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Results List

    private var resultsList: some View {
        Group {
            if results.isEmpty && !query.isEmpty && !isSearching {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try searching for something else")
                )
            } else if results.isEmpty && query.isEmpty {
                ContentUnavailableView(
                    "Search Spotify",
                    systemImage: "music.magnifyingglass",
                    description: Text("Find songs to add to the jukebox")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(results) { track in
                            SearchResultRow(
                                track: track,
                                isAdded: addedTrackIDs.contains(track.id),
                                onAdd: {
                                    addTrack(track)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Actions

    private func debounceSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
            guard !Task.isCancelled, !query.isEmpty else { return }
            performSearch()
        }
    }

    private func performSearch() {
        guard !query.isEmpty else { return }
        isSearching = true
        Task {
            results = await spotify.search(query: query)
            isSearching = false
        }
    }

    private func addTrack(_ track: SpotifyTrack) {
        let song = track.toSong(addedBy: chat.sessionName)
        withAnimation(.spring(response: 0.3)) {
            jukebox.addToQueue(song)
            addedTrackIDs.insert(track.id)
        }

        // If nothing is playing, start playing this song
        if jukebox.nowPlaying == nil {
            jukebox.setNowPlaying(song)
            Task {
                await spotify.play(uri: song.spotifyURI)
            }
        }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let track: SpotifyTrack
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: track.album.bestImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundStyle(JukeboxTheme.textTertiary)
                    )
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(JukeboxTheme.textPrimary)
                    .lineLimit(1)

                Text(track.artistNames)
                    .font(.caption)
                    .foregroundStyle(JukeboxTheme.textSecondary)
                    .lineLimit(1)

                Text(track.album.name)
                    .font(.caption2)
                    .foregroundStyle(JukeboxTheme.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onAdd) {
                Group {
                    if isAdded {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(JukeboxTheme.spotifyGreen)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(JukeboxTheme.spotifyGreen)
                    }
                }
                .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(isAdded)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
    }
}
