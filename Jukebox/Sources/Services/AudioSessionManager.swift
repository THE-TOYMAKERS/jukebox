import AVFoundation

/// Configures the audio session for background playback.
/// Call `configure()` early in the app lifecycle.
enum AudioSessionManager {

    static func configure() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true)
        } catch {
            print("AudioSession configuration error: \(error.localizedDescription)")
        }
    }
}
