import Foundation
import CoreGraphics

/// 2D point supporting decoding from either `{"x": 100, "y": 200}` or `[100, 200]`.
public struct Point2D: Codable, Equatable, Sendable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            let xVal = try container.decode(Double.self, forKey: .x)
            let yVal = try container.decode(Double.self, forKey: .y)
            self.x = CGFloat(xVal)
            self.y = CGFloat(yVal)
            return
        }
        var unkeyed = try decoder.unkeyedContainer()
        let xVal = try unkeyed.decode(Double.self)
        let yVal = try unkeyed.decode(Double.self)
        self.x = CGFloat(xVal)
        self.y = CGFloat(yVal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Double(x), forKey: .x)
        try container.encode(Double(y), forKey: .y)
    }

    private enum CodingKeys: String, CodingKey {
        case x, y
    }

    public var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

/// Canvas dimensions configuration
public struct CanvasSize: Codable, Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat

    public init(width: CGFloat = 1024, height: CGFloat = 768) {
        self.width = width
        self.height = height
    }

    public var cgSize: CGSize {
        CGSize(width: width, height: height)
    }
}

/// Triangle orientation direction
public enum TriangleDirection: String, Codable, Sendable {
    case up
    case down
    case left
    case right
}

/// Represents the geometric shape kind and its specific parameters.
public enum ShapeGeometry: Codable, Equatable, Sendable {
    case square(center: Point2D, size: CGFloat, filled: Bool)
    case rectangle(center: Point2D, width: CGFloat, height: CGFloat, filled: Bool)
    case circle(center: Point2D, radius: CGFloat, filled: Bool)
    case ring(center: Point2D, innerRadius: CGFloat, outerRadius: CGFloat)
    case triangle(center: Point2D, width: CGFloat, height: CGFloat, direction: TriangleDirection, filled: Bool)
    case diamond(center: Point2D, width: CGFloat, height: CGFloat, filled: Bool)
    case star(center: Point2D, points: Int, innerRadius: CGFloat, outerRadius: CGFloat)
    case cross(center: Point2D, width: CGFloat, height: CGFloat, thickness: CGFloat)
    case polygon(vertices: [Point2D], filled: Bool)
}

/// Unified Shape definition decoded from JSON.
public struct ShapeDefinition: Codable, Equatable, Sendable {
    public var id: String?
    public var type: String
    public var center: Point2D?
    public var size: CGFloat?
    public var width: CGFloat?
    public var height: CGFloat?
    public var radius: CGFloat?
    public var innerRadius: CGFloat?
    public var outerRadius: CGFloat?
    public var direction: TriangleDirection?
    public var points: Int?
    public var thickness: CGFloat?
    public var filled: Bool?
    public var vertices: [Point2D]?

    public init(
        id: String? = nil,
        type: String,
        center: Point2D? = nil,
        size: CGFloat? = nil,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        radius: CGFloat? = nil,
        points: Int? = nil,
        innerRadius: CGFloat? = nil,
        outerRadius: CGFloat? = nil,
        direction: TriangleDirection? = nil,
        thickness: CGFloat? = nil,
        filled: Bool? = true,
        vertices: [Point2D]? = nil
    ) {
        self.id = id
        self.type = type
        self.center = center
        self.size = size
        self.width = width
        self.height = height
        self.radius = radius
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.direction = direction
        self.points = points
        self.thickness = thickness
        self.filled = filled
        self.vertices = vertices
    }

    /// Converts raw properties into strongly typed ShapeGeometry.
    public func resolveGeometry() -> ShapeGeometry? {
        let centerPoint = center ?? Point2D(x: 512, y: 384)
        let isFilled = filled ?? true

        switch type.lowercased() {
        case "square":
            let s = size ?? width ?? 100
            return .square(center: centerPoint, size: s, filled: isFilled)
        case "rectangle", "rect":
            let w = width ?? size ?? 150
            let h = height ?? size ?? 100
            return .rectangle(center: centerPoint, width: w, height: h, filled: isFilled)
        case "circle":
            let r = radius ?? ((size ?? width ?? 100) / 2.0)
            return .circle(center: centerPoint, radius: r, filled: isFilled)
        case "ring", "donut":
            let outR = outerRadius ?? radius ?? 100
            let inR = innerRadius ?? (outR * 0.5)
            return .ring(center: centerPoint, innerRadius: inR, outerRadius: outR)
        case "triangle":
            let w = width ?? size ?? 150
            let h = height ?? size ?? 150
            let dir = direction ?? .up
            return .triangle(center: centerPoint, width: w, height: h, direction: dir, filled: isFilled)
        case "diamond":
            let w = width ?? size ?? 120
            let h = height ?? size ?? 120
            return .diamond(center: centerPoint, width: w, height: h, filled: isFilled)
        case "star":
            let pts = points ?? 5
            let outR = outerRadius ?? radius ?? 100
            let inR = innerRadius ?? (outR * 0.4)
            return .star(center: centerPoint, points: pts, innerRadius: inR, outerRadius: outR)
        case "cross", "plus":
            let w = width ?? size ?? 120
            let h = height ?? size ?? 120
            let th = thickness ?? (min(w, h) * 0.3)
            return .cross(center: centerPoint, width: w, height: h, thickness: th)
        case "polygon":
            if let verts = vertices, verts.count >= 3 {
                return .polygon(vertices: verts, filled: isFilled)
            }
            return nil
        default:
            return nil
        }
    }
}

/// Root data model representing a Map configuration.
public struct MapModel: Codable, Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var description: String?
    public var canvas: CanvasSize?
    public var nodeSize: CGFloat
    public var spacing: CGFloat?
    public var shapes: [ShapeDefinition]

    public init(
        id: String,
        name: String,
        description: String? = nil,
        canvas: CanvasSize? = CanvasSize(),
        nodeSize: CGFloat = 16,
        spacing: CGFloat? = 1,
        shapes: [ShapeDefinition] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.canvas = canvas
        self.nodeSize = max(nodeSize, 2)
        self.spacing = spacing
        self.shapes = shapes
    }
}
