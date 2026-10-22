import CoreGraphics
import Foundation

public nonisolated enum ScenePixels: Equatable, Sendable {
    /// 橫式長邊 1920，正方形 1080，直式寬 1080。
    case sns
    case longEdge(Int)
}

public nonisolated struct PixelRect: Equatable, Sendable {
    public var x: Int
    public var y: Int
    public var width: Int
    public var height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Int { x + width }
    public var maxY: Int { y + height }

    public var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

public nonisolated struct RingFrame: Equatable, Sendable {
    public var id: BorderRing.ID
    public var outer: PixelRect
    public var color: RGBColor
    public var opacity: Double
    /// 顯示框外緣到這一圈外緣的像素距離。
    public var top: Int
    public var bottom: Int
    public var left: Int
    public var right: Int
}

public nonisolated struct InfoFrame: Equatable, Sendable {
    public var slot: InfoSlot
    public var barTop: Int?
    public var barBottom: Int?
    public var textRect: CGRect
    public var textRects: [CGRect]
    public var unrotatedSize: CGSize
    public var placedSize: CGSize
}

public nonisolated enum HitTarget: Equatable, Sendable {
    case background
    case photo
    case border(BorderRing.ID)
    case info(InfoSlot)
}

public nonisolated struct FrameScene: Equatable, Sendable {
    public var unitCanvas: CGRect
    public var unitDisplay: CGRect
    public var canvasSize: PixelRect
    public var display: PixelRect
    public var imageRect: CGRect
    public var ringFrames: [RingFrame]
    /// 邊寬百分比的允許範圍。上限是還能讓顯示框短邊達到畫布短邊 10% 的值。
    public var allowedRange: ClosedRange<Double>
    public var longEdgePixels: Int
    public var infoFrames: [InfoFrame]
    public var slices: [PixelRect]
    public var guideXs: [Int]
    public var fileGap: Int
    public var frostRadiusPixels: Int
    public var backgroundColor: RGBColor

    public init(
        document: FrameDocument,
        photoPixelSize: CGSize,
        crop: CropTransform = .identity,
        pixels: ScenePixels = .sns
    ) {
        let pixelAspect = photoPixelSize.height > 0 ? photoPixelSize.width / photoPixelSize.height : 1
        let photoAspect = document.layers.photo.imageRatio.widthOverHeight(photoAspect: pixelAspect)
        let requested = EdgeFractions.widest(of: document.layers.borders)
        let canvasAspect = document.layers.borders.first { $0.sizing.isDriving }?.sizing.ratioSizing?.aspect
        let kMax = largestUniformScale(edges: requested, photoAspect: photoAspect, canvasAspect: canvasAspect)
        let k = min(1, kMax)
        let edges = requested.scaled(by: k)
        let unit = unitLayout(edges: edges, photoAspect: photoAspect, canvasAspect: canvasAspect)
            ?? UnitLayout(canvas: CGRect(x: 0, y: 0, width: 1, height: 1), display: CGRect(x: 0, y: 0, width: 1, height: 1))

        let longEdge = resolvedLongEdge(unitCanvas: unit.canvas, pixels: pixels)
        let driven = canvasAspect != nil
        let pixel = pixelLayout(
            unit: unit,
            edges: edges,
            photoAspect: photoAspect,
            longEdge: longEdge,
            driven: driven
        )

        unitCanvas = unit.canvas
        unitDisplay = unit.display
        canvasSize = pixel.canvas
        display = pixel.display
        longEdgePixels = longEdge
        imageRect = imageRectCovering(
            display: pixel.display,
            pixelAspect: pixelAspect,
            crop: crop
        )
        ringFrames = makeRingFrames(
            borders: document.layers.borders,
            display: pixel.display,
            canvas: pixel.canvas,
            scale: k,
            longEdge: longEdge
        )
        let maxRequest = requested.maximum * 100
        if maxRequest <= 0 {
            allowedRange = 0...50
        } else {
            allowedRange = 0...min(50, kMax * maxRequest)
        }
        infoFrames = makeInfoFrames(
            document: document,
            display: pixel.display,
            canvas: pixel.canvas,
            longEdge: longEdge
        )
        let split = splitLayout(document: document, canvas: pixel.canvas, longEdge: longEdge)
        slices = split.slices
        guideXs = split.guides
        fileGap = split.gap
        if let frost = document.background.frostRadius {
            frostRadiusPixels = roundToInt(frost.value / 100 * Double(longEdge))
        } else {
            frostRadiusPixels = 0
        }
        backgroundColor = document.background.color
    }

    public func hitTest(x: Int, y: Int) -> HitTarget {
        let point = CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5)
        for frame in infoFrames where frame.textRects.contains(where: { $0.contains(point) }) {
            return .info(frame.slot)
        }
        guard x >= 0, y >= 0, x < canvasSize.width, y < canvasSize.height else {
            return .background
        }
        if x >= display.x, x < display.maxX, y >= display.y, y < display.maxY {
            return .photo
        }

        let side = bandSide(x: x, y: y)
        let indexed = ringFrames.enumerated().filter { covers($0.element, side: side, x: x, y: y) }
        guard let winner = indexed.min(by: { lhs, rhs in
            let left = margin(lhs.element, side)
            let right = margin(rhs.element, side)
            if left != right { return left < right }
            return lhs.offset > rhs.offset
        }) else {
            return .background
        }
        return .border(winner.element.id)
    }
}

