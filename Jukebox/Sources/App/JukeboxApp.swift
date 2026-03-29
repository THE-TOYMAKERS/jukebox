import SwiftUI
import FirebaseCore

@main
struct JukeboxApp: App {

    init() {
        FirebaseApp.configure()
        AudioSessionManager.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Handle Spotify callback
                    // This is handled in SpotifyConnectView via ASWebAuthenticationSession
                }
        }
    }
}
