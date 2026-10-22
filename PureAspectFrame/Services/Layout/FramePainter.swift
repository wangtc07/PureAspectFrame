import CoreGraphics
import Foundation
import SwiftUI

public nonisolated enum FramePainter {
    /// 舞台與輸出共用這一個入口。毛玻璃半徑記在場景上，這裡仍鋪實心底色。
    public static func paint(
        scene: FrameScene,
        photo: CGImage?,
        into context: CGContext,
        scale: CGFloat = 1,
        drawGuides: Bool = false
    ) {
        context.saveGState()
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        context.interpolationQuality = .none
        context.translateBy(x: 0, y: CGFloat(context.height))
        context.scaleBy(x: scale, y: -scale)

        context.setFillColor(fill(scene.backgroundColor, alpha: 1))
        context.fill(scene.canvasSize.cgRect)

        if let photo {
            context.saveGState()
            context.clip(to: scene.display.cgRect)
            context.draw(photo, in: scene.imageRect)
            context.restoreGState()
        }

        for side in Band.allCases {
            let ordered = scene.ringFrames.enumerated().sorted { lhs, rhs in
                let left = margin(lhs.element, side)
                let right = margin(rhs.element, side)
                if left != right { return left > right }
                return lhs.offset < rhs.offset
            }
            for (_, ring) in ordered {
                let band = bandRect(ring, side, display: scene.display)
                guard band.width > 0, band.height > 0 else { continue }
                context.setFillColor(fill(ring.color, alpha: ring.opacity))
                context.fill(band)
            }
        }

        for frame in scene.infoFrames {
            context.setFillColor(CGColor(srgbRed: 0.1, green: 0.1, blue: 0.1, alpha: 1))
            for rect in frame.textRects where rect.width > 0 && rect.height > 0 {
                if vertical(frame.slot) {
                    context.saveGState()
                    context.translateBy(x: rect.midX, y: rect.midY)
                    context.rotate(by: -.pi / 2)
                    context.fill(CGRect(
                        x: -rect.height / 2,
                        y: -rect.width / 2,
                        width: rect.height,
                        height: rect.width
                    ))
                    context.restoreGState()
                } else {
                    context.fill(rect)
                }
            }
        }

        if drawGuides {
            context.setFillColor(CGColor(srgbRed: 0, green: 1, blue: 1, alpha: 1))
            for guide in scene.guideXs where guide > 0 {
                context.fill(CGRect(x: guide - 1, y: 0, width: 1, height: scene.canvasSize.height))
            }
        }
        context.restoreGState()
    }

    private static func fill(_ color: RGBColor, alpha: Double) -> CGColor {
        CGColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: alpha)
    }

    private static func margin(_ ring: RingFrame, _ side: Band) -> Int {
        switch side {
        case .top: return ring.top
        case .bottom: return ring.bottom
        case .left: return ring.left
        case .right: return ring.right
        }
    }

    private static func bandRect(_ ring: RingFrame, _ side: Band, display: PixelRect) -> CGRect {
        switch side {
        case .top:
            return CGRect(x: ring.outer.x, y: ring.outer.y, width: ring.outer.width, height: ring.top)
        case .bottom:
            return CGRect(x: ring.outer.x, y: display.maxY, width: ring.outer.width, height: ring.bottom)
        case .left:
            return CGRect(x: ring.outer.x, y: display.y, width: ring.left, height: display.height)
        case .right:
            return CGRect(x: display.maxX, y: display.y, width: ring.right, height: display.height)
        }
    }

    private static func vertical(_ slot: InfoSlot) -> Bool {
        switch slot {
        case .photoLeft, .photoRight, .frameLeft, .frameRight:
            return true
        case .photoTop, .photoBottom, .frameTop, .frameBottom:
            return false
        }
    }
}

public struct FrameCanvas: View {
    public var scene: FrameScene
    public var photo: CGImage?
    public var drawGuides: Bool

    public init(scene: FrameScene, photo: CGImage? = nil, drawGuides: Bool = true) {
        self.scene = scene
        self.photo = photo
        self.drawGuides = drawGuides
    }

    public var body: some View {
        Canvas { context, _ in
            context.withCGContext { cgContext in
                FramePainter.paint(scene: scene, photo: photo, into: cgContext, drawGuides: drawGuides)
            }
        }
        .frame(width: CGFloat(scene.canvasSize.width), height: CGFloat(scene.canvasSize.height))
    }
}

private nonisolated enum Band: CaseIterable {
    case top
    case bottom
    case left
    case right
}
