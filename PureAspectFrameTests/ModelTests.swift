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

    @Test func testBorderTwoLinkGroups() {
        var border = BorderSettings()
        // 預設：只有 A 組（四邊），B 組為空
        #expect(border.linkGroups.count == 2)
        #expect(border.linkGroups[0] == Set(PaddingEdge.allCases))
        #expect(border.linkGroups[1].isEmpty)

        // 重新規劃：A = 上下、B = 左右
        border.setLinkGroups(a: [.top, .bottom], b: [.left, .right])
        #expect(border.groupIndex(of: .top) == 0)
        #expect(border.groupIndex(of: .bottom) == 0)
        #expect(border.groupIndex(of: .left) == 1)
        #expect(border.groupIndex(of: .right) == 1)

        // 點選上 → 選中上下；點選右 → 選中左右
        #expect(border.selectEdgeForAdjustment(.top) == [.top, .bottom])
        #expect(border.selectEdgeForAdjustment(.right) == [.left, .right])

        // 兩組互不影響
        border.updatePadding(for: .top, value: 10)
        border.updatePadding(for: .left, value: 30)
        #expect(border.paddingTop == 10 && border.paddingBottom == 10)
        #expect(border.paddingLeft == 30 && border.paddingRight == 30)
    }

    @Test func testBorderLinkModeAssignsEdgeToActiveSlotExclusively() {
        var border = BorderSettings()
        border.setLinkGroups(a: [.top, .bottom], b: [])
        border.isLinkedActive = true

        // 在 B 組模式下點選上：上從 A 移到 B（一條邊只屬於一組）
        border.activeLinkSlot = 1
        border.toggleEdgeInLinkMode(.top)
        #expect(border.groupIndex(of: .top) == 1)
        #expect(!border.linkGroups[0].contains(.top))

        // 再點一次同一邊 → 從 B 移除，變成未連結
        border.toggleEdgeInLinkMode(.top)
        #expect(border.groupIndex(of: .top) == nil)

        // 只剩單邊的組不構成連結：A 只剩下 → 調整下不連動
        border.isLinkedActive = false
        #expect(border.selectEdgeForAdjustment(.bottom) == [.bottom])
        border.updatePadding(for: .bottom, value: 5)
        #expect(border.paddingTop != 5)
    }

    @Test func testBorderSettingsDecodesLegacyLinkedEdges() throws {
        // 舊版模板只有 linkedEdges 欄位（單組連結）
        let legacy = """
        {"unit":"%","paddingTop":20,"paddingBottom":20,"paddingLeft":20,"paddingRight":20,
         "isLinkedActive":false,"linkedEdges":["上","下"],"selectedEdges":["上"],
         "cornerRadius":0,"cornerRadiusUnit":"%"}
        """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(BorderSettings.self, from: legacy)
        #expect(decoded.linkGroups[0] == [.top, .bottom])
        #expect(decoded.linkGroups[1].isEmpty)

        // 新版編碼往返
        var border = BorderSettings()
        border.setLinkGroups(a: [.top, .bottom], b: [.left, .right])
        let data = try JSONEncoder().encode(border)
        let back = try JSONDecoder().decode(BorderSettings.self, from: data)
        #expect(back == border)
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

    // MARK: - BackgroundMode Stage Background Dynamic Adjustment Tests
    @Test func testBackgroundModeStageColorDynamicAdjustment() {
        // 1. 黑色模式：屬於深色，舞台背景應切換為淺灰色 #F5F5F5 (R: 245, G: 245, B: 245)
        let blackMode = BackgroundMode.black
        #expect(blackMode.isDarkOrNearDarkGray == true)
        #expect(blackMode.stageBackgroundColorHex == "#F5F5F5")

        // 2. 白色模式：屬於淺色，舞台背景維持預設深灰色 #1C1C1E (R: 28, G: 28, B: 30)
        let whiteMode = BackgroundMode.white
        #expect(whiteMode.isDarkOrNearDarkGray == false)
        #expect(whiteMode.stageBackgroundColorHex == "#1C1C1E")

        // 3. 自訂顏色：同樣為 #1C1C1E 或更深的顏色，應切換為 #F5F5F5
        let sameAsStageColor = BackgroundMode.customHSB(hue: 240/360, saturation: 0.067, brightness: 30/255)
        #expect(sameAsStageColor.isDarkOrNearDarkGray == true)
        #expect(sameAsStageColor.stageBackgroundColorHex == "#F5F5F5")

        // 4. 自訂顏色：接近深灰色的顏色（如亮度稍高一點的 #2C2C2E 或 #3A3A3C），應動態切換為 #F5F5F5
        let nearDarkGray = BackgroundMode.customHSB(hue: 0, saturation: 0, brightness: 0.22)
        #expect(nearDarkGray.isDarkOrNearDarkGray == true)
        #expect(nearDarkGray.stageBackgroundColorHex == "#F5F5F5")

        // 5. 自訂顏色：亮色（如淺黃色、粉色、淺灰），舞台背景維持深灰 #1C1C1E
        let lightCustom = BackgroundMode.customHSB(hue: 60/360, saturation: 0.2, brightness: 0.9)
        #expect(lightCustom.isDarkOrNearDarkGray == false)
        #expect(lightCustom.stageBackgroundColorHex == "#1C1C1E")
    }
}
