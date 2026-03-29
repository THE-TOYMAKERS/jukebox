# Jukebox 🎵

A shared real-time jukebox iOS app powered by Spotify. Everyone on the app listens to the same playlist, can queue songs, and chat in real time.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4-purple)

## Features

- **Shared Jukebox** — One playlist that everyone listens to and can add to
- **Spotify Integration** — Connect your Spotify Premium account via OAuth PKCE
- **Real-Time Queue** — Add, reorder, and remove songs — synced instantly via Firebase
- **Background Playback** — Music keeps playing when the app is backgrounded or screen is off
- **Ephemeral Chat** — Real-time chat that disappears when you leave (no persistence)
- **Modern UI** — Glassmorphism, smooth animations, SF Symbols, dark theme

## Architecture

```
Jukebox/
├── Sources/
│   ├── App/             # App entry point
│   ├── Models/          # Song, ChatMessage, SpotifySearchResult
│   ├── Services/        # SpotifyService, JukeboxService, ChatService
│   ├── Views/           # SwiftUI views
│   └── Theme/           # Design system (colors, modifiers)
└── Resources/           # Assets, Info.plist, entitlements
```

### Key Services

| Service | Purpose | Backend |
|---------|---------|---------|
| `SpotifyService` | OAuth PKCE auth, search, playback control | Spotify Web API |
| `JukeboxService` | Shared queue, now playing, listener count | Firebase RTDB |
| `ChatService` | Ephemeral real-time chat | Firebase RTDB |
| `AudioSessionManager` | Background audio configuration | AVFoundation |

## Setup

### 1. Spotify App

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app
3. Add `jukebox://callback` as a Redirect URI
4. Copy your **Client ID**
5. Open `Jukebox/Sources/Services/SpotifyConfig.swift` and set your `clientID`

### 2. Firebase

1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Add an iOS app with bundle ID `com.toymakers.jukebox`
3. Download `GoogleService-Info.plist` and add it to `Jukebox/Resources/`
4. Enable **Realtime Database** in the Firebase console
5. Set database rules for development:

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

### 3. Build & Run

1. Open `Jukebox.xcodeproj` in Xcode 15+
2. Wait for Swift Package Manager to resolve `firebase-ios-sdk`
3. Select your team under Signing & Capabilities
4. Build and run on a real device (Spotify playback requires a device)

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Spotify Premium account (for playback control)
- Firebase project with Realtime Database enabled

## Integration

This app is designed as a self-contained module that can be integrated into a larger app. It does not include authentication — the host app is expected to handle that. Key integration points:

- `ContentView` is the root view — embed it wherever needed
- `SpotifyService`, `JukeboxService`, and `ChatService` are independent `ObservableObject`s
- Chat uses random session names (no user identity required)
- All Firebase paths are under the root — namespace them if integrating alongside other data

## Notes

- Chat messages auto-expire after 5 minutes and are not persisted
- The jukebox queue and now-playing state persist in Firebase across sessions
- Background audio is enabled via the `UIBackgroundModes` audio capability
- Spotify PKCE flow is used (no client secret needed — safe for mobile)
