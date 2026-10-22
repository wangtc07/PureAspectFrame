import CoreGraphics
import Foundation
import Testing
@testable import PureAspectFrame

struct FrameSceneTests {
    private let landscape = CGSize(width: 6000, height: 4000)

    @Test func w1UnitAndPixels() throws {
        let scene = FrameScene(document: try w1(), photoPixelSize: landscape)
        let photoHeight = 0.76 / 1.5
        #expect(abs(scene.unitCanvas.width - 1) < 1e-6)
        #expect(abs(scene.unitCanvas.height - (0.24 + photoHeight)) < 1e-6)
        #expect(abs(scene.unitDisplay.minX - 0.12) < 1e-6)
        #expect(abs(scene.unitDisplay.minY - 0.12) < 1e-6)
        #expect(abs(scene.unitDisplay.width - 0.76) < 1e-6)
        #expect(abs(scene.unitDisplay.height - photoHeight) < 1e-6)
        #expect(scene.canvasSize == PixelRect(x: 0, y: 0, width: 1920, height: 1433))
        #expect(scene.display == PixelRect(x: 230, y: 230, width: 1460, height: 973))
        #expect(scene.ringFrames.map(\.left) == [96, 230])
        #expect(scene.frostRadiusPixels == 0)

        var frosted = try w1()
        frosted.background.frostRadius = Percent(10)
        let frostedScene = FrameScene(document: frosted, photoPixelSize: landscape)
        #expect(frostedScene.frostRadiusPixels == 192)
        #expect(frostedScene.display == scene.display)
    }

    @Test func w2UnitAndPixels() throws {
        var stack = LayerStack()
        _ = try stack.addBorder(color: RGBColor(red: 0, green: 0, blue: 1), sizing: ratio(.r1x1, minimum: 5, role: .drives))
        let scene = FrameScene(document: FrameDocument(layers: stack), photoPixelSize: landscape)
        #expect(abs(scene.unitCanvas.width - 1) < 1e-6)
        #expect(abs(scene.unitCanvas.height - 1) < 1e-6)
        #expect(abs(scene.unitDisplay.minX - 0.05) < 1e-6)
        #expect(abs(scene.unitDisplay.minY - 0.05) < 1e-6)
        #expect(abs(scene.unitDisplay.width - 0.9) < 1e-6)
        #expect(abs(scene.unitDisplay.height - 0.6) < 1e-6)
        #expect(scene.canvasSize == PixelRect(x: 0, y: 0, width: 1080, height: 1080))
        #expect(scene.display == PixelRect(x: 54, y: 54, width: 972, height: 648))
        #expect(scene.ringFrames.first?.bottom == 378)
        #expect(scene.ringFrames.first?.left == 54)
        #expect(scene.ringFrames.first?.right == 54)

        let painted = try render(scene, photo: nil)
        let slack = sample(painted, x: 540, y: 1000)
        #expect(slack.0 < 5)
        #expect(slack.1 < 5)
        #expect(slack.2 > 250)
    }

