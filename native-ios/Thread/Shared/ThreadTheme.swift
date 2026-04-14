import SwiftUI

enum ThreadPalette {
    static let background = Color(red: 0.969, green: 0.957, blue: 0.937)
    static let surface = Color.white
    static let surfaceMuted = Color(red: 0.964, green: 0.945, blue: 0.914)
    static let ink = Color(red: 0.102, green: 0.090, blue: 0.078)
    static let muted = Color(red: 0.455, green: 0.420, blue: 0.364)
    static let faint = Color(red: 0.663, green: 0.612, blue: 0.541)
    static let border = Color(red: 0.894, green: 0.871, blue: 0.831)
    static let accent = Color(red: 0.180, green: 0.420, blue: 0.227)
    static let accentSoft = Color(red: 0.894, green: 0.941, blue: 0.902)
    static let failure = Color(red: 0.753, green: 0.325, blue: 0.251)
    static let failureSoft = Color(red: 0.984, green: 0.918, blue: 0.902)
    static let glow = Color(red: 0.996, green: 0.976, blue: 0.933)
}

enum ThreadFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom(displayFontName(for: weight), size: size)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(bodyFontName(for: weight), size: size)
    }

    private static func displayFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return "CormorantGaramond-Bold"
        case .semibold:
            return "CormorantGaramond-SemiBold"
        case .medium:
            return "CormorantGaramond-Medium"
        case .regular, .light, .thin, .ultraLight:
            return "CormorantGaramond-Light"
        default:
            return "CormorantGaramond-Regular"
        }
    }

    private static func bodyFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .heavy, .black, .bold:
            return "DMSans-Bold"
        case .semibold:
            return "DMSans-SemiBold"
        case .medium:
            return "DMSans-Medium"
        default:
            return "DMSans-Regular"
        }
    }
}

enum ThreadMetrics {
    static let maxContentWidth: CGFloat = 560
    static let wideContentWidth: CGFloat = 920
    static let cardCornerRadius: CGFloat = 16
    static let splitSpacing: CGFloat = 20
}

enum ThreadMotion {
    static let defaultSpring = Animation.spring(response: 0.42, dampingFraction: 0.88)
    static let quickSpring = Animation.spring(response: 0.22, dampingFraction: 0.86)
    static let ambientPulse = Animation.easeInOut(duration: 1.25).repeatForever(autoreverses: true)
    static var pageTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.992))
    }

    static var revealTransition: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
    }
}