private nonisolated struct EdgeFractions: Equatable {
    var top: Double
    var bottom: Double
    var left: Double
    var right: Double

    static let zero = EdgeFractions(top: 0, bottom: 0, left: 0, right: 0)

    var maximum: Double { max(top, bottom, left, right) }

    func scaled(by factor: Double) -> EdgeFractions {
        EdgeFractions(
            top: top * factor,
            bottom: bottom * factor,
            left: left * factor,
            right: right * factor
        )
    }

    static func widest(of borders: [BorderRing]) -> EdgeFractions {
        borders.reduce(into: EdgeFractions.zero) { edges, ring in
            let next = EdgeFractions(ring.sizing, scale: 1)
            edges.top = max(edges.top, next.top)
            edges.bottom = max(edges.bottom, next.bottom)
            edges.left = max(edges.left, next.left)
            edges.right = max(edges.right, next.right)
        }
    }

    init(top: Double, bottom: Double, left: Double, right: Double) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }

    init(_ sizing: BorderSizing, scale: Double) {
        let edges = sizing.convertedToPerSide()
        top = edges.top.value / 100 * scale
        bottom = edges.bottom.value / 100 * scale
        left = edges.left.value / 100 * scale
        right = edges.right.value / 100 * scale
    }
}

private nonisolated struct UnitLayout {
    var canvas: CGRect
    var display: CGRect
}

private nonisolated func widthOverHeight(_ aspect: CanvasAspect) -> Double {
    switch aspect {
    case .r1x1: return 1
    case .r4x5: return 4.0 / 5.0
    case .r3x2: return 3.0 / 2.0
    case .r9x16: return 9.0 / 16.0
    case .r3x4: return 3.0 / 4.0
    case .polaroidMini: return 54.0 / 86.0
    case .polaroidSquare: return 72.0 / 86.0
    case .polaroidWide: return 108.0 / 86.0
    }
}

private nonisolated func roundToInt(_ value: Double) -> Int {
    Int(value.rounded())
}

private nonisolated func unitLayout(
    edges: EdgeFractions,
    photoAspect: Double,
    canvasAspect: CanvasAspect?
) -> UnitLayout? {
    let aspect = photoAspect > 0 ? photoAspect : 1
    if let canvasAspect {
        let ratio = widthOverHeight(canvasAspect)
        let canvasW = ratio >= 1 ? 1 : ratio
        let canvasH = ratio >= 1 ? 1 / ratio : 1
        let innerW = canvasW - edges.left - edges.right
        let innerH = canvasH - edges.top - edges.bottom
        guard innerW > 1e-9, innerH > 1e-9 else { return nil }
        let display: CGRect
        if aspect >= innerW / innerH {
            let height = innerW / aspect
            display = CGRect(x: edges.left, y: edges.top, width: innerW, height: height)
        } else {
            let width = innerH * aspect
            let slack = innerW - width
            display = CGRect(x: edges.left + slack / 2, y: edges.top, width: width, height: innerH)
        }
        guard display.width > 0, display.height > 0 else { return nil }
        return UnitLayout(
            canvas: CGRect(x: 0, y: 0, width: canvasW, height: canvasH),
            display: display
        )
    }

    let photoW = 1 - edges.left - edges.right
    let photoH = photoW / aspect
    let canvasH = edges.top + photoH + edges.bottom
    if photoW > 1e-9, canvasH <= 1 + 1e-12 {
        return UnitLayout(
            canvas: CGRect(x: 0, y: 0, width: 1, height: canvasH),
            display: CGRect(x: edges.left, y: edges.top, width: photoW, height: photoH)
        )
    }

    let flippedH = 1 - edges.top - edges.bottom
    let flippedW = flippedH * aspect
    let canvasW = edges.left + flippedW + edges.right
    guard flippedH > 1e-9, flippedW > 1e-9, canvasW <= 1 + 1e-12 else { return nil }
    return UnitLayout(
        canvas: CGRect(x: 0, y: 0, width: canvasW, height: 1),
        display: CGRect(x: edges.left, y: edges.top, width: flippedW, height: flippedH)
    )
}

