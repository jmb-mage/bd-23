import Foundation

/// Manages loading, discovery, and cycling through Mood JSON color/wave configurations.
public final class MoodManager: @unchecked Sendable {
    public private(set) var moods: [MoodModel] = []
    public private(set) var currentIndex: Int = 0

    public init(customMoods: [MoodModel]? = nil) {
        if let custom = customMoods, !custom.isEmpty {
            self.moods = custom
        } else {
            self.moods = loadAvailableMoods()
        }
    }

    public var currentMood: MoodModel {
        guard !moods.isEmpty else {
            return MoodManager.createFallbackMood()
        }
        return moods[currentIndex % moods.count]
    }

    public var count: Int {
        moods.count
    }

    @discardableResult
    public func next() -> MoodModel {
        guard !moods.isEmpty else { return currentMood }
        currentIndex = (currentIndex + 1) % moods.count
        return currentMood
    }

    @discardableResult
    public func previous() -> MoodModel {
        guard !moods.isEmpty else { return currentMood }
        currentIndex = (currentIndex - 1 + moods.count) % moods.count
        return currentMood
    }

    @discardableResult
    public func select(index: Int) -> MoodModel {
        guard !moods.isEmpty else { return currentMood }
        currentIndex = abs(index) % moods.count
        return currentMood
    }

    // MARK: - File Loading

    private func loadAvailableMoods() -> [MoodModel] {
        var loaded: [MoodModel] = []
        let decoder = JSONDecoder()

        // 1. Check Bundle resources if available
        #if SWIFT_PACKAGE
        if let urls = Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Resources/Moods") ??
                      Bundle.module.urls(forResourcesWithExtension: "json", subdirectory: "Moods") {
            for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                if let data = try? Data(contentsOf: url),
                   let mood = try? decoder.decode(MoodModel.self, from: data) {
                    loaded.append(mood)
                }
            }
        }
        #endif

        // 2. Check local directories
        if loaded.isEmpty {
            let candidatePaths = [
                "Sources/Resources/Moods",
                "Resources/Moods",
                "./Moods"
            ]
            let fm = FileManager.default
            for path in candidatePaths {
                guard let files = try? fm.contentsOfDirectory(atPath: path) else { continue }
                let jsonFiles = files.filter { $0.hasSuffix(".json") }.sorted()
                for file in jsonFiles {
                    let fileURL = URL(fileURLWithPath: path).appendingPathComponent(file)
                    if let data = try? Data(contentsOf: fileURL),
                       let mood = try? decoder.decode(MoodModel.self, from: data) {
                        loaded.append(mood)
                    }
                }
                if !loaded.isEmpty { break }
            }
        }

        // 3. Fallback built-in moods if no files found
        if loaded.isEmpty {
            loaded = MoodManager.builtInMoods()
        }

