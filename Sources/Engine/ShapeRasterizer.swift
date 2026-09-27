import Foundation
import CoreGraphics

/// Descriptor for a discrete rasterized pixel node.
public struct RasterNodeData: Sendable, Hashable {
    public let id: Int
    public let gridX: Int
    public let gridY: Int
    public let position: CGPoint
    public let size: CGSize
    public let normalizedPos: CGPoint
    public let distanceFromCenter: CGFloat
    public let polarAngle: CGFloat

    public init(
        id: Int,
        gridX: Int,
        gridY: Int,
        position: CGPoint,
        size: CGSize,
        normalizedPos: CGPoint,
        distanceFromCenter: CGFloat,
        polarAngle: CGFloat
    ) {
        self.id = id
        self.gridX = gridX
        self.gridY = gridY
        self.position = position
        self.size = size
        self.normalizedPos = normalizedPos
        self.distanceFromCenter = distanceFromCenter
        self.polarAngle = polarAngle
    }
}

/// Grid coordinate hashable key for deduplication.
private struct GridKey: Hashable {
    let x: Int
    let y: Int
}

/// High-performance geometric rasterizer converting vector shapes into discrete square pixel nodes.
public final class ShapeRasterizer: Sendable {

    public init() {}

    /// Rasterizes all shapes in a MapModel into an array of RasterNodeData.
    public func rasterize(map: MapModel, nodeSizeOverride: CGFloat? = nil) -> [RasterNodeData] {
        let nodeSize = max(nodeSizeOverride ?? map.nodeSize, 2.0)
        let spacing = max(map.spacing ?? 1.0, 0.0)
        let step = nodeSize + spacing
        let canvas = map.canvas ?? CanvasSize(width: 1024, height: 768)

        var visitedCells = Set<GridKey>()
        var cellCandidates: [(key: GridKey, pos: CGPoint)] = []

        // Iterate through each shape and determine candidate cells
        for shape in map.shapes {
            guard let geometry = shape.resolveGeometry() else { continue }
            let bounds = boundingBox(for: geometry)

            let minCol = Int(floor(bounds.minX / step))
            let maxCol = Int(ceil(bounds.maxX / step))
            let minRow = Int(floor(bounds.minY / step))
            let maxRow = Int(ceil(bounds.maxY / step))

            for col in minCol...maxCol {
                for row in minRow...maxRow {
                    let key = GridKey(x: col, y: row)
                    if visitedCells.contains(key) { continue }

                    let posX = CGFloat(col) * step + nodeSize * 0.5
                    let posY = CGFloat(row) * step + nodeSize * 0.5
                    let candidatePoint = CGPoint(x: posX, y: posY)

                    if contains(point: candidatePoint, in: geometry, margin: nodeSize * 0.4) {
                        visitedCells.insert(key)
                        cellCandidates.append((key, candidatePoint))
                    }
                }
            }
        }

        // Compute centroid of the active nodes for center-relative patterns
        let count = CGFloat(max(cellCandidates.count, 1))
        let totalX = cellCandidates.reduce(0.0) { $0 + $1.pos.x }
        let totalY = cellCandidates.reduce(0.0) { $0 + $1.pos.y }
        let centroid = cellCandidates.isEmpty
            ? CGPoint(x: canvas.width * 0.5, y: canvas.height * 0.5)
            : CGPoint(x: totalX / count, y: totalY / count)

        let canvasWidth = max(canvas.width, 1.0)
        let canvasHeight = max(canvas.height, 1.0)
        let nodeDimensions = CGSize(width: nodeSize, height: nodeSize)

        return cellCandidates.enumerated().map { index, item in
            let pos = item.pos
            let dx = pos.x - centroid.x
            let dy = pos.y - centroid.y
            let dist = sqrt(dx * dx + dy * dy)
            let angle = atan2(dy, dx)

            let normX = min(max(pos.x / canvasWidth, 0.0), 1.0)
            let normY = min(max(pos.y / canvasHeight, 0.0), 1.0)

            return RasterNodeData(
                id: index,
                gridX: item.key.x,
                gridY: item.key.y,
                position: pos,
                size: nodeDimensions,
                normalizedPos: CGPoint(x: normX, y: normY),
                distanceFromCenter: dist,
                polarAngle: angle
            )
        }
    }

