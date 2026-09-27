import Foundation

/// Manages loading, discovery, and cycling through Map JSON configurations.
public final class MapManager: @unchecked Sendable {
    public private(set) var maps: [MapModel] = []
    public private(set) var currentIndex: Int = 0

    public init(customMaps: [MapModel]? = nil) {
        if let custom = customMaps, !custom.isEmpty {
            self.maps = custom
        } else {
            self.maps = loadAvailableMaps()
        }
    }

    public var currentMap: MapModel {
        guard !maps.isEmpty else {
            return MapManager.createFallbackMap()
        }
        return maps[currentIndex % maps.count]
    }

    public var count: Int {
        maps.count
    }

    @discardableResult
    public func next() -> MapModel {
        guard !maps.isEmpty else { return currentMap }
        currentIndex = (currentIndex + 1) % maps.count
        return currentMap
    }

    @discardableResult
    public func previous() -> MapModel {
        guard !maps.isEmpty else { return currentMap }
        currentIndex = (currentIndex - 1 + maps.count) % maps.count
        return currentMap
    }

    @discardableResult
    public func select(index: Int) -> MapModel {
        guard !maps.isEmpty else { return currentMap }
        currentIndex = abs(index) % maps.count
        return currentMap
    }

    // MARK: - File Loading

    private func loadAvailableMaps() -> [MapModel] {
        var loaded: [MapModel] = []
        let decoder = JSONDecoder()

        // 1. Check Bundle resources if available
        #if SWIFT_PACKAGE
        if let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Resources/Maps") ??
                      Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Maps") {
            for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if let data = try? Data(contentsOf: url),
                   let map = try? decoder.decode(MapModel.self, from: data) {
                    loaded.append(map)
                }
            }
        }
        #endif

        // 2. Check local directories
        if loaded.isEmpty {
            let candidatePaths = [
                "Sources/Resources/Maps",
                "Resources/Maps",
                "./Maps"
            ]
            let fm = FileManager.default
            for path in candidatePaths {
                guard let files = try? fm.contentsOfDirectory(atPath: path) else { continue }
                let jsonFiles = files.filter { $0.hasSuffix(".json") }.sorted()
                for file in jsonFiles {
                    let fileURL = URL(fileURLWithPath: path).appendingPathComponent(file)
                    if let data = try? Data(contentsOf: fileURL),
                       let map = try? decoder.decode(MapModel.self, from: data) {
                        loaded.append(map)
                    }
                }
                if !loaded.isEmpty { break }
            }
        }

        // 3. Fallback built-in maps if no files found
        if loaded.isEmpty {
            loaded = MapManager.builtInMaps()
        }

        return loaded
    }

    public static func createFallbackMap() -> MapModel {
        MapModel(
            id: "default_geometric",
            name: "Geometric Symphony",
            nodeSize: 16,
            spacing: 2,
            shapes: [
                ShapeDefinition(type: "circle", center: Point2D(x: 350, y: 384), radius: 120, filled: true),
                ShapeDefinition(type: "square", center: Point2D(x: 674, y: 384), size: 180, filled: true),
                ShapeDefinition(type: "triangle", center: Point2D(x: 512, y: 384), width: 140, height: 140, direction: .up, filled: true)
            ]
        )
    }

    public static func builtInMaps() -> [MapModel] {
        return [
            MapModel(
                id: "01_geometric_quartet",
                name: "Geometric Quartet",
                description: "Square, Circle, Triangle, and Rectangle in harmony (16px nodes)",
                nodeSize: 16,
                spacing: 2,
                shapes: [
                    ShapeDefinition(type: "circle", center: Point2D(x: 280, y: 500), radius: 110, filled: true),
                    ShapeDefinition(type: "square", center: Point2D(x: 744, y: 500), size: 180, filled: true),
                    ShapeDefinition(type: "triangle", center: Point2D(x: 280, y: 220), width: 220, height: 180, direction: .up, filled: true),
                    ShapeDefinition(type: "rectangle", center: Point2D(x: 744, y: 220), width: 240, height: 120, filled: true),
                    ShapeDefinition(type: "ring", center: Point2D(x: 512, y: 360), innerRadius: 50, outerRadius: 90)
                ]
            ),
            MapModel(
                id: "02_mandala_rings",
                name: "Cosmic Mandala",
                description: "Fine-density concentric rings and nested starbursts (8px nodes)",
                nodeSize: 8,
                spacing: 1,
                shapes: [
                    ShapeDefinition(type: "circle", center: Point2D(x: 512, y: 384), radius: 240, filled: false),
                    ShapeDefinition(type: "ring", center: Point2D(x: 512, y: 384), innerRadius: 180, outerRadius: 210),
                    ShapeDefinition(type: "ring", center: Point2D(x: 512, y: 384), innerRadius: 110, outerRadius: 140),
                    ShapeDefinition(type: "star", center: Point2D(x: 512, y: 384), points: 8, innerRadius: 40, outerRadius: 90),
                    ShapeDefinition(type: "diamond", center: Point2D(x: 512, y: 384), width: 40, height: 40, filled: true)
                ]
            ),
            MapModel(
                id: "03_retro_arcade",
                name: "Retro Arcade Matrix",
                description: "Chunky 32px pixel blocks forming an arcade spacecraft motif",
                nodeSize: 32,
                spacing: 3,
                shapes: [
                    ShapeDefinition(type: "triangle", center: Point2D(x: 512, y: 480), width: 320, height: 260, direction: .up, filled: true),
                    ShapeDefinition(type: "rectangle", center: Point2D(x: 512, y: 280), width: 420, height: 96, filled: true),
                    ShapeDefinition(type: "square", center: Point2D(x: 320, y: 200), size: 96, filled: true),
                    ShapeDefinition(type: "square", center: Point2D(x: 704, y: 200), size: 96, filled: true),
                    ShapeDefinition(type: "cross", center: Point2D(x: 512, y: 384), width: 120, height: 120, thickness: 32)
                ]
            ),
            MapModel(
                id: "04_dual_pyramids",
                name: "Dual Pyramids & Portals",
                description: "Mirrored triangles with gateway diamond and perimeter rings (12px nodes)",
                nodeSize: 12,
                spacing: 2,
                shapes: [
                    ShapeDefinition(type: "triangle", center: Point2D(x: 340, y: 384), width: 280, height: 260, direction: .right, filled: true),
                    ShapeDefinition(type: "triangle", center: Point2D(x: 684, y: 384), width: 280, height: 260, direction: .left, filled: true),
                    ShapeDefinition(type: "diamond", center: Point2D(x: 512, y: 384), width: 140, height: 180, filled: true),
                    ShapeDefinition(type: "circle", center: Point2D(x: 512, y: 580), radius: 50, filled: true),
                    ShapeDefinition(type: "circle", center: Point2D(x: 512, y: 188), radius: 50, filled: true)
                ]
            ),
            MapModel(
                id: "05_micro_stellar_lattice",
                name: "Micro Stellar Lattice",
                description: "Ultra-crisp 4px micro nodes rendering precision planetary bodies",
                nodeSize: 4,
                spacing: 1,
                shapes: [
                    ShapeDefinition(type: "circle", center: Point2D(x: 512, y: 384), radius: 160, filled: true),
                    ShapeDefinition(type: "ring", center: Point2D(x: 512, y: 384), innerRadius: 210, outerRadius: 250),
                    ShapeDefinition(type: "star", center: Point2D(x: 200, y: 560), points: 5, innerRadius: 30, outerRadius: 75),
                    ShapeDefinition(type: "star", center: Point2D(x: 824, y: 560), points: 5, innerRadius: 30, outerRadius: 75),
                    ShapeDefinition(type: "diamond", center: Point2D(x: 200, y: 200), width: 110, height: 110, filled: true),
                    ShapeDefinition(type: "diamond", center: Point2D(x: 824, y: 200), width: 110, height: 110, filled: true)
                ]
            )
        ]
    }
}
