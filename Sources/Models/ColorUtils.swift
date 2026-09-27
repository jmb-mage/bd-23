import Foundation
import SpriteKit

#if os(macOS)
import AppKit
public typealias ColorType = NSColor
#else
import UIKit
public typealias ColorType = UIColor
#endif

/// Lightweight cross-platform RGBA color struct for fast vectorized math.
public struct RGBAColor: Codable, Equatable, Sendable {
    public var r: CGFloat
    public var g: CGFloat
    public var b: CGFloat
    public var a: CGFloat

    public init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1.0) {
        self.r = min(max(r, 0.0), 1.0)
        self.g = min(max(g, 0.0), 1.0)
        self.b = min(max(b, 0.0), 1.0)
        self.a = min(max(a, 0.0), 1.0)
    }

    /// Parse hex color string (e.g., "#FF5500", "#F50", "FF5500FF")
    public init?(hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }

        var rgbValue: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&rgbValue) else {
            return nil
        }

        let length = cleanHex.count
        switch length {
        case 3: // RGB (12-bit)
            self.r = CGFloat((rgbValue >> 8) & 0xF) / 15.0
            self.g = CGFloat((rgbValue >> 4) & 0xF) / 15.0
            self.b = CGFloat(rgbValue & 0xF) / 15.0
            self.a = 1.0
        case 4: // RGBA (16-bit)
            self.r = CGFloat((rgbValue >> 12) & 0xF) / 15.0
            self.g = CGFloat((rgbValue >> 8) & 0xF) / 15.0
            self.b = CGFloat((rgbValue >> 4) & 0xF) / 15.0
            self.a = CGFloat(rgbValue & 0xF) / 15.0
        case 6: // RRGGBB (24-bit)
            self.r = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
            self.g = CGFloat((rgbValue >> 8) & 0xFF) / 255.0
            self.b = CGFloat(rgbValue & 0xFF) / 255.0
            self.a = 1.0
        case 8: // RRGGBBAA (32-bit)
            self.r = CGFloat((rgbValue >> 24) & 0xFF) / 255.0
            self.g = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
            self.b = CGFloat((rgbValue >> 8) & 0xFF) / 255.0
            self.a = CGFloat(rgbValue & 0xFF) / 255.0
        default:
            return nil
        }
    }

    /// Linear interpolation between two colors
    public static func lerp(_ c1: RGBAColor, _ c2: RGBAColor, t: CGFloat) -> RGBAColor {
        let clampedT = min(max(t, 0.0), 1.0)
        return RGBAColor(
            r: c1.r + (c2.r - c1.r) * clampedT,
            g: c1.g + (c2.g - c1.g) * clampedT,
            b: c1.b + (c2.b - c1.b) * clampedT,
            a: c1.a + (c2.a - c1.a) * clampedT
        )
    }

    /// Evaluates a multi-stop color palette at a continuous parameter t in [0, 1].
    public static func samplePalette(_ palette: [RGBAColor], at t: CGFloat, closedLoop: Bool = true) -> RGBAColor {
        guard !palette.isEmpty else {
            return RGBAColor(r: 1, g: 1, b: 1, a: 1)
        }
        guard palette.count > 1 else {
            return palette[0]
        }

        // Normalize t into [0, 1)
        var normT = t.truncatingRemainder(dividingBy: 1.0)
        if normT < 0 { normT += 1.0 }

        let count = closedLoop ? palette.count : (palette.count - 1)
        let scaled = normT * CGFloat(count)
        let index = Int(scaled)
        let localT = scaled - CGFloat(index)

        let colorA = palette[index % palette.count]
        let colorB = palette[(index + 1) % palette.count]

        // Smooth cosine ease for organic color transitions
        let smoothT = (1.0 - cos(localT * .pi)) * 0.5
        return lerp(colorA, colorB, t: smoothT)
    }

    /// Convert to platform NSColor / SKColor
    public var skColor: SKColor {
        return SKColor(red: r, green: g, blue: b, alpha: a)
    }

    public static let black = RGBAColor(r: 0, g: 0, b: 0, a: 1)
    public static let white = RGBAColor(r: 1, g: 1, b: 1, a: 1)
    public static let clear = RGBAColor(r: 0, g: 0, b: 0, a: 0)
}
