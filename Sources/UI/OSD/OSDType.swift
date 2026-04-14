import SwiftUI

enum OSDType {
    case brightness
    case volume

    var icon: String {
        switch self {
        case .brightness: "sun.max"
        case .volume: "speaker.wave.2"
        }
    }
}