    @Test func w3DriverFollowerAndAspectChange() throws {
        var stack = LayerStack()
        let driver = try stack.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 5, role: .drives))
        let follower = try stack.addBorder(color: .black, sizing: ratio(.r1x1, minimum: 12, role: .detached))
        try stack.linkRatio(follower: follower, source: driver)
        let scene = FrameScene(document: FrameDocument(layers: stack), photoPixelSize: landscape)
        #expect(abs(scene.unitCanvas.width - 1) < 1e-6)
        #expect(abs(scene.unitCanvas.height - 1) < 1e-6)
        #expect(abs(scene.unitDisplay.minX - 0.12) < 1e-6)
        #expect(abs(scene.unitDisplay.minY - 0.12) < 1e-6)
        #expect(abs(scene.unitDisplay.width - 0.76) < 1e-6)
        #expect(abs(scene.unitDisplay.height - (0.76 / 1.5)) < 1e-6)
        #expect(scene.canvasSize == PixelRect(x: 0, y: 0, width: 1080, height: 1080))
        #expect(scene.display == PixelRect(x: 130, y: 130, width: 820, height: 547))
        #expect(scene.ringFrames[0].outer == PixelRect(x: 76, y: 76, width: 928, height: 928))
        #expect(scene.ringFrames[0].bottom == 327)
        #expect(scene.ringFrames[1].bottom == 403)
        #expect(scene.hitTest(x: 540, y: 687) == .border(driver))
        #expect(scene.hitTest(x: 540, y: 1070) == .border(follower))

        let painted = try render(scene, photo: nil)
        let inner = sample(painted, x: 540, y: 687)
        let outer = sample(painted, x: 540, y: 1070)
        #expect(inner.0 > 250 && inner.1 > 250 && inner.2 > 250)
        #expect(outer.0 < 5 && outer.1 < 5 && outer.2 < 5)

        try stack.setCanvasAspect(.r4x5, on: driver)
        let portrait = FrameScene(document: FrameDocument(layers: stack), photoPixelSize: landscape)
        #expect(portrait.canvasSize == PixelRect(x: 0, y: 0, width: 1080, height: 1350))
        #expect(abs(portrait.unitCanvas.width / portrait.unitCanvas.height - 0.8) < 1e-6)
        #expect(stack.border(follower)?.sizing.ratioSizing?.aspect == .r4x5)
    }

    @Test func w4SamplesStayPutWhenNestedRingsMove() throws {
        var stack = LayerStack()
        let red = try stack.addBorder(color: RGBColor(red: 1, green: 0, blue: 0), sizing: perSide(top: 5, bottom: 5, left: 20, right: 5))
        let blue = try stack.addBorder(color: RGBColor(red: 0, green: 0, blue: 1), sizing: perSide(top: 12, bottom: 5, left: 5, right: 5))
        let scene = FrameScene(document: FrameDocument(layers: stack), photoPixelSize: landscape, pixels: .longEdge(100))
        #expect(scene.canvasSize == PixelRect(x: 0, y: 0, width: 100, height: 67))
        #expect(scene.display == PixelRect(x: 20, y: 12, width: 75, height: 50))
        let nested = [
            (57, 9, HitTarget.border(red)),
            (57, 4, HitTarget.border(blue)),
            (17, 37, HitTarget.border(blue)),
            (10, 37, HitTarget.border(red)),
        ]
        for samplePoint in nested {
            #expect(scene.hitTest(x: samplePoint.0, y: samplePoint.1) == samplePoint.2)
        }
        #expect(scene.hitTest(x: 57, y: 65) == .border(blue))
        #expect(scene.hitTest(x: 97, y: 37) == .border(blue))

        stack.moveBorder(blue, to: 0)
        let moved = FrameScene(document: FrameDocument(layers: stack), photoPixelSize: landscape, pixels: .longEdge(100))
        #expect(moved.canvasSize == scene.canvasSize)
        #expect(moved.display == scene.display)
        for samplePoint in nested {
            #expect(moved.hitTest(x: samplePoint.0, y: samplePoint.1) == samplePoint.2)
        }
        #expect(moved.hitTest(x: 57, y: 65) == .border(red))
        #expect(moved.hitTest(x: 97, y: 37) == .border(red))
    }

    @Test func w5ClampsTheShortSideToTenPercent() throws {
        var stack = LayerStack()
        _ = try stack.addBorder(color: .white, sizing: .equal(Percent(45)))
        let scene = FrameScene(
            document: FrameDocument(layers: stack),
            photoPixelSize: CGSize(width: 4000, height: 3000)
        )
        let displayShort = min(scene.unitDisplay.width, scene.unitDisplay.height)
        let canvasShort = min(scene.unitCanvas.width, scene.unitCanvas.height)
        #expect(displayShort + 1e-6 >= 0.1 * canvasShort)
        #expect(abs(displayShort / canvasShort - 0.1) < 1e-4)
        #expect(abs(scene.allowedRange.upperBound - 43.5) < 0.1)
        #expect(scene.display.width > 0)
        #expect(scene.display.height > 0)
    }

    @Test func w8TwoPhotosShareTheDriverAndCropsStayApart() throws {
        var stack = LayerStack()
        _ = try stack.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 5, role: .drives))
        let document = FrameDocument(layers: stack)
        let wide = FrameScene(document: document, photoPixelSize: landscape)
        let tall = FrameScene(
            document: document,
            photoPixelSize: CGSize(width: 4000, height: 6000),
            crop: CropTransform(scale: 4, offsetX: 3, offsetY: -3)
        )
        let wideAgain = FrameScene(document: document, photoPixelSize: landscape)
        #expect(wide.canvasSize == PixelRect(x: 0, y: 0, width: 1080, height: 1080))
        #expect(tall.canvasSize == wide.canvasSize)
        #expect(wide.display == PixelRect(x: 54, y: 54, width: 972, height: 648))
        #expect(1080 - wide.display.maxY == 378)
        #expect(tall.display == PixelRect(x: 216, y: 54, width: 648, height: 972))
        #expect(tall.display.y == 54)
        #expect(tall.display.x == 216)
        #expect(tall.canvasSize.width - tall.display.maxX == 216)
        #expect(abs(wide.unitDisplay.minX - 0.05) < 1e-6)
        #expect(abs(wide.unitDisplay.height - 0.6) < 1e-6)
        #expect(abs(tall.unitDisplay.minX - 0.2) < 1e-6)
        #expect(abs(tall.unitDisplay.width - 0.6) < 1e-6)
        #expect(abs(tall.unitDisplay.height - 0.9) < 1e-6)
        #expect(wideAgain.display == wide.display)
        #expect(wideAgain.imageRect == wide.imageRect)
        #expect(covers(wide.imageRect, display: wide.display))
        #expect(covers(tall.imageRect, display: tall.display))
    }

    @Test func randomEqualRingsKeepEvenPixelsAndCoverTheDisplay() throws {
        var rng = SplitMix(state: 0xC0FFEE)
        let ratios = ImageRatio.allCases
        for index in 0..<1000 {
            var stack = LayerStack(photo: PhotoLayer(imageRatio: ratios[index % ratios.count]))
            let first = Double(rng.next(40))
            _ = try stack.addBorder(color: .white, sizing: .equal(Percent(first)))
            if rng.next(2) == 0 {
                _ = try stack.addBorder(color: .black, sizing: .equal(Percent(Double(rng.next(40)))))
            }
            let crop = CropTransform(
                scale: 1 + Double(rng.next(400)) / 100,
                offsetX: Double(Int(rng.next(17)) - 8),
                offsetY: Double(Int(rng.next(17)) - 8)
            )
            let scene = FrameScene(
                document: FrameDocument(layers: stack),
                photoPixelSize: CGSize(width: 200 + Int(rng.next(4800)), height: 200 + Int(rng.next(4800))),
                crop: crop
            )
            #expect(scene.display.width > 0, "index \(index)")
            #expect(scene.display.height > 0, "index \(index)")
            let left = scene.display.x
            let top = scene.display.y
            let right = scene.canvasSize.width - scene.display.maxX
            let bottom = scene.canvasSize.height - scene.display.maxY
            #expect(left == right && top == bottom && left == top, "index \(index)")
            for ring in scene.ringFrames {
                #expect(ring.left == ring.right && ring.top == ring.bottom && ring.left == ring.top, "index \(index)")
            }
            #expect(covers(scene.imageRect, display: scene.display), "index \(index)")
        }
    }

    @Test func w1PainterColorsAtScaleOne() throws {
        let scene = FrameScene(document: try w1(), photoPixelSize: landscape)
        let painted = try render(scene, photo: solid(red: 255, green: 0, blue: 0))
        #expect(sample(painted, x: 180, y: 700) == (255, 255, 255, 255))
        #expect(sample(painted, x: 80, y: 700) == (0, 0, 0, 255))
        let centerX = scene.display.x + scene.display.width / 2
        let centerY = scene.display.y + scene.display.height / 2
        #expect(sample(painted, x: centerX, y: centerY) == (255, 0, 0, 255))

        var translucent = LayerStack()
        _ = try translucent.addBorder(color: .white, sizing: .equal(Percent(5)))
        _ = try translucent.addBorder(color: .black, opacity: 0.5, sizing: .equal(Percent(12)))
        let grayScene = FrameScene(document: FrameDocument(layers: translucent), photoPixelSize: landscape)
        let gray = sample(try render(grayScene, photo: nil), x: 80, y: 700)
        #expect(abs(Int(gray.0) - 128) <= 2)
        #expect(abs(Int(gray.1) - 128) <= 2)
        #expect(abs(Int(gray.2) - 128) <= 2)
        #expect(gray.3 == 255)

        var asymmetric = LayerStack()
        _ = try asymmetric.addBorder(
            color: .black,
            sizing: perSide(top: 20, bottom: 0, left: 0, right: 0)
        )
        let oriented = FrameScene(
            document: FrameDocument(layers: asymmetric),
            photoPixelSize: landscape,
            pixels: .longEdge(100)
        )
        let orientedImage = try render(oriented, photo: solid(red: 255, green: 0, blue: 0))
        #expect(sample(orientedImage, x: 50, y: 2) == (0, 0, 0, 255))
        #expect(sample(orientedImage, x: 50, y: oriented.display.y + 4).0 == 255)
    }

    @Test func w7InfoBarsAndShortEdgeType() throws {
        var document = try w1()
        document.layers.setInfo(
            InfoBar(spacing: Percent(0), regions: [
                InfoRegion(alignment: .leading, bricks: [.fixedText("近")]),
            ]),
            at: .photoBottom
        )
        document.layers.setInfo(
            InfoBar(spacing: Percent(2), regions: [
                InfoRegion(alignment: .leading, bricks: [.fixedText("W7")]),
            ]),
            at: .frameBottom
        )
        let scene = FrameScene(document: document, photoPixelSize: landscape)
        let photoBar = try #require(scene.infoFrames.first { $0.slot == .photoBottom })
        let frameBar = try #require(scene.infoFrames.first { $0.slot == .frameBottom })
        #expect(photoBar.barTop == scene.display.maxY)
        #expect(photoBar.barTop == 1203)
        #expect(frameBar.barBottom == 1395)
        let x = Int(frameBar.textRect.midX)
        let y = Int(frameBar.textRect.midY)
        #expect(frameBar.textRect.contains(CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)))
        #expect(scene.hitTest(x: x, y: y) == .info(.frameBottom))

        let narrow = try squareInfoScene(longEdge: 1080)
        let wide = try squareInfoScene(longEdge: 4320)
        let narrowTop = try #require(narrow.infoFrames.first { $0.slot == .photoTop })
        let wideTop = try #require(wide.infoFrames.first { $0.slot == .photoTop })
        let narrowLeft = try #require(narrow.infoFrames.first { $0.slot == .photoLeft })
        #expect(abs(narrowTop.placedSize.height / 1080 - 0.03) < 1e-9)
        #expect(abs(wideTop.placedSize.height / 4320 - 0.03) < 1e-9)
        #expect(abs(wideTop.placedSize.width / 4 - narrowTop.placedSize.width) < 1)
        #expect(abs(narrowLeft.placedSize.width - narrowTop.placedSize.height) < 0.01)
        #expect(abs(narrowLeft.placedSize.height - narrowTop.placedSize.width) < 0.01)

        let shrunk = try #require(narrow.infoFrames.first { $0.slot == .frameTop })
        let natural = 10 * 0.5 * 1080.0
        #expect(abs(shrunk.unrotatedSize.width / natural - 0.35) < 1e-9)

        var signed = FrameDocument(signatureText: "Hi")
        signed.layers.photo = PhotoLayer()
        signed.layers.setInfo(InfoBar(
            spacing: Percent(0),
            regions: [InfoRegion(alignment: .leading, bricks: [.signature, .watermark])],
            fontScale: 0.03
        ), at: .photoTop)
        var literal = signed
        literal.signatureText = ""
        literal.layers.setInfo(InfoBar(
            spacing: Percent(0),
            regions: [InfoRegion(alignment: .leading, bricks: [.fixedText("Hey")])],
            fontScale: 0.03
        ), at: .photoTop)
        let signedScene = FrameScene(document: signed, photoPixelSize: CGSize(width: 1000, height: 1000))
        let literalScene = FrameScene(document: literal, photoPixelSize: CGSize(width: 1000, height: 1000))
        #expect(signedScene.infoFrames[0].unrotatedSize == literalScene.infoFrames[0].unrotatedSize)
    }

    @Test func customGapEntersTheFileAndTheGuideStaysOnStage() throws {
        var custom = LayerStack()
        custom.setSplit(SplitLayer(count: 2, gap: .custom(Percent(1))))
        let scene = FrameScene(
            document: FrameDocument(layers: custom, background: BackgroundSpec(color: RGBColor(red: 1, green: 0, blue: 0))),
            photoPixelSize: landscape,
            pixels: .longEdge(3240)
        )
        #expect(scene.fileGap == 32)
        #expect(scene.guideXs == scene.slices.dropFirst().map(\.x))
        #expect(scene.guideXs == [1636])

        let exported = try render(scene, photo: nil, drawGuides: false)
        let staged = try render(scene, photo: nil, drawGuides: true)
        let seam = sample(exported, x: 1635, y: 20)
        let guide = sample(staged, x: 1635, y: 20)
        #expect(seam.1 < 5 && seam.2 < 5)
        #expect(guide == (0, 255, 255, 255))

        var platform = LayerStack()
        platform.setSplit(SplitLayer(count: 2, gap: .platform(.instagram)))
        let platformScene = FrameScene(
            document: FrameDocument(layers: platform),
            photoPixelSize: landscape,
            pixels: .longEdge(3240)
        )
        #expect(platformScene.fileGap == 0)
        #expect(platformScene.guideXs == platformScene.slices.dropFirst().map(\.x))
        let platformExport = try render(platformScene, photo: nil, drawGuides: false)
        let boundary = platformScene.guideXs[0]
        let pixel = sample(platformExport, x: boundary - 1, y: 20)
        #expect(!(pixel.0 < 5 && pixel.1 > 250 && pixel.2 > 250))
    }

    private func w1() throws -> FrameDocument {
        var stack = LayerStack()
        _ = try stack.addBorder(color: .white, sizing: .equal(Percent(5)))
        _ = try stack.addBorder(color: .black, sizing: .equal(Percent(12)))
        return FrameDocument(layers: stack)
    }

    private func squareInfoScene(longEdge: Int) throws -> FrameScene {
        var stack = LayerStack(photo: PhotoLayer())
        _ = try stack.addBorder(color: .white, sizing: ratio(.r1x1, minimum: 0, role: .drives))
        stack.setInfo(InfoBar(
            spacing: Percent(0),
            regions: [InfoRegion(alignment: .leading, bricks: [.fixedText("ABCD")])],
            fontScale: 0.03
        ), at: .photoTop)
        stack.setInfo(InfoBar(
            spacing: Percent(0),
            regions: [InfoRegion(alignment: .leading, bricks: [.fixedText("ABCD")])],
            fontScale: 0.03
        ), at: .photoLeft)
        stack.setInfo(InfoBar(
            spacing: Percent(0),
            regions: [InfoRegion(alignment: .leading, bricks: [.fixedText(String(repeating: "M", count: 10))])],
            fontScale: 1
        ), at: .frameTop)
        return FrameScene(
            document: FrameDocument(layers: stack),
            photoPixelSize: CGSize(width: 1000, height: 1000),
            pixels: .longEdge(longEdge)
        )
    }
}