private nonisolated func largestUniformScale(
    edges: EdgeFractions,
    photoAspect: Double,
    canvasAspect: CanvasAspect?
) -> Double {
    let maxEdge = edges.maximum
    let upper = maxEdge > 0 ? 0.5 / maxEdge : 1
    func fits(_ scale: Double) -> Bool {
        guard let layout = unitLayout(
            edges: edges.scaled(by: scale),
            photoAspect: photoAspect,
            canvasAspect: canvasAspect
        ) else { return false }
        let displayShort = min(layout.display.width, layout.display.height)
        let canvasShort = min(layout.canvas.width, layout.canvas.height)
        return displayShort > 0 && displayShort + 1e-9 >= 0.1 * canvasShort
    }
    guard fits(0) else { return 0 }
    if fits(upper) { return upper }
    var lo = 0.0
    var hi = upper
    for _ in 0..<52 {
        let mid = (lo + hi) / 2
        if fits(mid) {
            lo = mid
        } else {
            hi = mid
        }
    }
    return lo
}

private nonisolated func resolvedLongEdge(unitCanvas: CGRect, pixels: ScenePixels) -> Int {
    switch pixels {
    case .longEdge(let value):
        return max(1, value)
    case .sns:
        let ratio = unitCanvas.height > 0 ? unitCanvas.width / unitCanvas.height : 1
        if abs(ratio - 1) < 1e-9 { return 1080 }
        if ratio > 1 { return 1920 }
        return max(1, roundToInt(1080 / ratio))
    }
}

private nonisolated struct PixelLayout {
    var canvas: PixelRect
    var display: PixelRect
}

private nonisolated func pixelLayout(
    unit: UnitLayout,
    edges: EdgeFractions,
    photoAspect: Double,
    longEdge: Int,
    driven: Bool
) -> PixelLayout {
    let aspect = photoAspect > 0 ? photoAspect : 1
    if driven {
        let ratio = unit.canvas.height > 0 ? unit.canvas.width / unit.canvas.height : 1
        let canvasW: Int
        let canvasH: Int
        if abs(ratio - 1) < 1e-9 {
            canvasW = longEdge
            canvasH = longEdge
        } else if ratio > 1 {
            canvasW = longEdge
            canvasH = max(1, roundToInt(Double(longEdge) / ratio))
        } else {
            canvasH = longEdge
            canvasW = max(1, roundToInt(Double(longEdge) * ratio))
        }
        let left = roundToInt(edges.left * Double(longEdge))
        let right = roundToInt(edges.right * Double(longEdge))
        let top = roundToInt(edges.top * Double(longEdge))
        let bottom = roundToInt(edges.bottom * Double(longEdge))
        let inner = PixelRect(
            x: left,
            y: top,
            width: max(0, canvasW - left - right),
            height: max(0, canvasH - top - bottom)
        )
        return PixelLayout(
            canvas: PixelRect(x: 0, y: 0, width: canvasW, height: canvasH),
            display: fit(photoAspect: aspect, in: inner)
        )
    }

    let landscape = unit.canvas.width + 1e-9 >= unit.canvas.height
    if landscape {
        let left = roundToInt(edges.left * Double(longEdge))
        let right = roundToInt(edges.right * Double(longEdge))
        let top = roundToInt(edges.top * Double(longEdge))
        let bottom = roundToInt(edges.bottom * Double(longEdge))
        let displayW = max(0, longEdge - left - right)
        let displayH = max(0, roundToInt(Double(displayW) / aspect))
        return PixelLayout(
            canvas: PixelRect(x: 0, y: 0, width: longEdge, height: top + displayH + bottom),
            display: PixelRect(x: left, y: top, width: displayW, height: displayH)
        )
    }

    let left = roundToInt(edges.left * Double(longEdge))
    let right = roundToInt(edges.right * Double(longEdge))
    let top = roundToInt(edges.top * Double(longEdge))
    let bottom = roundToInt(edges.bottom * Double(longEdge))
    let displayH = max(0, longEdge - top - bottom)
    let displayW = max(0, roundToInt(Double(displayH) * aspect))
    return PixelLayout(
        canvas: PixelRect(x: 0, y: 0, width: left + displayW + right, height: longEdge),
        display: PixelRect(x: left, y: top, width: displayW, height: displayH)
    )
}

