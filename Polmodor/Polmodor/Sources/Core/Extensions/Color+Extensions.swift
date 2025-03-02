import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

extension Color {
    static let timerBackground = Color("TimerBackground")
    static let taskBackground = Color("TaskBackground")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        #if os(iOS)
            let uic = UIColor(self)
            guard let components = uic.cgColor.components, components.count >= 3 else {
                return nil
            }
            let r = Float(components[0])
            let g = Float(components[1])
            let b = Float(components[2])
            var a = Float(1.0)

            if components.count >= 4 {
                a = Float(components[3])
            }

            if a != Float(1.0) {
                return String(
                    format: "#%02lX%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255),
                    lroundf(a * 255))
            } else {
                return String(
                    format: "#%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255))
            }
        #elseif os(macOS)
            let nsColor = NSColor(self)
            guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
                return nil
            }
            let r = Float(rgbColor.redComponent)
            let g = Float(rgbColor.greenComponent)
            let b = Float(rgbColor.blueComponent)
            let a = Float(rgbColor.alphaComponent)

            if a != Float(1.0) {
                return String(
                    format: "#%02lX%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255),
                    lroundf(a * 255))
            } else {
                return String(
                    format: "#%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255))
            }
        #else
            return nil
        #endif
    }

    // Additional color-related extensions can be added here

    // Return hex string representation of the color
    var hexString: String? {
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255))
    }
}

// Timer Feature Color Extensions
extension Color {
    static let timerColors = TimerColors()

    struct TimerColors {
        // Work Colors
        let workStart = Color(hex: "FF6B6B")
        let workEnd = Color(hex: "F03E3E")

        // Short Break Colors
        let shortBreakStart = Color(hex: "4ECDC4")
        let shortBreakEnd = Color(hex: "26A69A")

        // Long Break Colors
        let longBreakStart = Color(hex: "45B7D1")
        let longBreakEnd = Color(hex: "2196F3")
    }
}
