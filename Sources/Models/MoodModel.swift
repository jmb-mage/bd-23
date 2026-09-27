import Foundation
import CoreGraphics

/// Wave animation pattern types.
public enum PatternType: String, Codable, CaseIterable, Sendable {
    case topDown = "topDown"
    case bottomUp = "bottomUp"
    case leftToRight = "leftToRight"
    case rightToLeft = "rightToLeft"
    case insideOut = "insideOut"
    case outsideIn = "outsideIn"
    case diagonal = "diagonal"
    case spiral = "spiral"
    case checkerboard = "checkerboard"
    case harmonicWave = "harmonicWave"
    case radialPulse = "radialPulse"
}

/// Pattern animation configuration
public struct PatternConfig: Codable, Equatable, Sendable {
    public var type: PatternType
    public var wavelength: CGFloat?
    public var speed: CGFloat?
    public var cycleDuration: CGFloat?
    public var angleDegrees: CGFloat?
    public var reverse: Bool?

    public init(
        type: PatternType = .insideOut,
        wavelength: CGFloat? = 250.0,
        speed: CGFloat? = 1.0,
        cycleDuration: CGFloat? = 4.0,
        angleDegrees: CGFloat? = 45.0,
        reverse: Bool? = false
    ) {
        self.type = type
        self.wavelength = wavelength
        self.speed = speed
        self.cycleDuration = cycleDuration
        self.angleDegrees = angleDegrees
        self.reverse = reverse
    }
}

/// Visual accents configuration (alpha modulation, pulsing scale)
public struct VisualAccentConfig: Codable, Equatable, Sendable {
    public var minAlpha: CGFloat?
    public var maxAlpha: CGFloat?
    public var scalePulse: CGFloat?
    public var glowIntensity: CGFloat?

    public init(
        minAlpha: CGFloat? = 0.5,
        maxAlpha: CGFloat? = 1.0,
        scalePulse: CGFloat? = 0.05,
        glowIntensity: CGFloat? = 0.0
    ) {
        self.minAlpha = minAlpha
        self.maxAlpha = maxAlpha
        self.scalePulse = scalePulse
        self.glowIntensity = glowIntensity
    }
}

/// Root data model representing a Mood color animation configuration.
public struct MoodModel: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var description: String?
    public var paletteHex: [String]
    public var pattern: PatternConfig
    public var visuals: VisualAccentConfig?

    private enum CodingKeys: String, CodingKey {
        case id, name, description, pattern, visuals
        case paletteHex = "palette"
    }

    public init(
        id: String,
        name: String,
        description: String? = nil,
        paletteHex: [String] = ["#FF007F", "#7928CA", "#0070F3"],
        pattern: PatternConfig = PatternConfig(),
        visuals: VisualAccentConfig? = VisualAccentConfig()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.paletteHex = paletteHex
        self.pattern = pattern
        self.visuals = visuals
    }

    /// Resolves hex strings into parsed RGBAColor instances.
    public var resolvedColors: [RGBAColor] {
        let parsed = paletteHex.compactMap { RGBAColor(hex: $0) }
        return parsed.isEmpty ? [RGBAColor(r: 1, g: 1, b: 1)] : parsed
    }
}