private nonisolated func fit(photoAspect: Double, in inner: PixelRect) -> PixelRect {
    guard inner.width > 0, inner.height > 0 else {
        return PixelRect(x: inner.x, y: inner.y, width: 0, height: 0)
    }
    let innerAspect = Double(inner.width) / Double(inner.height)
    var displayW: Int
    var displayH: Int
    if photoAspect >= innerAspect {
        displayW = inner.width
        displayH = min(inner.height, max(1, roundToInt(Double(inner.width) / photoAspect)))
    } else {
        displayH = inner.height
        displayW = min(inner.width, max(1, roundToInt(Double(inner.height) * photoAspect)))
    }
    var slack = inner.width - displayW
    if slack % 2 != 0, displayW > 1 {
        displayW -= 1
        slack += 1
    }
    return PixelRect(x: inner.x + slack / 2, y: inner.y, width: displayW, height: displayH)
}

private nonisolated func imageRectCovering(display: PixelRect, pixelAspect: Double, crop: CropTransform) -> CGRect {
    let box = display.cgRect
    guard box.width > 0, box.height > 0 else { return box }
    let aspect = pixelAspect > 0 ? pixelAspect : 1
    let boxAspect = box.width / box.height
    var fill = box.size
    if aspect > boxAspect {
        fill.height = box.height
        fill.width = box.height * aspect
    } else {
        fill.width = box.width
        fill.height = box.width / aspect
    }
    fill.width = max(box.width, fill.width * crop.scale)
    fill.height = max(box.height, fill.height * crop.scale)
    var originX = box.midX - fill.width / 2 + crop.offsetX * box.width
    var originY = box.midY - fill.height / 2 + crop.offsetY * box.height
    originX = min(box.minX, max(box.maxX - fill.width, originX))
    originY = min(box.minY, max(box.maxY - fill.height, originY))
    return CGRect(origin: CGPoint(x: originX, y: originY), size: fill)
}

private nonisolated func makeRingFrames(
    borders: [BorderRing],
    display: PixelRect,
    canvas: PixelRect,
    scale: Double,
    longEdge: Int
) -> [RingFrame] {
    borders.map { ring in
        let fractions = EdgeFractions(ring.sizing, scale: scale)
        let minimum = PixelRect(
            x: roundToInt(fractions.left * Double(longEdge)),
            y: roundToInt(fractions.top * Double(longEdge)),
            width: roundToInt(fractions.right * Double(longEdge)),
            height: roundToInt(fractions.bottom * Double(longEdge))
        )
        let outer = outerRect(ring: ring, display: display, canvas: canvas, minimum: minimum)
        return RingFrame(
            id: ring.id,
            outer: outer,
            color: ring.color,
            opacity: ring.opacity,
            top: max(0, display.y - outer.y),
            bottom: max(0, outer.maxY - display.maxY),
            left: max(0, display.x - outer.x),
            right: max(0, outer.maxX - display.maxX)
        )
    }
}

/// `minimum` 借用欄位：x 左、y 上、width 右、height 下。
private nonisolated func outerRect(
    ring: BorderRing,
    display: PixelRect,
    canvas: PixelRect,
    minimum: PixelRect
) -> PixelRect {
    let left = minimum.x
    let top = minimum.y
    let right = minimum.width
    let bottom = minimum.height
    let expanded: PixelRect
    if let sizing = ring.sizing.ratioSizing, sizing.role != .detached {
        let minW = display.width + left + right
        let minH = display.height + top + bottom
        let aspect = widthOverHeight(sizing.aspect)
        var width = max(Double(minW), Double(minH) * aspect)
        var height = width / aspect
        if height < Double(minH) {
            height = Double(minH)
            width = height * aspect
        }
        var pixelW = max(minW, roundToInt(width))
        var pixelH = max(minH, roundToInt(height))
        if aspect > 0, Double(pixelW) / Double(pixelH) + 1e-9 < aspect {
            pixelW = max(pixelW, roundToInt(Double(pixelH) * aspect))
        }
        if pixelH > 0, Double(pixelW) / Double(max(pixelH, 1)) > aspect + 1e-9 {
            pixelH = max(minH, roundToInt(Double(pixelW) / aspect))
        }
        let extraW = max(0, pixelW - minW)
        expanded = PixelRect(
            x: display.x - left - extraW / 2,
            y: display.y - top,
            width: pixelW,
            height: pixelH
        )
    } else {
        expanded = PixelRect(
            x: display.x - left,
            y: display.y - top,
            width: display.width + left + right,
            height: display.height + top + bottom
        )
    }
    return clip(expanded, to: canvas)
}

