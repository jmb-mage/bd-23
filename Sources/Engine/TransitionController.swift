import Foundation
import CoreGraphics
import SpriteKit

/// Orchestrates smooth visual choreography when transitioning between Maps or Moods.
public final class TransitionController {

    public init() {}

    /// Calculates staggered exit delays for existing nodes based on the current wave pattern.
    public func calculateExitDelays(
        nodes: [PixelNode],
        patternType: PatternType,
        totalDuration: TimeInterval = 0.5
    ) -> [TimeInterval] {
        guard !nodes.isEmpty else { return [] }

        var metrics: [CGFloat] = []
        metrics.reserveCapacity(nodes.count)

        for node in nodes {
            let m: CGFloat
            switch patternType {
            case .topDown:
                m = -node.data.position.y
            case .bottomUp:
                m = node.data.position.y
            case .leftToRight:
                m = node.data.position.x
            case .rightToLeft:
                m = -node.data.position.x
            case .insideOut:
                m = node.data.distanceFromCenter
            case .outsideIn:
                m = -node.data.distanceFromCenter
            case .spiral:
                m = node.data.distanceFromCenter + node.data.polarAngle * 50.0
            default:
                m = node.data.distanceFromCenter
            }
            metrics.append(m)
        }

        let minM = metrics.min() ?? 0.0
        let maxM = metrics.max() ?? 1.0
        let range = max(maxM - minM, 0.001)

        return metrics.map { m in
            let normalized = (m - minM) / range
            return TimeInterval(normalized) * totalDuration
        }
    }

    /// Calculates staggered entrance delays for newly spawned nodes.
    public func calculateEnterDelays(
        dataList: [RasterNodeData],
        patternType: PatternType,
        totalDuration: TimeInterval = 0.55
    ) -> [TimeInterval] {
        guard !dataList.isEmpty else { return [] }

        var metrics: [CGFloat] = []
        metrics.reserveCapacity(dataList.count)

        for data in dataList {
            let m: CGFloat
            switch patternType {
            case .topDown:
                m = -data.position.y
            case .bottomUp:
                m = data.position.y
            case .leftToRight:
                m = data.position.x
            case .rightToLeft:
                m = -data.position.x
            case .insideOut:
                m = data.distanceFromCenter
            case .outsideIn:
                m = -data.distanceFromCenter
            case .spiral:
                m = data.distanceFromCenter + data.polarAngle * 50.0
            default:
                m = data.distanceFromCenter
            }
            metrics.append(m)
        }

        let minM = metrics.min() ?? 0.0
        let maxM = metrics.max() ?? 1.0
        let range = max(maxM - minM, 0.001)

        return metrics.map { m in
            let normalized = (m - minM) / range
            return TimeInterval(normalized) * totalDuration
        }
    }
}
