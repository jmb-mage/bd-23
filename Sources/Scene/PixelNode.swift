import Foundation
import SpriteKit

/// High-performance visual node wrapping an SKSpriteNode.
public final class PixelNode {
    public let data: RasterNodeData
    public let sprite: SKSpriteNode

    /// Shared 1x1 pixel texture for optimal Metal batch rendering
    private static let sharedTexture: SKTexture = {
        let size = CGSize(width: 4, height: 4)
        #if os(macOS)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return SKTexture(image: image)
        #else
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: img)
        #endif
    }()

    public init(data: RasterNodeData) {
        self.data = data
        let nodeSprite = SKSpriteNode(texture: PixelNode.sharedTexture, color: .white, size: data.size)
        nodeSprite.position = data.position
        nodeSprite.colorBlendFactor = 1.0
        nodeSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.sprite = nodeSprite
    }

    /// Updates node color and visual accents for the current frame
    public func updateVisual(color: RGBAColor, alpha: CGFloat, scale: CGFloat) {
        sprite.color = color.skColor
        sprite.alpha = alpha
        sprite.xScale = scale
        sprite.yScale = scale
    }

    /// Entrance transition animation
    public func animateIn(delay: TimeInterval, duration: TimeInterval = 0.45) {
        sprite.setScale(0.01)
        sprite.alpha = 0.0

        let waitAction = SKAction.wait(forDuration: delay)
        let scaleAction = SKAction.scale(to: 1.0, duration: duration)
        scaleAction.timingMode = .easeOut
        let fadeInAction = SKAction.fadeIn(withDuration: duration)
        let group = SKAction.group([scaleAction, fadeInAction])

        sprite.run(SKAction.sequence([waitAction, group]))
    }

    /// Exit transition animation
    public func animateOut(delay: TimeInterval, duration: TimeInterval = 0.35, completion: @escaping () -> Void) {
        let waitAction = SKAction.wait(forDuration: delay)
        let scaleAction = SKAction.scale(to: 0.01, duration: duration)
        scaleAction.timingMode = .easeIn
        let fadeOutAction = SKAction.fadeOut(withDuration: duration)
        let group = SKAction.group([scaleAction, fadeOutAction])
        let removeAction = SKAction.run(completion)

        sprite.run(SKAction.sequence([waitAction, group, removeAction]))
    }
}
