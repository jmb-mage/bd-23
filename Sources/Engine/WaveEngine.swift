import Foundation
import CoreGraphics

/// Evaluates color, alpha, and scale for nodes over time based on Mood configuration and wave patterns.
public final class WaveEngine: @unchecked Sendable {

    /// Active mood configuration
    public private(set) var currentMood: MoodModel
    /// Secondary mood during cross-fade transition
    public private(set) var transitionSourceMood: MoodModel?
    /// Progress of mood transition in [0, 1]
    public private(set) var moodTransitionProgress: CGFloat = 1.0
    public var moodTransitionDuration: TimeInterval = 1.0
    private var transitionElapsed: TimeInterval = 0.0

    public init(initialMood: MoodModel) {
        self.currentMood = initialMood
    }

    /// Triggers a smooth crossfade into a new mood over a given duration.
    public func transition(to newMood: MoodModel, duration: TimeInterval = 1.0) {
        self.transitionSourceMood = self.currentMood
        self.currentMood = newMood
        self.moodTransitionDuration = max(duration, 0.1)
        self.transitionElapsed = 0.0
        self.moodTransitionProgress = 0.0
    }

    /// Advance transition timing
    public func update(deltaTime: TimeInterval) {
        if moodTransitionProgress < 1.0 {
            transitionElapsed += deltaTime
            moodTransitionProgress = min(CGFloat(transitionElapsed / moodTransitionDuration), 1.0)
            if moodTransitionProgress >= 1.0 {
                transitionSourceMood = nil
            }
        }
    }

    /// Computes the visual state (color, alpha, scaleFactor) for a node at time t.
    public func evaluateNode(
        _ node: RasterNodeData,
        time: TimeInterval,
        canvasSize: CGSize
    ) -> (color: RGBAColor, alpha: CGFloat, scale: CGFloat) {
        let (destColor, destAlpha, destScale) = evaluateMood(currentMood, for: node, time: time, canvasSize: canvasSize)

        guard let sourceMood = transitionSourceMood, moodTransitionProgress < 1.0 else {
            return (destColor, destAlpha, destScale)
        }

        let (srcColor, srcAlpha, srcScale) = evaluateMood(sourceMood, for: node, time: time, canvasSize: canvasSize)

        // Smooth cubic Hermite interpolation for transition progress
        let t = smoothStep(moodTransitionProgress)
        let blendedColor = RGBAColor.lerp(srcColor, destColor, t: t)
        let blendedAlpha = srcAlpha + (destAlpha - srcAlpha) * t
        let blendedScale = srcScale + (destScale - srcScale) * t

        return (blendedColor, blendedAlpha, blendedScale)
    }

    private func evaluateMood(
        _ mood: MoodModel,
        for node: RasterNodeData,
        time: TimeInterval,
        canvasSize: CGSize
    ) -> (color: RGBAColor, alpha: CGFloat, scale: CGFloat) {
        let pattern = mood.pattern
        let wavelength = max(pattern.wavelength ?? 250.0, 10.0)
        let speed = pattern.speed ?? 1.0
        let cycleDuration = max(pattern.cycleDuration ?? 4.0, 0.1)
        let reverseSign: CGFloat = (pattern.reverse ?? false) ? -1.0 : 1.0

        let distanceMetric = computeDistance(
            node: node,
            patternType: pattern.type,
            angleDeg: pattern.angleDegrees ?? 45.0,
            canvasSize: canvasSize
        )

        // Wave phase propagation: phi = (distance / wavelength) - (time / cycleDuration * speed)
        let spatialPhase = distanceMetric / wavelength
        let temporalPhase = CGFloat(time / cycleDuration) * speed * reverseSign
        let phase = spatialPhase - temporalPhase

        // Sample palette
        let palette = mood.resolvedColors
        let color = RGBAColor.samplePalette(palette, at: phase)

        // Visual accents
        let visuals = mood.visuals ?? VisualAccentConfig()
        let minA = visuals.minAlpha ?? 0.5
        let maxA = visuals.maxAlpha ?? 1.0
        let scalePulse = visuals.scalePulse ?? 0.05

        // Modulate alpha and scale in sync with color wave phase
        let waveSine = sin(phase * .pi * 2.0)
        let normalizedSine = (waveSine + 1.0) * 0.5 // [0, 1]

        let alpha = minA + (maxA - minA) * normalizedSine
        let scale = 1.0 + (waveSine * scalePulse)

        return (color, alpha, scale)
    }

    private func computeDistance(
        node: RasterNodeData,
        patternType: PatternType,
        angleDeg: CGFloat,
        canvasSize: CGSize
    ) -> CGFloat {
        let pos = node.position
        let maxDim = max(canvasSize.width, canvasSize.height, 1.0)

        switch patternType {
        case .leftToRight:
            return pos.x

        case .rightToLeft:
            return canvasSize.width - pos.x

        case .topDown:
            return canvasSize.height - pos.y

        case .bottomUp:
            return pos.y

        case .insideOut:
            return node.distanceFromCenter

        case .outsideIn:
            return (maxDim * 0.7) - node.distanceFromCenter

        case .diagonal:
            let rad = angleDeg * (.pi / 180.0)
            return pos.x * cos(rad) + pos.y * sin(rad)

        case .spiral:
            // Archimedean vortex wave: distance + polar angle phase
            let normalizedAngle = (node.polarAngle + .pi) / (.pi * 2.0) // [0, 1]
            let spiralPitch: CGFloat = 180.0
            return node.distanceFromCenter + (normalizedAngle * spiralPitch)

        case .checkerboard:
            let isEven = (node.gridX + node.gridY) % 2 == 0
            return isEven ? 0.0 : 120.0

        case .harmonicWave:
            let freqX = 2.0 * .pi / 200.0
            let freqY = 2.0 * .pi / 200.0
            let waveVal = sin(pos.x * freqX) * cos(pos.y * freqY)
            return waveVal * 150.0

        case .radialPulse:
            // Heartbeat pulse with localized harmonics
            return node.distanceFromCenter * 0.4
        }
    }

    private func smoothStep(_ x: CGFloat) -> CGFloat {
        let clamped = min(max(x, 0.0), 1.0)
        return clamped * clamped * (3.0 - 2.0 * clamped)
    }
}