        return loaded
    }

    public static func createFallbackMood() -> MoodModel {
        MoodModel(
            id: "fallback_cyberpunk",
            name: "Cyberpunk Pulse",
            paletteHex: ["#FF007F", "#7928CA", "#0070F3", "#00DFD8"],
            pattern: PatternConfig(type: .insideOut, wavelength: 260.0, speed: 1.2, cycleDuration: 4.0)
        )
    }

    public static func builtInMoods() -> [MoodModel] {
        return [
            MoodModel(
                id: "01_cyberpunk_neon",
                name: "Cyberpunk Neon",
                description: "High-octane neon pulse expanding radially from the core (Inside-Out)",
                paletteHex: [
                    "#FF007F", // Electric Magenta
                    "#7928CA", // Neon Violet
                    "#0070F3", // Cyan Blue
                    "#00DFD8", // Aquamarine
                    "#FF007F"  // Loop
                ],
                pattern: PatternConfig(
                    type: .insideOut,
                    wavelength: 220.0,
                    speed: 1.3,
                    cycleDuration: 3.5
                ),
                visuals: VisualAccentConfig(minAlpha: 0.45, maxAlpha: 1.0, scalePulse: 0.08)
            ),
            MoodModel(
                id: "02_aurora_borealis",
                name: "Aurora Borealis",
                description: "Mystic curtain of emerald, violet, and sky blue cascading Top-Down",
                paletteHex: [
                    "#05FFA1", // Emerald Neon
                    "#00B4D8", // Electric Blue
                    "#7209B7", // Deep Violet
                    "#F72585", // Pink Glow
                    "#05FFA1"
                ],
                pattern: PatternConfig(
                    type: .topDown,
                    wavelength: 280.0,
                    speed: 0.9,
                    cycleDuration: 4.5
                ),
                visuals: VisualAccentConfig(minAlpha: 0.4, maxAlpha: 1.0, scalePulse: 0.04)
            ),
            MoodModel(
                id: "03_solar_flare",
                name: "Solar Flare",
                description: "Radiant wave of incandescent gold, ember crimson, and molten lava (Left-to-Right)",
                paletteHex: [
                    "#FF0000", // Crimson
                    "#FF4500", // OrangeRed
                    "#FF8C00", // DarkOrange
                    "#FFD700", // Electric Gold
                    "#FFFFFF", // White Heat
                    "#FF0000"
                ],
                pattern: PatternConfig(
                    type: .leftToRight,
                    wavelength: 320.0,
                    speed: 1.1,
                    cycleDuration: 3.8
                ),
                visuals: VisualAccentConfig(minAlpha: 0.5, maxAlpha: 1.0, scalePulse: 0.07)
            ),
            MoodModel(
                id: "04_vortex_spiral",
                name: "Vortex Spiral",
                description: "Archimedean cosmic spiral vortex swirling in indigo, magenta, and teal",
                paletteHex: [
                    "#3A0CA3", // Indigo
                    "#4361EE", // Vivid Blue
                    "#4CC9F0", // Teal Blue
                    "#F72585", // Hot Pink
                    "#7209B7", // Purple
                    "#3A0CA3"
                ],
                pattern: PatternConfig(
                    type: .spiral,
                    wavelength: 240.0,
                    speed: 1.4,
                    cycleDuration: 4.2
                ),
                visuals: VisualAccentConfig(minAlpha: 0.4, maxAlpha: 1.0, scalePulse: 0.06)
            ),
            MoodModel(
                id: "05_deep_ocean_abyss",
                name: "Bioluminescent Abyss",
                description: "Deep sea hydrothermal flow ascending Bottom-Up with glowing cyan and deep navy",
                paletteHex: [
                    "#03045E", // Midnight Navy
                    "#0077B6", // Ocean Blue
                    "#00B4D8", // Cyan
                    "#90E0EF", // Ice Blue
                    "#CAF0F8", // Foam
                    "#03045E"
                ],
                pattern: PatternConfig(
                    type: .bottomUp,
                    wavelength: 300.0,
                    speed: 0.85,
                    cycleDuration: 5.0
                ),
                visuals: VisualAccentConfig(minAlpha: 0.35, maxAlpha: 1.0, scalePulse: 0.05)
            ),
            MoodModel(
                id: "06_diagonal_prism",
                name: "Prismatic Horizon",
                description: "45-degree diagonal refraction wave of vibrant spectral gradients",
                paletteHex: [
                    "#E63946", // Coral Red
                    "#F1FAEE", // Pale Prism
                    "#A8DADC", // Soft Cyan
                    "#457B9D", // Steel Blue
                    "#1D3557", // Deep Prussian
                    "#E63946"
                ],
                pattern: PatternConfig(
                    type: .diagonal,
                    wavelength: 260.0,
                    speed: 1.0,
                    cycleDuration: 4.0,
                    angleDegrees: 45.0
                ),
                visuals: VisualAccentConfig(minAlpha: 0.5, maxAlpha: 1.0, scalePulse: 0.05)
            ),
            MoodModel(
                id: "07_monochrome_pulse",
                name: "Monochrome Minimalist",
                description: "High-contrast rhythmic radial pulse with silver, pure white, and charcoal",
                paletteHex: [
                    "#111111",
                    "#444444",
                    "#888888",
                    "#CCCCCC",
                    "#FFFFFF",
                    "#111111"
                ],
                pattern: PatternConfig(
                    type: .radialPulse,
                    wavelength: 200.0,
                    speed: 1.5,
                    cycleDuration: 2.8
                ),
                visuals: VisualAccentConfig(minAlpha: 0.3, maxAlpha: 1.0, scalePulse: 0.12)
            ),
            MoodModel(
                id: "08_harmonic_matrix",
                name: "Harmonic Interference",
                description: "2D spatial harmonic wave interference pattern in emerald and neon lime",
                paletteHex: [
                    "#003B00",
                    "#008F11",
                    "#00FF66",
                    "#CCFF00",
                    "#00FF66",
                    "#003B00"
                ],
                pattern: PatternConfig(
                    type: .harmonicWave,
                    wavelength: 180.0,
                    speed: 1.2,
                    cycleDuration: 3.2
                ),
                visuals: VisualAccentConfig(minAlpha: 0.4, maxAlpha: 1.0, scalePulse: 0.06)
            )
        ]
    }
}
