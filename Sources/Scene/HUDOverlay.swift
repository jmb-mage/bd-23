import Foundation
import SpriteKit

/// Clean, translucent HUD overlay showing active Map, Mood, node metrics, and keyboard shortcuts.
public final class HUDOverlay {
    public let rootNode: SKNode

    private let backgroundNode: SKShapeNode
    private let mapTitleLabel: SKLabelNode
    private let mapDetailLabel: SKLabelNode
    private let moodTitleLabel: SKLabelNode
    private let moodDetailLabel: SKLabelNode
    private let controlsLabel: SKLabelNode
    private var isVisible: Bool = true

    public init(size: CGSize) {
        rootNode = SKNode()
        rootNode.zPosition = 1000 // Ensure overlay sits above pixel nodes

        // Semi-transparent rounded backdrop banner at top
        let bannerRect = CGRect(x: 20, y: size.height - 120, width: size.width - 40, height: 100)
        backgroundNode = SKShapeNode(rect: bannerRect, cornerRadius: 14)
        backgroundNode.fillColor = SKColor(white: 0.05, alpha: 0.78)
        backgroundNode.strokeColor = SKColor(white: 0.3, alpha: 0.6)
        backgroundNode.lineWidth = 1.0
        rootNode.addChild(backgroundNode)

        // Left Column: Map Information
        mapTitleLabel = SKLabelNode(fontNamed: "SFProText-Bold")
        mapTitleLabel.fontSize = 17
        mapTitleLabel.fontColor = .white
        mapTitleLabel.horizontalAlignmentMode = .left
        mapTitleLabel.position = CGPoint(x: 40, y: size.height - 55)
        rootNode.addChild(mapTitleLabel)

        mapDetailLabel = SKLabelNode(fontNamed: "SFProText-Regular")
        mapDetailLabel.fontSize = 12
        mapDetailLabel.fontColor = SKColor(white: 0.75, alpha: 1.0)
        mapDetailLabel.horizontalAlignmentMode = .left
        mapDetailLabel.position = CGPoint(x: 40, y: size.height - 78)
        rootNode.addChild(mapDetailLabel)

        // Middle Column: Mood Information
        moodTitleLabel = SKLabelNode(fontNamed: "SFProText-Bold")
        moodTitleLabel.fontSize = 17
        moodTitleLabel.fontColor = .white
        moodTitleLabel.horizontalAlignmentMode = .left
        moodTitleLabel.position = CGPoint(x: size.width * 0.42, y: size.height - 55)
        rootNode.addChild(moodTitleLabel)

        moodDetailLabel = SKLabelNode(fontNamed: "SFProText-Regular")
        moodDetailLabel.fontSize = 12
        moodDetailLabel.fontColor = SKColor(white: 0.75, alpha: 1.0)
        moodDetailLabel.horizontalAlignmentMode = .left
        moodDetailLabel.position = CGPoint(x: size.width * 0.42, y: size.height - 78)
        rootNode.addChild(moodDetailLabel)

        // Right Column: Keyboard Shortcuts
        controlsLabel = SKLabelNode(fontNamed: "SFProText-Semibold")
        controlsLabel.fontSize = 11
        controlsLabel.fontColor = SKColor(red: 0.3, green: 0.85, blue: 1.0, alpha: 0.95)
        controlsLabel.horizontalAlignmentMode = .right
        controlsLabel.numberOfLines = 4
        controlsLabel.text = "← / → : Change Map\n↑ / ↓ : Change Mood\n+ / - : Node Size\nSpace : Pause | H : Hide"
        controlsLabel.position = CGPoint(x: size.width - 40, y: size.height - 90)
        rootNode.addChild(controlsLabel)
    }

    /// Resize HUD elements when window or scene resizes
    public func resize(size: CGSize) {
        let bannerRect = CGRect(x: 20, y: size.height - 110, width: size.width - 40, height: 90)
        backgroundNode.path = CGPath(roundedRect: bannerRect, cornerWidth: 12, cornerHeight: 12, transform: nil)

        mapTitleLabel.position = CGPoint(x: 40, y: size.height - 50)
        mapDetailLabel.position = CGPoint(x: 40, y: size.height - 72)

        moodTitleLabel.position = CGPoint(x: size.width * 0.40, y: size.height - 50)
        moodDetailLabel.position = CGPoint(x: size.width * 0.40, y: size.height - 72)

        controlsLabel.position = CGPoint(x: size.width - 40, y: size.height - 85)
    }

    /// Update HUD content strings
    public func update(
        mapIndex: Int,
        totalMaps: Int,
        map: MapModel,
        activeNodeSize: CGFloat,
        nodeCount: Int,
        moodIndex: Int,
        totalMoods: Int,
        mood: MoodModel
    ) {
        mapTitleLabel.text = "Map [\(mapIndex + 1)/\(totalMaps)]: \(map.name)"
        let nodeSizeStr = String(format: "%.0f×%.0f px", activeNodeSize, activeNodeSize)
        mapDetailLabel.text = "Nodes: \(nodeCount) | Size: \(nodeSizeStr) | Shapes: \(map.shapes.count)"

        moodTitleLabel.text = "Mood [\(moodIndex + 1)/\(totalMoods)]: \(mood.name)"
        let patternStr = mood.pattern.type.rawValue
        moodDetailLabel.text = "Wave: \(patternStr) | Palette: \(mood.paletteHex.count) colors"
    }

    public func toggleVisibility() {
        isVisible.toggle()
        rootNode.run(isVisible ? SKAction.fadeIn(withDuration: 0.25) : SKAction.fadeOut(withDuration: 0.25))
    }
}