    // MARK: - Point-in-Shape Intersection Tests

    private func contains(point: CGPoint, in geometry: ShapeGeometry, margin: CGFloat) -> Bool {
        switch geometry {
        case .square(let center, let size, let filled):
            let half = size * 0.5
            let dx = abs(point.x - center.x)
            let dy = abs(point.y - center.y)
            if filled {
                return dx <= half && dy <= half
            } else {
                return (dx <= half && dy <= half) && (dx >= half - margin || dy >= half - margin)
            }

        case .rectangle(let center, let width, let height, let filled):
            let halfW = width * 0.5
            let halfH = height * 0.5
            let dx = abs(point.x - center.x)
            let dy = abs(point.y - center.y)
            if filled {
                return dx <= halfW && dy <= halfH
            } else {
                return (dx <= halfW && dy <= halfH) && (dx >= halfW - margin || dy >= halfH - margin)
            }

        case .circle(let center, let radius, let filled):
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distSq = dx * dx + dy * dy
            let rSq = radius * radius
            if filled {
                return distSq <= rSq
            } else {
                let innerSq = max(radius - margin, 0) * max(radius - margin, 0)
                return distSq <= rSq && distSq >= innerSq
            }

        case .ring(let center, let innerRadius, let outerRadius):
            let dx = point.x - center.x
            let dy = point.y - center.y
            let distSq = dx * dx + dy * dy
            return distSq <= (outerRadius * outerRadius) && distSq >= (innerRadius * innerRadius)

        case .triangle(let center, let width, let height, let direction, let filled):
            let vertices = triangleVertices(center: center, width: width, height: height, direction: direction)
            let inside = pointInPolygon(point: point, vertices: vertices)
            if !filled {
                return inside && distanceToPolygonPerimeter(point: point, vertices: vertices) <= margin
            }
            return inside

        case .diamond(let center, let width, let height, let filled):
            let halfW = max(width * 0.5, 0.001)
            let halfH = max(height * 0.5, 0.001)
            let dx = abs(point.x - center.x)
            let dy = abs(point.y - center.y)
            let value = (dx / halfW) + (dy / halfH)
            if filled {
                return value <= 1.0
            } else {
                return value <= 1.0 && value >= (1.0 - (margin / min(halfW, halfH)))
            }

        case .star(let center, let points, let innerRadius, let outerRadius):
            let vertices = starVertices(center: center, points: points, innerRadius: innerRadius, outerRadius: outerRadius)
            return pointInPolygon(point: point, vertices: vertices)

        case .cross(let center, let width, let height, let thickness):
            let halfW = width * 0.5
            let halfH = height * 0.5
            let halfT = thickness * 0.5
            let dx = abs(point.x - center.x)
            let dy = abs(point.y - center.y)
            let inHorizontal = (dx <= halfW) && (dy <= halfT)
            let inVertical = (dx <= halfT) && (dy <= halfH)
            return inHorizontal || inVertical

        case .polygon(let vertices, _):
            let pts = vertices.map { CGPoint(x: $0.x, y: $0.y) }
            return pointInPolygon(point: point, vertices: pts)
        }
    }

    // MARK: - Geometry Helpers

    private func boundingBox(for geometry: ShapeGeometry) -> CGRect {
        switch geometry {
        case .square(let center, let size, _):
            return CGRect(x: center.x - size * 0.5, y: center.y - size * 0.5, width: size, height: size)
        case .rectangle(let center, let width, let height, _):
            return CGRect(x: center.x - width * 0.5, y: center.y - height * 0.5, width: width, height: height)
        case .circle(let center, let radius, _):
            return CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        case .ring(let center, _, let outerRadius):
            return CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)
        case .triangle(let center, let width, let height, _, _):
            return CGRect(x: center.x - width * 0.5, y: center.y - height * 0.5, width: width, height: height)
        case .diamond(let center, let width, let height, _):
            return CGRect(x: center.x - width * 0.5, y: center.y - height * 0.5, width: width, height: height)
        case .star(let center, _, _, let outerRadius):
            return CGRect(x: center.x - outerRadius, y: center.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)
        case .cross(let center, let width, let height, _):
            return CGRect(x: center.x - width * 0.5, y: center.y - height * 0.5, width: width, height: height)
        case .polygon(let vertices, _):
            guard let first = vertices.first else { return .zero }
            var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
            for v in vertices {
                minX = min(minX, v.x)
                maxX = max(maxX, v.x)
                minY = min(minY, v.y)
                maxY = max(maxY, v.y)
            }
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
    }

