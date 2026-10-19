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
}