private struct SplitMix {
    var state: UInt64

    mutating func next(_ bound: UInt64) -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return (state >> 33) % bound
    }
}

private func ratio(_ aspect: CanvasAspect, minimum: Double, role: RatioRole) -> BorderSizing {
    let edge = Percent(minimum)
    return .ratio(RatioSizing(
        aspect: aspect,
        minimum: EdgeValues(top: edge, bottom: edge, left: edge, right: edge),
        role: role
    ))
}

private func perSide(top: Double, bottom: Double, left: Double, right: Double) -> BorderSizing {
    .perSide(EdgeValues(top: Percent(top), bottom: Percent(bottom), left: Percent(left), right: Percent(right)))
}

private func covers(_ image: CGRect, display: PixelRect) -> Bool {
    image.minX <= CGFloat(display.x) + 0.01
        && image.minY <= CGFloat(display.y) + 0.01
        && image.maxX >= CGFloat(display.maxX) - 0.01
        && image.maxY >= CGFloat(display.maxY) - 0.01
}

private func render(_ scene: FrameScene, photo: CGImage?, drawGuides: Bool = false) throws -> CGContext {
    let width = scene.canvasSize.width
    let height = scene.canvasSize.height
    let context = try #require(CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ))
    FramePainter.paint(scene: scene, photo: photo, into: context, scale: 1, drawGuides: drawGuides)
    return context
}

private func sample(_ context: CGContext, x: Int, y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
    let bytesPerRow = context.bytesPerRow
    let row = y
    let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
    let offset = row * bytesPerRow + x * 4
    return (pixels[offset], pixels[offset + 1], pixels[offset + 2], pixels[offset + 3])
}

private func solid(red: UInt8, green: UInt8, blue: UInt8) -> CGImage {
    let context = CGContext(
        data: nil,
        width: 4,
        height: 4,
        bitsPerComponent: 8,
        bytesPerRow: 16,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor(
        srgbRed: CGFloat(red) / 255,
        green: CGFloat(green) / 255,
        blue: CGFloat(blue) / 255,
        alpha: 1
    ))
    context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    return context.makeImage()!
}
