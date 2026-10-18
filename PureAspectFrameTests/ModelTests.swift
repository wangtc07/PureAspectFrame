import Testing
import Foundation
import CoreGraphics
@testable import PureAspectFrame

struct ModelTests {
    // MARK: - CanvasRatio Tests
    @Test func testCanvasRatioCalculations() {
        let eps: CGFloat = 0.0001
        // Standard SNS ratios
        #expect(abs(CanvasRatio.ig4x5.aspectRatio - (4.0 / 5.0)) < eps)
        #expect(abs(CanvasRatio.square1x1.aspectRatio - 1.0) < eps)
        #expect(abs(CanvasRatio.xhs3x4.aspectRatio - (3.0 / 4.0)) < eps)
        #expect(abs(CanvasRatio.story9x16.aspectRatio - (9.0 / 16.0)) < eps)
        #expect(abs(CanvasRatio.landscape16x9.aspectRatio - (16.0 / 9.0)) < eps)
        
        // Polaroid physical dimensions
        #expect(abs(CanvasRatio.polaroidMini.aspectRatio - (54.0 / 86.0)) < eps)
        #expect(abs(CanvasRatio.polaroidSquare.aspectRatio - (72.0 / 86.0)) < eps)
        #expect(abs(CanvasRatio.polaroidWide.aspectRatio - (108.0 / 86.0)) < eps)
        
        // Target canvas dimensions
        let bounds = CanvasRatio.ig4x5.targetPixelSize(baseWidth: 1080)
        #expect(bounds.width == 1080)
        #expect(bounds.height == 1350)
    }

    // MARK: - BorderSettings Tests
    @Test func testBorderLinkedEdgesPersistence() {
        var border = BorderSettings()
        #expect(border.isLinkedActive == false)
        #expect(border.linkedEdges.contains(.top))
        #expect(border.linkedEdges.contains(.bottom))
        #expect(border.linkedEdges.contains(.left))
        #expect(border.linkedEdges.contains(.right))

        // Enter link mode: toggle edge
        border.isLinkedActive = true
        border.toggleEdgeInLinkMode(.bottom)
        #expect(!border.linkedEdges.contains(.bottom))
        #expect(border.linkedEdges.contains(.top))

        // Exit link mode: persistence remains
        border.isLinkedActive = false
        // Tapping .top should select all currently linked edges (.top, .left, .right)
        let affected = border.selectEdgeForAdjustment(.top)
        #expect(affected.contains(.top))
        #expect(affected.contains(.left))
        #expect(affected.contains(.right))
        #expect(!affected.contains(.bottom))

        // Updating linked edges updates all connected edges
        border.updatePadding(for: .top, value: 40)
        #expect(border.paddingTop == 40)
        #expect(border.paddingLeft == 40)
        #expect(border.paddingRight == 40)
        #expect(border.paddingBottom != 40) // Bottom was unlinked, retains default
    }

    // MARK: - SplitSettings Tests
    @Test func testSplitSettingsSlicingCalculations() {
        var split = SplitSettings()
        split.splitCount = 3
        split.gapPx = 10
        #expect(split.splitCount == 3)
        #expect(split.gapPx == 10)

        // Calculate slice rects for a 1200x800 canvas
        let slices = split.calculateSlices(totalWidth: 1200, totalHeight: 800)
        #expect(slices.count == 3)
        // Check slices are horizontal left-to-right
        #expect(slices[0].minX == 0)
        #expect(slices[1].minX > slices[0].maxX)
    }
}
