import Foundation
import CommonCrypto

/// Bridging header replacement — CommonCrypto functions for PKCE
/// Since we can't use a bridging header in SwiftUI-only projects,
/// we provide these helpers.

func CC_SHA256(_ data: UnsafeRawPointer?, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
    return CommonCrypto.CC_SHA256(data, len, md)
}