    private func triangleVertices(center: Point2D, width: CGFloat, height: CGFloat, direction: TriangleDirection) -> [CGPoint] {
        let halfW = width * 0.5
        let halfH = height * 0.5
        let cx = center.x
        let cy = center.y

        switch direction {
        case .up:
            return [
                CGPoint(x: cx, y: cy + halfH),
                CGPoint(x: cx - halfW, y: cy - halfH),
                CGPoint(x: cx + halfW, y: cy - halfH)
            ]
        case .down:
            return [
                CGPoint(x: cx, y: cy - halfH),
                CGPoint(x: cx - halfW, y: cy + halfH),
                CGPoint(x: cx + halfW, y: cy + halfH)
            ]
        case .left:
            return [
                CGPoint(x: cx - halfW, y: cy),
                CGPoint(x: cx + halfW, y: cy + halfH),
                CGPoint(x: cx + halfW, y: cy - halfH)
            ]
        case .right:
            return [
                CGPoint(x: cx + halfW, y: cy),
                CGPoint(x: cx - halfW, y: cy + halfH),
                CGPoint(x: cx - halfW, y: cy - halfH)
            ]
        }
    }

    private func starVertices(center: Point2D, points: Int, innerRadius: CGFloat, outerRadius: CGFloat) -> [CGPoint] {
        let totalCount = max(points, 3) * 2
        let angleStep = (CGFloat.pi * 2.0) / CGFloat(totalCount)
        var vertices: [CGPoint] = []

        for i in 0..<totalCount {
            let r = (i % 2 == 0) ? outerRadius : innerRadius
            let angle = CGFloat(i) * angleStep - (CGFloat.pi * 0.5)
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r
            vertices.append(CGPoint(x: x, y: y))
        }
        return vertices
    }

    /// Jordan curve ray-casting test for point in polygon
    private func pointInPolygon(point: CGPoint, vertices: [CGPoint]) -> Bool {
        guard vertices.count >= 3 else { return false }
        var inside = false
        var j = vertices.count - 1
        for i in 0..<vertices.count {
            let vi = vertices[i]
            let vj = vertices[j]
            let intersects = ((vi.y > point.y) != (vj.y > point.y)) &&
                (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x)
            if intersects {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    private func distanceToPolygonPerimeter(point: CGPoint, vertices: [CGPoint]) -> CGFloat {
        guard vertices.count >= 2 else { return .greatestFiniteMagnitude }
        var minDistance = CGFloat.greatestFiniteMagnitude
        for i in 0..<vertices.count {
            let p1 = vertices[i]
            let p2 = vertices[(i + 1) % vertices.count]
            let d = distanceToSegment(point: point, a: p1, b: p2)
            minDistance = min(minDistance, d)
        }
        return minDistance
    }

    private func distanceToSegment(point: CGPoint, a: CGPoint, b: CGPoint) -> CGFloat {
        let l2 = (b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)
        if l2 == 0 { return sqrt((point.x - a.x) * (point.x - a.x) + (point.y - a.y) * (point.y - a.y)) }
        var t = ((point.x - a.x) * (b.x - a.x) + (point.y - a.y) * (b.y - a.y)) / l2
        t = max(0, min(1, t))
        let projX = a.x + t * (b.x - a.x)
        let projY = a.y + t * (b.y - a.y)
        let dx = point.x - projX
        let dy = point.y - projY
        return sqrt(dx * dx + dy * dy)
    }
}