private nonisolated func clip(_ rect: PixelRect, to canvas: PixelRect) -> PixelRect {
    let x0 = max(canvas.x, rect.x)
    let y0 = max(canvas.y, rect.y)
    let x1 = min(canvas.maxX, rect.maxX)
    let y1 = min(canvas.maxY, rect.maxY)
    return PixelRect(x: x0, y: y0, width: max(0, x1 - x0), height: max(0, y1 - y0))
}

private nonisolated enum BandSide {
    case top
    case bottom
    case left
    case right
}

private nonisolated func margin(_ ring: RingFrame, _ side: BandSide) -> Int {
    switch side {
    case .top: return ring.top
    case .bottom: return ring.bottom
    case .left: return ring.left
    case .right: return ring.right
    }
}

extension FrameScene {
    fileprivate nonisolated func bandSide(x: Int, y: Int) -> BandSide {
        if y < display.y { return .top }
        if y >= display.maxY { return .bottom }
        if x < display.x { return .left }
        return .right
    }

    fileprivate nonisolated func covers(_ ring: RingFrame, side: BandSide, x: Int, y: Int) -> Bool {
        switch side {
        case .top:
            return y >= ring.outer.y && y < display.y && x >= ring.outer.x && x < ring.outer.maxX
        case .bottom:
            return y >= display.maxY && y < ring.outer.maxY && x >= ring.outer.x && x < ring.outer.maxX
        case .left:
            return x >= ring.outer.x && x < display.x && y >= display.y && y < display.maxY
        case .right:
            return x >= display.maxX && x < ring.outer.maxX && y >= display.y && y < display.maxY
        }
    }
}

private nonisolated func makeInfoFrames(
    document: FrameDocument,
    display: PixelRect,
    canvas: PixelRect,
    longEdge: Int
) -> [InfoFrame] {
    let shortEdge = Double(min(canvas.width, canvas.height))
    return InfoSlot.allCases.compactMap { slot in
        guard let bar = document.layers.infos[slot] else { return nil }
        let spacing = roundToInt(bar.spacing.value / 100 * Double(longEdge))
        let vertical = isVertical(slot)
        let spanStart: Double
        let spanLength: Double
        switch slot {
        case .photoTop, .photoBottom:
            spanStart = Double(display.x)
            spanLength = Double(display.width)
        case .photoLeft, .photoRight:
            spanStart = Double(display.y)
            spanLength = Double(display.height)
        case .frameTop, .frameBottom:
            spanStart = 0
            spanLength = Double(canvas.width)
        case .frameLeft, .frameRight:
            spanStart = 0
            spanLength = Double(canvas.height)
        }
        let font = bar.fontScale * shortEdge
        let lengths = bar.regions.map { textLength($0, signature: document.signatureText) }
        let natural = Double(lengths.reduce(0, +)) * 0.5 * font
        let shrink = natural > spanLength && natural > 0 ? max(0.35, spanLength / natural) : 1
        let textHeight = font * shrink
        var rects: [CGRect] = []
        for (region, length) in zip(bar.regions, lengths) where length > 0 {
            let along = Double(length) * 0.5 * font * shrink
            let start = aligned(region.alignment, spanStart: spanStart, spanLength: spanLength, item: along)
            rects.append(textRect(
                slot: slot,
                start: start,
                along: along,
                thickness: textHeight,
                spacing: spacing,
                display: display,
                canvas: canvas
            ))
        }
        let unrotated = CGSize(width: natural * shrink, height: textHeight)
        let placed = vertical ? CGSize(width: textHeight, height: unrotated.width) : unrotated
        let union = rects.dropFirst().reduce(rects.first ?? .zero) { $0.union($1) }
        return InfoFrame(
            slot: slot,
            barTop: barEdgeTop(slot, spacing: spacing, display: display, canvas: canvas),
            barBottom: barEdgeBottom(slot, spacing: spacing, display: display, canvas: canvas),
            textRect: rects.isEmpty ? .zero : union,
            textRects: rects,
            unrotatedSize: unrotated,
            placedSize: placed
        )
    }
}

