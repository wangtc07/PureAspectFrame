import Testing
import Foundation
import CoreGraphics
import SwiftData
import SwiftUI
@testable import PureAspectFrame

@MainActor
struct UIWorkflowTests {
    // Helper to generate a test CGImage
    private func makeTestImage() -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(
            data: nil,
            width: 800,
            height: 600,
            bitsPerComponent: 8,
            bytesPerRow: 3200,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 0.1, green: 0.5, blue: 0.8, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        return ctx.makeImage()!
    }

    @Test func testSwiftDataManualLensCRUD() throws {
        let schema = Schema([ManualLens.self, FrameTemplate.self, ArtworkRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // 1. Create lens
        let lens = ManualLens(name: "Noctilux 50/0.95", focalLength: 50, maxAperture: 0.95, brand: "Leica")
        context.insert(lens)
        try context.save()

        // 2. Fetch
        let fetchDesc = FetchDescriptor<ManualLens>()
        let results = try context.fetch(fetchDesc)
        #expect(results.count == 1)
        #expect(results.first?.name == "Noctilux 50/0.95")
        #expect(results.first?.displayTitle.contains("50mm f/0.95") == true)

        // 3. Delete
        context.delete(lens)
        try context.save()
        let afterDelete = try context.fetch(fetchDesc)
        #expect(afterDelete.isEmpty)
    }

    @Test func testSwiftDataFrameTemplatePersistenceAndDecoding() throws {
        let schema = Schema([ManualLens.self, FrameTemplate.self, ArtworkRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        var customBorder = BorderSettings()
        customBorder.paddingTop = 25
        customBorder.paddingBottom = 35
        customBorder.cornerRadius = 15

        let template = FrameTemplate(
            name: "日系膠卷白邊",
            canvasRatio: .polaroidSquare,
            internalRatio: .square1x1,
            isZeroCrop: false,
            borderSettings: customBorder,
            backgroundMode: .white
        )
        context.insert(template)
        try context.save()

        let fetchDesc = FetchDescriptor<FrameTemplate>()
        let templates = try context.fetch(fetchDesc)
        #expect(templates.count == 1)
        
        let loaded = templates[0]
        #expect(loaded.name == "日系膠卷白邊")
        #expect(loaded.canvasRatio == .polaroidSquare)
        #expect(loaded.internalRatio == .square1x1)
        #expect(loaded.borderSettings.paddingTop == 25)
        #expect(loaded.borderSettings.paddingBottom == 35)
        #expect(loaded.borderSettings.cornerRadius == 15)
    }

    @Test func testArtworkRecordDualStoragePolicy() throws {
        let schema = Schema([ManualLens.self, FrameTemplate.self, ArtworkRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // Full image record
        let dummyData = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let fullRecord = ArtworkRecord(
            title: "Leica Portrait",
            storagePolicy: .fullImage,
            thumbnailData: dummyData,
            exportedImageData: dummyData,
            diskSizeBytes: 4096
        )
        context.insert(fullRecord)

        // Settings only record
        let settingsOnlyRecord = ArtworkRecord(
            title: "Sony Sunset",
            storagePolicy: .settingsOnly,
            assetLocalIdentifier: "LOCAL-PHASSET-123",
            thumbnailData: dummyData,
            diskSizeBytes: 128
        )
        context.insert(settingsOnlyRecord)
        try context.save()

        let fetchDesc = FetchDescriptor<ArtworkRecord>()
        let records = try context.fetch(fetchDesc)
        #expect(records.count == 2)
        
        let full = records.first(where: { $0.storagePolicy == .fullImage })
        #expect(full?.exportedImageData != nil)
        #expect(full?.diskSizeBytes == 4096)

        let settings = records.first(where: { $0.storagePolicy == .settingsOnly })
        #expect(settings?.exportedImageData == nil)
        #expect(settings?.assetLocalIdentifier == "LOCAL-PHASSET-123")
        #expect(settings?.diskSizeBytes == 128)
    }

    @Test func testToolbarButtonsInitialization() {
        var didClick = false
        let closeBtn = CloseToolbarButton { didClick = true }
        closeBtn.action()
        #expect(didClick)
        
        var didConfirm = false
        let confirmBtn = ConfirmToolbarButton { didConfirm = true }
        confirmBtn.action()
        #expect(didConfirm)
    }

    @Test func testPaddingEdgeIconInitialization() {
        for edge in PaddingEdge.allCases {
            let icon = PaddingEdgeIcon(edge: edge, isSelected: true)
            #expect(icon.edge == edge)
            #expect(icon.isSelected == true)
        }
    }

    @Test func testHSBColorPickerViewComponents() {
        var h: Double = 0.5
        var s: Double = 0.8
        var b: Double = 0.9
        
        let bindingH = Binding(get: { h }, set: { h = $0 })
        let bindingS = Binding(get: { s }, set: { s = $0 })
        let bindingB = Binding(get: { b }, set: { b = $0 })
        
        let _ = HSBColorPickerView(hue: bindingH, saturation: bindingS, brightness: bindingB)
        let _ = GradientSlider(value: bindingH, gradientColors: [.red, .blue])
        let _ = SliderDirectValueInput(value: bindingH, range: 0...360, suffix: "°")
        
        #expect(h == 0.5)
        #expect(s == 0.8)
        #expect(b == 0.9)
    }

    @Test func testPaddingBoxWidget() {
        var clickedEdge: PaddingEdge?
        var selectAllCalled = false
        let widget = PaddingBoxWidget(
            selectedEdges: [.top, .bottom],
            linkGroups: [[.top, .bottom], [.left, .right]],
            isLinkedActive: false,
            activeLinkSlot: 0,
            onSelectEdge: { edge in
                clickedEdge = edge
            },
            onSelectAll: {
                selectAllCalled = true
            }
        )
        #expect(widget.selectedEdges.contains(.top))
        #expect(widget.selectedEdges.contains(.bottom))
        #expect(!widget.selectedEdges.contains(.left))
        
        widget.onSelectEdge(.left)
        #expect(clickedEdge == .left)
        
        widget.onSelectAll?()
        #expect(selectAllCalled == true)
    }

    @Test func testEditableNumberBadgeScrubberLogic() {
        // 往上滑動 (translationY < 0) 應增加數值
        let increased = EditableNumberBadge.calculateScrubbedValue(
            startValue: 20,
            translationY: -30,
            sensitivity: 3.0,
            range: 0...40
        )
        #expect(increased == 30)
        
        // 往下滑動 (translationY > 0) 應減少數值，並限制在範圍下限
        let decreased = EditableNumberBadge.calculateScrubbedValue(
            startValue: 20,
            translationY: 150,
            sensitivity: 3.0,
            range: 0...40
        )
        #expect(decreased == 0)

        // 測試超出上限限制
        let clampedMax = EditableNumberBadge.calculateScrubbedValue(
            startValue: 35,
            translationY: -60,
            sensitivity: 3.0,
            range: 0...40
        )
        #expect(clampedMax == 40)
    }

    @Test func testCanvasStageViewInstantiation() {
        let testImage = makeTestImage()
        var border = BorderSettings()
        var showDistance = true
        var isCollapsed = false
        
        let stage = CanvasStageView(
            image: testImage,
            canvasRatio: .ig4x5,
            internalRatio: .square1x1,
            isZeroCrop: false,
            borderSettings: Binding(get: { border }, set: { border = $0 }),
            backgroundMode: .white,
            footerSettings: FooterSettings(),
            exifMetadata: ExifMetadata(),
            showDistanceMarkers: Binding(get: { showDistance }, set: { showDistance = $0 }),
            isBottomPanelCollapsed: Binding(get: { isCollapsed }, set: { isCollapsed = $0 })
        )
        let _ = stage.body
        #expect(showDistance == true)
    }

    @Test func testArtworkSelectionState() {
        var state = ArtworkSelectionState()
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let allIDs = [id1, id2, id3]

        // 初始狀態為空
        #expect(state.selectedIDs.isEmpty)
        #expect(!state.isSelected(id1))

        // 單選切換
        state.toggle(id1)
        #expect(state.isSelected(id1))
        #expect(state.selectedIDs.count == 1)

        state.toggle(id2)
        #expect(state.isSelected(id2))
        #expect(state.selectedIDs.count == 2)

        state.toggle(id1)
        #expect(!state.isSelected(id1))
        #expect(state.selectedIDs.count == 1)

        // 全選與取消全選切換
        state.toggleSelectAll(from: allIDs)
        #expect(state.selectedIDs.count == 3)
        #expect(state.isSelected(id1) && state.isSelected(id2) && state.isSelected(id3))

        // 再次切換全選應全部取消
        state.toggleSelectAll(from: allIDs)
        #expect(state.selectedIDs.isEmpty)
    }

    @Test func testArtworkExportHelperAndBatchDelete() throws {
        let schema = Schema([ManualLens.self, FrameTemplate.self, ArtworkRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        // 建立測試用圖片 Data
        let testImage = makeTestImage()
        let uiImage = UIImage(cgImage: testImage)
        let imgData = uiImage.jpegData(compressionQuality: 0.9)!

        let record1 = ArtworkRecord(title: "Record 1", storagePolicy: .fullImage, exportedImageData: imgData)
        let record2 = ArtworkRecord(title: "Record 2", storagePolicy: .settingsOnly, thumbnailData: imgData)
        let record3 = ArtworkRecord(title: "Record 3", storagePolicy: .settingsOnly, thumbnailData: nil)

        context.insert(record1)
        context.insert(record2)
        context.insert(record3)
        try context.save()

        // 導出測試
        let exportedImages = ArtworkExportHelper.exportImages(for: [record1, record2, record3])
        #expect(exportedImages.count == 2)

        // 單項導出測試
        #expect(ArtworkExportHelper.exportImage(for: record1) != nil)
        #expect(ArtworkExportHelper.exportImage(for: record3) == nil)

        // 批次刪除測試
        var selection = ArtworkSelectionState()
        selection.toggle(record1.id)
        selection.toggle(record2.id)

        let allRecords = try context.fetch(FetchDescriptor<ArtworkRecord>())
        for record in allRecords where selection.isSelected(record.id) {
            context.delete(record)
        }
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<ArtworkRecord>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == record3.id)
    }

    @Test func testCanvasStageImageAdjustmentVisualStyles() {
        let testImage = makeTestImage()
        var border = BorderSettings()
        let footer = FooterSettings()
        let exif = ExifMetadata()

        // 驗證 CanvasStageView 支援手勢調整狀態之初始參數
        let stage = CanvasStageView(
            image: testImage,
            canvasRatio: .ig4x5,
            internalRatio: .square1x1,
            isZeroCrop: false,
            borderSettings: Binding(get: { border }, set: { border = $0 }),
            backgroundMode: .white,
            footerSettings: footer,
            exifMetadata: exif,
            showDistanceMarkers: .constant(false),
            isBottomPanelCollapsed: .constant(false),
            initialOffset: CGSize(width: 20, height: -10),
            initialScale: 1.25,
            initialIsAdjustingImage: true
        )
        _ = stage

        // 驗證內部畫框指示線：細灰黑虛線（lineWidth: 1.0, dash: [4, 3]），無陰影模糊
        let lightInnerStroke = CanvasStageView.innerFrameStrokeStyle
        #expect(lightInnerStroke.lineWidth == 1.0)
        #expect(lightInnerStroke.dash == [4, 3])

        let lightInnerColor = CanvasStageView.innerFrameColor(isDarkBackground: false)
        let darkInnerColor = CanvasStageView.innerFrameColor(isDarkBackground: true)
        #expect(lightInnerColor != darkInnerColor)

        // 驗證實際照片超出部分邊界：半透明淺灰色虛線（lineWidth: 1.0, dash: [5, 4]），無陰影模糊
        let overflowStroke = CanvasStageView.photoOverflowStrokeStyle
        #expect(overflowStroke.lineWidth == 1.0)
        #expect(overflowStroke.dash == [5, 4])

        let overflowColor = CanvasStageView.photoOverflowColor
        #expect(overflowColor == Color(hex: "#8E8E93").opacity(0.65))
    }

    @Test func testRatioTabViewOrientationToggle() {
        var canvasRatio: CanvasRatio = .ig4x5
        var isLandscape = false
        var internalRatio: InternalCropRatio = .square1x1
        var isZeroCrop = false

        let view = RatioTabView(
            canvasRatio: Binding(get: { canvasRatio }, set: { canvasRatio = $0 }),
            isLandscape: Binding(get: { isLandscape }, set: { isLandscape = $0 }),
            internalRatio: Binding(get: { internalRatio }, set: { internalRatio = $0 }),
            isZeroCrop: Binding(get: { isZeroCrop }, set: { isZeroCrop = $0 })
        )
        _ = view

        // 驗證初始為直式
        #expect(canvasRatio.displayName(isLandscape: isLandscape) == "4:5 (IG)")
        #expect(isLandscape == false)

        // 切換為橫式
        isLandscape = true
        #expect(canvasRatio.displayName(isLandscape: isLandscape) == "5:4 (IG)")
        #expect(isLandscape == true)
        
        // 驗證內部比例選項均無「自由」
        #expect(!InternalCropRatio.allCases.map(\.rawValue).contains("自由"))
        #expect(InternalCropRatio.allCases.count == 4)
    }

    @Test func testCanvasStageSplitPreviewAndCutLine() {
        // 1. 驗證切割指示線樣式常數（不能太粗，剛好 1.0pt 細線；暗調底基 2.0pt，確保暗調與亮調照片均能清晰可見）
        #expect(CanvasStageView.splitCutLineWidth == 1.0)
        #expect(CanvasStageView.splitCutLineBaseWidth == 2.0)
        #expect(CanvasStageView.splitCutLineWhiteColor == Color.white.opacity(0.95))
        #expect(CanvasStageView.splitCutLineDarkColor == Color.black.opacity(0.65))

        // 2. 驗證切割預覽幾何計算（無縫 0px 切割）
        var split = SplitSettings()
        split.isEnabled = true
        split.splitCount = 3
        split.gapPx = 0

        let cutPositions = CanvasStageView.calculateCutLinePositions(totalWidth: 300, splitSettings: split)
        #expect(cutPositions.count == 2)
        #expect(abs(cutPositions[0] - 100.0) < 0.01)
        #expect(abs(cutPositions[1] - 200.0) < 0.01)

        // 3. 驗證切割預覽幾何計算（有間隔切割，例如 Threads/Twitter 平台預設）
        split.gapPx = 10
        let slicesWithGap = CanvasStageView.calculateSplitPreviewSlices(totalWidth: 320, splitSettings: split)
        #expect(slicesWithGap.count == 3)
        // 總寬度 320，2 個間隙各 10，剩餘 300 / 3 = 100
        #expect(abs(slicesWithGap[0].width - 100.0) < 0.01)
        #expect(abs(slicesWithGap[1].width - 100.0) < 0.01)
        #expect(abs(slicesWithGap[2].width - 100.0) < 0.01)
        #expect(abs(slicesWithGap[0].minX - 0.0) < 0.01)
        #expect(abs(slicesWithGap[1].minX - 110.0) < 0.01)
        #expect(abs(slicesWithGap[2].minX - 220.0) < 0.01)

        // 4. 驗證 CanvasStageView 支援接收 splitSettings
        let dummyImage = makeTestImage()
        var border = BorderSettings()
        var showDistance = false
        var isCollapsed = false

        let stage = CanvasStageView(
            image: dummyImage,
            canvasRatio: .ig4x5,
            isZeroCrop: false,
            borderSettings: Binding(get: { border }, set: { border = $0 }),
            backgroundMode: .white,
            footerSettings: FooterSettings(),
            splitSettings: split,
            exifMetadata: ExifMetadata(),
            showDistanceMarkers: Binding(get: { showDistance }, set: { showDistance = $0 }),
            isBottomPanelCollapsed: Binding(get: { isCollapsed }, set: { isCollapsed = $0 })
        )
        _ = stage
    }

    @Test func testSNSPreviewViewPlatformFeaturesAndGestures() {
        // 1. 驗證各社群平台規範常數
        #expect(SNSTargetPlatform.instagram.postCornerRadius == 0)
        #expect(SNSTargetPlatform.threads.postCornerRadius == 12)
        #expect(SNSTargetPlatform.xTwitter.postCornerRadius == 16)
        #expect(SNSTargetPlatform.redBook.postCornerRadius == 8)
        
        #expect(SNSTargetPlatform.threads.supportsPinchToMerge == true)
        #expect(SNSTargetPlatform.instagram.supportsPinchToMerge == false)

        // 2. 驗證 Threads 雙圖捏合縫合幾何計算
        #expect(SNSPreviewView.threadsGap(isMerged: false) == 6.0)
        #expect(SNSPreviewView.threadsGap(isMerged: true) == 0.0)
        #expect(SNSPreviewView.threadsInnerCornerRadius(isMerged: false) == 12.0)
        #expect(SNSPreviewView.threadsInnerCornerRadius(isMerged: true) == 0.0)

        // 3. 驗證 SNSPreviewView 初始化與狀態參數
        let img1 = makeTestImage()
        let img2 = makeTestImage()
        let view = SNSPreviewView(
            renderedImage: img1,
            slices: [img1, img2],
            initialPlatform: .threads,
            initialIsThreadsMerged: true
        )
        _ = view
    }

    @Test func testSNSPreviewDynamicAspectRatioCalculations() {
        // 1. Instagram 滿版寬度下依實際圖片比例動態計算高度 (1.91:1 ~ 3:4 範圍)
        let screenWidth: CGFloat = 400.0
        // 3:2 橫圖 (1.5) -> 400 / 1.5 = 266.67
        let igLandscapeH = SNSPreviewView.instagramMediaHeight(containerWidth: screenWidth, imageAspectRatio: 1.5)
        #expect(abs(igLandscapeH - 266.666) < 0.1)

        // 1:1 方圖 (1.0) -> 400
        let igSquareH = SNSPreviewView.instagramMediaHeight(containerWidth: screenWidth, imageAspectRatio: 1.0)
        #expect(abs(igSquareH - 400.0) < 0.1)

        // 4:5 直圖 (0.8) -> 400 / 0.8 = 500
        let igPortraitH = SNSPreviewView.instagramMediaHeight(containerWidth: screenWidth, imageAspectRatio: 0.8)
        #expect(abs(igPortraitH - 500.0) < 0.1)

        // 2. Threads 水平滾動多圖：固定輪播高度下，每張切片寬度依圖片真實比例動態計算
        let threadsH: CGFloat = 330.0
        let threads2x3Size = SNSPreviewView.threadsCarouselItemSize(carouselHeight: threadsH, imageAspectRatio: 2.0 / 3.0)
        #expect(abs(threads2x3Size.width - 220.0) < 0.1)
        #expect(abs(threads2x3Size.height - 330.0) < 0.1)

        let threads4x5Size = SNSPreviewView.threadsCarouselItemSize(carouselHeight: threadsH, imageAspectRatio: 0.8)
        #expect(abs(threads4x5Size.width - 264.0) < 0.1)

        // 3. X (Twitter) 水平滾動多圖：固定高度下依實際比例計算寬度，且多圖間隙為 4pt、圓角為 12pt
        let xH: CGFloat = 330.0
        let x2x3Size = SNSPreviewView.xTwitterCarouselItemSize(carouselHeight: xH, imageAspectRatio: 2.0 / 3.0)
        #expect(abs(x2x3Size.width - 220.0) < 0.1)
        #expect(abs(x2x3Size.height - 330.0) < 0.1)
        #expect(SNSPreviewView.xTwitterCarouselGap == 4.0)
        #expect(SNSPreviewView.xTwitterMediaCornerRadius == 12.0)

        // 4. 驗證貼文區域中性假資料（帳號、日期符號內文）、左上角 X 關閉按鈕與各平台真實互動/分享圖示列
        #expect(SNSPreviewView.usesLeadingCloseButton == true)
        #expect(!SNSPreviewView.placeholderUsername.isEmpty)
        #expect(SNSPreviewView.placeholderCaption.contains("2026"))
        #expect(SNSPreviewView.actionIconNames(for: .instagram) == ["heart", "message", "arrow.2.squarepath", "paperplane", "bookmark"])
        #expect(SNSPreviewView.actionIconNames(for: .threads) == ["heart", "message", "arrow.2.squarepath", "paperplane"])
        #expect(SNSPreviewView.actionIconNames(for: .xTwitter) == ["bubble.left", "arrow.2.squarepath", "heart", "bookmark", "square.and.arrow.up"])

        // 5. 驗證從實際 SNS 官方 SVG 向量路徑繪製之圖示 (Instagram / Threads / X) 皆能產生有效非空向量路徑
        #expect(SNSPreviewView.officialActionIcons(for: .instagram) == [.igHeart, .igComment, .igRepost, .igShare, .igBookmark])
        #expect(SNSPreviewView.officialActionIcons(for: .threads) == [.igHeart, .igComment, .igRepost, .igShare])
        #expect(SNSPreviewView.officialActionIcons(for: .xTwitter) == [.xReply, .xRetweet, .xHeart, .xBookmark, .xShare])

        let targetRect = CGRect(x: 0, y: 0, width: 24, height: 24)
        for icon in SNSOfficialIcon.allCases {
            let path = icon.path(in: targetRect)
            #expect(!path.isEmpty)
            #expect(path.boundingRect.width > 4.0)
            #expect(path.boundingRect.height > 4.0)
        }
    }

    @Test func testHomeViewSystemPhotosStyleSelectionAndRightStackedIconButtons() {
        // 1. 驗證首頁右上角按鈕順序為「設定 -> 選擇」兩個按鈕
        #expect(HomeView.topTrailingButtonOrder == ["settings", "select"])
        
        // 2. 驗證選擇模式參考系統相簿 UI：
        // - 右上關閉按鈕為圓形 X ("xmark")
        // - 底部左側圓形分享按鈕 ("square.and.arrow.up")、中間選取數量文字、右側圓形垃圾桶按鈕 ("trash")
        // - 照片卡片選取標記位於右下角 (.bottomTrailing)，且未選取時不顯示空白圓圈
        #expect(HomeView.selectionUsesSystemPhotosStyle == true)
        #expect(HomeView.selectionCloseButtonIcon == "xmark")
        #expect(HomeView.selectionBottomExportIcon == "square.and.arrow.up")
        #expect(HomeView.selectionBottomDeleteIcon == "trash")
        #expect(HomeView.selectionBadgeAlignment == .bottomTrailing)
        #expect(HomeView.selectionShowsUnselectedCircle == false)
        
        // 3. 驗證快速導入與自訂編輯改成只有 icon，放在右邊垂直堆疊放置
        #expect(HomeView.importButtonsShowIconOnly == true)
        #expect(HomeView.importButtonsAreRightAlignedVerticalStack == true)
        #expect(HomeView.quickImportIconName == "bolt.fill")
        #expect(HomeView.customEditIconName == "plus")
        
        // 4. 驗證選取狀態文字格式
        #expect(HomeView.selectionStatusText(count: 0) == "選取項目")
        #expect(HomeView.selectionStatusText(count: 6) == "已選取 6 張")
    }
}

