import Foundation
import CoreGraphics

/// Built-in automated test suite runnable via `--test` argument.
public struct SelfTests {
    public static func run() -> Bool {
        print("==================================================")
        print("  MoodMap Automated Verification & Self-Test Suite")
        print("==================================================")
        var passed = 0
        var failed = 0

        func assertTest(_ condition: Bool, _ name: String) {
            if condition {
                print("  ✅ [PASS] \(name)")
                passed += 1
            } else {
                print("  ❌ [FAIL] \(name)")
                failed += 1
            }
        }

        // Test 1: Color Parsing
        print("\n[1] Testing Color Utilities & Hex Decoding...")
        let red = RGBAColor(hex: "#FF0000")
        assertTest(red != nil && red?.r == 1.0 && red?.g == 0.0 && red?.b == 0.0, "Hex #FF0000 correctly parses to pure red")

        let shortHex = RGBAColor(hex: "#0F0")
        assertTest(shortHex != nil && shortHex?.g == 1.0, "Hex #0F0 parses to pure green")

        let invalid = RGBAColor(hex: "invalid")
        assertTest(invalid == nil, "Invalid hex string returns nil")

        // Test 2: Color Lerp & Palette Sampling
        let black = RGBAColor(r: 0, g: 0, b: 0, a: 1)
        let white = RGBAColor(r: 1, g: 1, b: 1, a: 1)
        let mid = RGBAColor.lerp(black, white, t: 0.5)
        assertTest(abs(mid.r - 0.5) < 0.01 && abs(mid.g - 0.5) < 0.01, "Linear color interpolation calculates mid-tone")

        let palette = [
            RGBAColor(r: 1, g: 0, b: 0),
            RGBAColor(r: 0, g: 1, b: 0),
            RGBAColor(r: 0, g: 0, b: 1)
        ]
        let pSample = RGBAColor.samplePalette(palette, at: 0.0)
        assertTest(abs(pSample.r - 1.0) < 0.05, "Palette sampling at t=0 returns first color")

        // Test 3: Shape Rasterization
        print("\n[2] Testing Shape Rasterizer...")
        let rasterizer = ShapeRasterizer()

        let squareMap = MapModel(
            id: "sq_test",
            name: "Square Test",
            nodeSize: 16,
            spacing: 2,
            shapes: [
                ShapeDefinition(type: "square", center: Point2D(x: 200, y: 200), size: 64, filled: true)
            ]
        )
        let sqNodes = rasterizer.rasterize(map: squareMap)
        assertTest(!sqNodes.isEmpty && sqNodes.first?.size.width == 16, "Square rasterization generates 16x16 nodes")

        let circleMap = MapModel(
            id: "circ_test",
            name: "Circle Test",
            nodeSize: 8,
            spacing: 1,
            shapes: [
                ShapeDefinition(type: "circle", center: Point2D(x: 200, y: 200), radius: 40, filled: true)
            ]
        )
        let circNodes = rasterizer.rasterize(map: circleMap)
        assertTest(circNodes.count >= 20 && circNodes.first?.size.width == 8, "Circle rasterization produces symmetric 8x8 nodes")

        // Test 4: Variable Node Sizes (4px to 32px)
        print("\n[3] Testing Variable Node Sizing...")
        let chunkyMap = MapModel(
            id: "chunky",
            name: "Chunky 32px",
            nodeSize: 32,
            spacing: 0,
            shapes: [ShapeDefinition(type: "square", center: Point2D(x: 100, y: 100), size: 128, filled: true)]
        )
        let chunkyNodes = rasterizer.rasterize(map: chunkyMap)
        assertTest(chunkyNodes.first?.size.width == 32, "Chunky 32x32 pixel node sizing verified")

        let microMap = MapModel(
            id: "micro",
            name: "Micro 4px",
            nodeSize: 4,
            spacing: 0,
            shapes: [ShapeDefinition(type: "square", center: Point2D(x: 100, y: 100), size: 64, filled: true)]
        )
        let microNodes = rasterizer.rasterize(map: microMap)
        assertTest(microNodes.first?.size.width == 4 && microNodes.count > chunkyNodes.count, "Micro 4x4 pixel node high density verified")

        // Test dynamic node size override
        let overrideNodes = rasterizer.rasterize(map: chunkyMap, nodeSizeOverride: 8)
        assertTest(overrideNodes.first?.size.width == 8, "Dynamic node size override to 8px successfully rasterized")

        // Test 5: Wave Engine & Pattern Propagation
        print("\n[4] Testing Wave Animation Engine & Patterns...")
        let mood = MoodModel(
            id: "test_mood",
            name: "Test Mood",
            paletteHex: ["#FF0055", "#00F0FF", "#7A00FF"],
            pattern: PatternConfig(type: .insideOut, wavelength: 200.0, speed: 1.0, cycleDuration: 4.0)
        )
        let waveEngine = WaveEngine(initialMood: mood)
        guard let sampleNode = sqNodes.first else {
            print("  ❌ [FAIL] Missing raster node for wave evaluation")
            return false
        }

        let evalT0 = waveEngine.evaluateNode(sampleNode, time: 0.0, canvasSize: CGSize(width: 1024, height: 768))
        let evalT1 = waveEngine.evaluateNode(sampleNode, time: 1.0, canvasSize: CGSize(width: 1024, height: 768))
        assertTest(evalT0.color != evalT1.color, "Wave engine modulates node color dynamically across time")

        // Test 6: Mood Transition Smoothness
        let nextMood = MoodModel(
            id: "aurora",
            name: "Aurora",
            paletteHex: ["#05FFA1", "#7209B7"],
            pattern: PatternConfig(type: .topDown)
        )
        waveEngine.transition(to: nextMood, duration: 1.0)
        assertTest(waveEngine.moodTransitionProgress == 0.0, "Mood transition initializes at 0.0 progress")
        waveEngine.update(deltaTime: 0.5)
        assertTest(waveEngine.moodTransitionProgress > 0.4 && waveEngine.moodTransitionProgress < 0.6, "Mood transition smoothly advances mid-way")
        waveEngine.update(deltaTime: 0.6)
        assertTest(waveEngine.moodTransitionProgress == 1.0, "Mood transition completes at 1.0 progress")

        // Test 7: Map & Mood Managers
        print("\n[5] Testing Map & Mood File Managers...")
        let mapManager = MapManager()
        assertTest(mapManager.count >= 5, "Discovered and loaded \(mapManager.count) Map configurations")

        let initialMapId = mapManager.currentMap.id
        let nextMap = mapManager.next()
        assertTest(nextMap.id != initialMapId, "Map cycling (next) selects new map")
        let prevMap = mapManager.previous()
        assertTest(prevMap.id == initialMapId, "Map cycling (previous) restores previous map")

        let moodManager = MoodManager()
        assertTest(moodManager.count >= 6, "Discovered and loaded \(moodManager.count) Mood configurations")
        let initialMoodId = moodManager.currentMood.id
        let nextMoodObj = moodManager.next()
        assertTest(nextMoodObj.id != initialMoodId, "Mood cycling (next) selects new mood")

        print("\n==================================================")
        print("  Summary: \(passed) Passed, \(failed) Failed")
        print("==================================================")
        return failed == 0
    }
}