private nonisolated func isVertical(_ slot: InfoSlot) -> Bool {
    switch slot {
    case .photoLeft, .photoRight, .frameLeft, .frameRight:
        return true
    case .photoTop, .photoBottom, .frameTop, .frameBottom:
        return false
    }
}

private nonisolated func textLength(_ region: InfoRegion, signature: String) -> Int {
    region.bricks.reduce(0) { total, brick in
        switch brick {
        case .fixedText(let text):
            return total + text.count
        case .signature:
            return total + signature.count
        case .watermark:
            return total + 1
        }
    }
}

private nonisolated func aligned(
    _ alignment: InfoAlignment,
    spanStart: Double,
    spanLength: Double,
    item: Double
) -> Double {
    switch alignment {
    case .leading:
        return spanStart
    case .trailing:
        return spanStart + spanLength - item
    case .center:
        return spanStart + (spanLength - item) / 2
    }
}

private nonisolated func barEdgeTop(_ slot: InfoSlot, spacing: Int, display: PixelRect, canvas: PixelRect) -> Int? {
    switch slot {
    case .photoBottom:
        return display.maxY + spacing
    case .frameTop:
        return spacing
    default:
        _ = canvas
        return nil
    }
}

private nonisolated func barEdgeBottom(_ slot: InfoSlot, spacing: Int, display: PixelRect, canvas: PixelRect) -> Int? {
    switch slot {
    case .photoTop:
        return display.y - spacing
    case .frameBottom:
        return canvas.height - spacing
    default:
        return nil
    }
}

private nonisolated func textRect(
    slot: InfoSlot,
    start: Double,
    along: Double,
    thickness: Double,
    spacing: Int,
    display: PixelRect,
    canvas: PixelRect
) -> CGRect {
    switch slot {
    case .photoBottom:
        return CGRect(x: start, y: Double(display.maxY + spacing), width: along, height: thickness)
    case .photoTop:
        return CGRect(x: start, y: Double(display.y - spacing) - thickness, width: along, height: thickness)
    case .frameTop:
        return CGRect(x: start, y: Double(spacing), width: along, height: thickness)
    case .frameBottom:
        return CGRect(x: start, y: Double(canvas.height - spacing) - thickness, width: along, height: thickness)
    case .photoLeft:
        return CGRect(x: Double(display.x - spacing) - thickness, y: start, width: thickness, height: along)
    case .photoRight:
        return CGRect(x: Double(display.maxX + spacing), y: start, width: thickness, height: along)
    case .frameLeft:
        return CGRect(x: Double(spacing), y: start, width: thickness, height: along)
    case .frameRight:
        return CGRect(x: Double(canvas.width - spacing) - thickness, y: start, width: thickness, height: along)
    }
}

private nonisolated struct SplitLayout {
    var slices: [PixelRect]
    var guides: [Int]
    var gap: Int
}

private nonisolated func splitLayout(document: FrameDocument, canvas: PixelRect, longEdge: Int) -> SplitLayout {
    guard let split = document.layers.split else {
        return SplitLayout(
            slices: [PixelRect(x: 0, y: 0, width: canvas.width, height: canvas.height)],
            guides: [],
            gap: 0
        )
    }
    let gap: Int
    switch split.gap {
    case .custom(let percent):
        gap = roundToInt(percent.value / 100 * Double(longEdge))
    case .platform:
        gap = 0
    }
    let count = split.count
    let content = max(0, canvas.width - gap * (count - 1))
    let base = count > 0 ? content / count : 0
    let remainder = count > 0 ? content % count : 0
    var slices: [PixelRect] = []
    var x = 0
    for index in 0..<count {
        let width = base + (index < remainder ? 1 : 0)
        slices.append(PixelRect(x: x, y: 0, width: width, height: canvas.height))
        x += width + gap
    }
    return SplitLayout(slices: slices, guides: slices.dropFirst().map(\.x), gap: gap)
}
