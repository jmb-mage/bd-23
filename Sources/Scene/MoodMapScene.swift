import Foundation
import SpriteKit

#if os(macOS)
import AppKit
#endif

/// Main interactive SpriteKit scene managing node grid rendering, wave animation, and keyboard navigation.
public final class MoodMapScene: SKScene {

    // MARK: - Dependencies & Engines
    public let mapManager: MapManager
    public let moodManager: MoodManager
    public let rasterizer: ShapeRasterizer
    public let waveEngine: WaveEngine
    public let transitionController: TransitionController

    // MARK: - Scene Hierarchy
    private let worldNode: SKNode
    private let nodeContainer: SKNode
    private var hudOverlay: HUDOverlay?

    // MARK: - Active State
    private var activeNodes: [PixelNode] = []
    private var isTransitioningMap: Bool = false
    private var isAnimationPaused: Bool = false
    private var lastFrameTime: TimeInterval = 0.0
    private var simulationTime: TimeInterval = 0.0

    // MARK: - Initialization

    public init(
        size: CGSize,
        mapManager: MapManager = MapManager(),
        moodManager: MoodManager = MoodManager()
    ) {
        self.mapManager = mapManager
        self.moodManager = moodManager
        self.rasterizer = ShapeRasterizer()
        self.waveEngine = WaveEngine(initialMood: moodManager.currentMood)
        self.transitionController = TransitionController()

        self.worldNode = SKNode()
        self.nodeContainer = SKNode()

        super.init(size: size)
        self.scaleMode = .resizeFill
        self.backgroundColor = SKColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scene Lifecycle

    public override func didMove(to view: SKView) {
        super.didMove(to: view)

        // Clear existing children if re-moving
        removeAllChildren()

        // Setup hierarchy
        addChild(worldNode)
        worldNode.addChild(nodeContainer)

        // Setup HUD
        let hud = HUDOverlay(size: size)
        hudOverlay = hud
        addChild(hud.rootNode)

        // Center canvas world
        centerWorldContainer()

        // Load and spawn initial map
        loadCurrentMap(animated: false)

        // Update HUD
        updateHUD()
    }

    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        centerWorldContainer()
        hudOverlay?.resize(size: size)
    }

    private func centerWorldContainer() {
        let canvas = mapManager.currentMap.canvas ?? CanvasSize(width: 1024, height: 768)
        let offsetX = (size.width - canvas.width) * 0.5
        let offsetY = (size.height - canvas.height) * 0.5
        nodeContainer.position = CGPoint(x: offsetX, y: offsetY)
    }

    // MARK: - Map Loading & Transitions

    public func loadCurrentMap(animated: Bool = true) {
        let currentMap = mapManager.currentMap
        let nodeDataList = rasterizer.rasterize(map: currentMap)
        centerWorldContainer()

        if !animated || activeNodes.isEmpty {
            // Immediate replacement
            activeNodes.forEach { $0.sprite.removeFromParent() }
            activeNodes.removeAll(keepingCapacity: true)

            for data in nodeDataList {
                let pixel = PixelNode(data: data)
                nodeContainer.addChild(pixel.sprite)
                activeNodes.append(pixel)
            }
            updateHUD()
            return
        }

        // Staggered animated transition
        isTransitioningMap = true
        let oldNodes = activeNodes
        let exitDelays = transitionController.calculateExitDelays(
            nodes: oldNodes,
            patternType: moodManager.currentMood.pattern.type,
            totalDuration: 0.35
        )

        for (index, node) in oldNodes.enumerated() {
            let delay = (index < exitDelays.count) ? exitDelays[index] : 0.0
            node.animateOut(delay: delay, duration: 0.25) { [weak node] in
                node?.sprite.removeFromParent()
            }
        }

        // Prepare new nodes
        let newPixels = nodeDataList.map { PixelNode(data: $0) }
        let enterDelays = transitionController.calculateEnterDelays(
            dataList: nodeDataList,
            patternType: moodManager.currentMood.pattern.type,
            totalDuration: 0.45
        )

        for (index, pixel) in newPixels.enumerated() {
            nodeContainer.addChild(pixel.sprite)
            let delay = (index < enterDelays.count) ? (enterDelays[index] + 0.1) : 0.1
            pixel.animateIn(delay: delay, duration: 0.35)
        }

        self.activeNodes = newPixels

        // Reset transition lock after completion
        let resetAction = SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in
                self?.isTransitioningMap = false
            }
        ])
        run(resetAction)

        updateHUD()
    }

    // MARK: - Navigation Triggers

    public func nextMap() {
        guard !isTransitioningMap else { return }
        mapManager.next()
        loadCurrentMap(animated: true)
    }

    public func previousMap() {
        guard !isTransitioningMap else { return }
        mapManager.previous()
        loadCurrentMap(animated: true)
    }

    public func nextMood() {
        let newMood = moodManager.next()
        waveEngine.transition(to: newMood, duration: 1.0)
        updateHUD()
    }

    public func previousMood() {
        let newMood = moodManager.previous()
        waveEngine.transition(to: newMood, duration: 1.0)
        updateHUD()
    }

    public func togglePause() {
        isAnimationPaused.toggle()
    }

    public func toggleHUD() {
        hudOverlay?.toggleVisibility()
    }

    public func randomize() {
        let randMap = Int.random(in: 0..<max(mapManager.count, 1))
        let randMood = Int.random(in: 0..<max(moodManager.count, 1))
        mapManager.select(index: randMap)
        let newMood = moodManager.select(index: randMood)
        loadCurrentMap(animated: true)
        waveEngine.transition(to: newMood, duration: 1.0)
        updateHUD()
    }

    private func updateHUD() {
        let currentMap = mapManager.currentMap
        let currentMood = moodManager.currentMood
        hudOverlay?.update(
            mapIndex: mapManager.currentIndex,
            totalMaps: mapManager.count,
            map: currentMap,
            nodeCount: activeNodes.count,
            moodIndex: moodManager.currentIndex,
            totalMoods: moodManager.count,
            mood: currentMood
        )
    }

    // MARK: - Frame Render Loop

    public override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        if lastFrameTime == 0.0 {
            lastFrameTime = currentTime
            return
        }

        let deltaTime = min(currentTime - lastFrameTime, 0.1)
        lastFrameTime = currentTime

        if !isAnimationPaused {
            simulationTime += deltaTime
            waveEngine.update(deltaTime: deltaTime)
        }

        let canvas = mapManager.currentMap.canvas ?? CanvasSize(width: 1024, height: 768)
        let canvasDim = CGSize(width: canvas.width, height: canvas.height)

        // Evaluate and update all active pixel nodes
        for node in activeNodes {
            let visual = waveEngine.evaluateNode(node.data, time: simulationTime, canvasSize: canvasDim)
            node.updateVisual(color: visual.color, alpha: visual.alpha, scale: visual.scale)
        }
    }

    // MARK: - Keyboard Input Handling (macOS)

    #if os(macOS)
    public override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: // Left Arrow -> Previous Map
            previousMap()
        case 124: // Right Arrow -> Next Map
            nextMap()
        case 125: // Down Arrow -> Previous Mood
            previousMood()
        case 126: // Up Arrow -> Next Mood
            nextMood()
        case 49:  // Spacebar -> Toggle Pause
            togglePause()
        case 4:   // 'H' -> Toggle HUD
            toggleHUD()
        case 15:  // 'R' -> Randomize
            randomize()
        default:
            super.keyDown(with: event)
        }
    }
    #endif
}
