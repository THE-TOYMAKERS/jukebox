import SwiftUI

struct ContentView: View {
    @StateObject private var spotify = SpotifyService()
    @StateObject private var jukebox = JukeboxService()
    @StateObject private var chat = ChatService()

    @State private var showingSearch = false
    @State private var selectedTab: Tab = .jukebox

    enum Tab {
        case jukebox, queue
    }

    var body: some View {
        ZStack {
            // Background
            JukeboxTheme.backgroundGradient
                .ignoresSafeArea()

            // Animated background particles
            AnimatedBackground()
                .ignoresSafeArea()
                .opacity(0.5)

            // Main Content
            VStack(spacing: 0) {
                // Header
                header

                // Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        if spotify.isConnected {
                            NowPlayingView(spotify: spotify, jukebox: jukebox)
                            QueueView(jukebox: jukebox, spotify: spotify)
                        } else {
                            SpotifyConnectView(spotify: spotify)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 120) // Space for chat
                }

                Spacer(minLength: 0)

                // Chat always visible at the bottom
                ChatView(chat: chat)
                    .padding(.bottom, 8)
            }

            // FAB - Add Songs
            if spotify.isConnected {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        addButton
                            .padding(.trailing, 20)
                            .padding(.bottom, 320) // Above the chat
                    }
                }
            }
        }
        .sheet(isPresented: $showingSearch) {
            SearchView(spotify: spotify, jukebox: jukebox, chat: chat)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("JUKEBOX")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [JukeboxTheme.spotifyGreen, Color(hex: "45B7D1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if spotify.isConnected {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(JukeboxTheme.spotifyGreen)
                            .frame(width: 6, height: 6)

                        Text("Connected")
                            .font(.caption2)
                            .foregroundStyle(JukeboxTheme.textTertiary)
                    }
                }
            }

            Spacer()

            if spotify.isConnected {
                HStack(spacing: 12) {
                    // Listener count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                        Text("\(jukebox.listenerCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(JukeboxTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassCardSmall()

                    // Disconnect
                    Button {
                        spotify.disconnect()
                    } label: {
                        Image(systemName: "power")
                            .font(.subheadline)
                            .foregroundStyle(JukeboxTheme.destructive)
                            .padding(8)
                            .glassCardSmall()
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showingSearch = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(JukeboxTheme.spotifyGreen)
                .clipShape(Circle())
                .shadow(color: JukeboxTheme.spotifyGreen.opacity(0.5), radius: 16, y: 4)
        }
        .symbolEffect(.bounce, options: .nonRepeating)
    }
}

// MARK: - Animated Background

struct AnimatedBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Floating orbs
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                JukeboxTheme.spotifyGreen.opacity(0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
                        y: animate ? CGFloat.random(in: -200...200) : CGFloat.random(in: -100...100)
                    )
                    .blur(radius: 40)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
