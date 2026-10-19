import Testing
import Foundation
import CoreGraphics
import ImageIO
@testable import PureAspectFrame

struct ExifParserAndFooterTests {
    // MARK: - ExifParserService Tests
    @Test func testExifParserFromDictionary() {
        let mockTiff: [String: Any] = [
            kCGImagePropertyTIFFMake as String: "LEICA CAMERA AG",
            kCGImagePropertyTIFFModel as String: "LEICA M11"
        ]
        let mockExif: [String: Any] = [
            kCGImagePropertyExifLensModel as String: "Noctilux-M 50mm f/0.95 ASPH.",
            kCGImagePropertyExifFocalLength as String: 50.0,
            kCGImagePropertyExifFNumber as String: 0.95,
            kCGImagePropertyExifExposureTime as String: 0.001, // 1/1000s
            kCGImagePropertyExifISOSpeedRatings as String: [100]
        ]
        let properties: [String: Any] = [
            kCGImagePropertyTIFFDictionary as String: mockTiff,
            kCGImagePropertyExifDictionary as String: mockExif
        ]
        
        let metadata = ExifParserService.parse(properties: properties)
        #expect(metadata.make == "LEICA CAMERA AG")
        #expect(metadata.model == "LEICA M11")
        #expect(metadata.detectedBrand == .leica)
        #expect(metadata.lensModel == "Noctilux-M 50mm f/0.95 ASPH.")
        #expect(metadata.focalLength == 50.0)
        #expect(metadata.fNumber == 0.95)
        #expect(metadata.shutterSpeed == "1/1000")
        #expect(metadata.iso == 100)
    }

    // MARK: - FooterItem Tests
    @Test func testFooterItemOrderingAndUsageFilter() {
        // Default items in bottom bar: camera, lens, parameters, logo
        let activeItems: [FooterItemType] = [.logo, .camera]
        
        // Available items should only include unused items
        let unused = FooterItemType.unusedItems(active: activeItems)
        #expect(!unused.contains(.logo))
        #expect(!unused.contains(.camera))
        #expect(unused.contains(.lens))
        #expect(unused.contains(.parameters))
        #expect(unused.contains(.spacer))
    }

    @Test func testSpacerFooterItemLimit() {
        // When there is 0 spacer, warehouse has .spacer
        var settings = FooterSettings()
        settings.activeItems = [.logo, .camera]
        #expect(settings.availableUnusedItems.contains(.spacer))

        // When there is 1 spacer, warehouse still allows adding a 2nd spacer
        settings.activeItems = [.logo, .spacer, .camera]
        #expect(settings.availableUnusedItems.contains(.spacer))

        // When there are 2 spacers, warehouse hides .spacer (max 2 spacers)
        settings.activeItems = [.logo, .spacer, .camera, .spacer]
        #expect(!settings.availableUnusedItems.contains(.spacer))
    }

    @Test func testFooterSectionsLayoutAlgorithm() {
        var settings = FooterSettings()

        // 1. 0 Spacers -> 1 section, 預設置中 (All in section 0)
        settings.activeItems = [.logo, .camera, .parameters]
        var sections = settings.layoutSections
        #expect(sections.count == 1)
        #expect(sections[0] == [.logo, .camera, .parameters])

        // 2. 1 Spacer in middle -> 2 sections (Left, Right)
        settings.activeItems = [.logo, .camera, .spacer, .parameters]
        sections = settings.layoutSections
        #expect(sections.count == 2)
        #expect(sections[0] == [.logo, .camera])
        #expect(sections[1] == [.parameters])

        // 3. 2 Spacers (middle and end) -> 3 sections: Left + Center (Right empty) -> 置左 + 置中
        settings.activeItems = [.logo, .camera, .spacer, .parameters, .spacer]
        sections = settings.layoutSections
        #expect(sections.count == 3)
        #expect(sections[0] == [.logo, .camera])
        #expect(sections[1] == [.parameters])
        #expect(sections[2] == [])

        // 4. 2 Spacers (beginning and middle) -> 3 sections: Center + Right (Left empty) -> 置中 + 置右
        settings.activeItems = [.spacer, .camera, .spacer, .parameters]
        sections = settings.layoutSections
        #expect(sections.count == 3)
        #expect(sections[0] == [])
        #expect(sections[1] == [.camera])
        #expect(sections[2] == [.parameters])

        // 5. 2 Spacers (middle and middle) -> 3 sections: Left + Center + Right
        settings.activeItems = [.logo, .spacer, .camera, .spacer, .parameters]
        sections = settings.layoutSections
        #expect(sections.count == 3)
        #expect(sections[0] == [.logo])
        #expect(sections[1] == [.camera])
        #expect(sections[2] == [.parameters])
    }

    @Test func testFooterMoveItem() {
        var settings = FooterSettings()
        settings.activeItems = [.logo, .camera, .spacer, .parameters]
        
        // 測試將第 3 個 (parameters) 往前移到第 0 個位置
        settings.moveItem(from: 3, to: 0)
        #expect(settings.activeItems == [.parameters, .logo, .camera, .spacer])

        // 測試將第 0 個移到第 2 個位置
        settings.moveItem(from: 0, to: 2)
        #expect(settings.activeItems == [.logo, .camera, .parameters, .spacer])
    }

    @Test func testFooterSwapAndAddItem() {
        var settings = FooterSettings()
        settings.activeItems = [.logo, .camera]
        
        // 測試交換相鄰位置
        settings.swapItems(at: 0, with: 1)
        #expect(settings.activeItems == [.camera, .logo])
        
        // 測試加入重複積木（一般積木不重複加入）
        settings.addItem(.camera)
        #expect(settings.activeItems == [.camera, .logo])
        
        // 測試加入 spacer（最多 2 個）
        settings.addItem(.spacer)
        #expect(settings.activeItems == [.camera, .logo, .spacer])
        settings.addItem(.spacer)
        #expect(settings.activeItems == [.camera, .logo, .spacer, .spacer])
        // 第 3 個 spacer 應被阻擋
        settings.addItem(.spacer)
        #expect(settings.activeItems == [.camera, .logo, .spacer, .spacer])
    }

    // MARK: - 底欄無資訊禁選與文字顏色測試 (TDD)
    @Test func testFooterItemHasAvailableInformation() {
        let emptyExif = ExifMetadata()
        #expect(!FooterItemType.logo.hasAvailableInformation(exif: emptyExif))
        #expect(!FooterItemType.camera.hasAvailableInformation(exif: emptyExif))
        #expect(!FooterItemType.lens.hasAvailableInformation(exif: emptyExif))
        #expect(!FooterItemType.parameters.hasAvailableInformation(exif: emptyExif))
        #expect(!FooterItemType.date.hasAvailableInformation(exif: emptyExif))
        #expect(!FooterItemType.customText.hasAvailableInformation(exif: emptyExif, customText: "   "))
        #expect(FooterItemType.customText.hasAvailableInformation(exif: emptyExif, customText: "Shot on iPhone"))
        #expect(FooterItemType.spacer.hasAvailableInformation(exif: emptyExif))

        // 部分 EXIF 存在時
        let cameraExif = ExifMetadata(make: "Sony", model: "ILCE-7RM5")
        #expect(FooterItemType.logo.hasAvailableInformation(exif: cameraExif))
        #expect(FooterItemType.camera.hasAvailableInformation(exif: cameraExif))
        #expect(!FooterItemType.lens.hasAvailableInformation(exif: cameraExif))
        #expect(!FooterItemType.parameters.hasAvailableInformation(exif: cameraExif))

        let paramExif = ExifMetadata(fNumber: 2.8)
        #expect(FooterItemType.parameters.hasAvailableInformation(exif: paramExif))
    }

    @Test func testFooterSettingsTextColorDefaultAndCustom() {
        let defaultSettings = FooterSettings()
        // 預設改成灰色 (因為預設白底)，預設值為 #8E8E93 (iOS 系統灰)
        #expect(defaultSettings.textColorHex == "#8E8E93")
        
        var customSettings = defaultSettings
        customSettings.textColorHex = "#FF3B30"
        #expect(customSettings.textColorHex == "#FF3B30")
    }

    @Test func testFooterAddItemGuardsMissingInfo() {
        var settings = FooterSettings()
        settings.activeItems = []
        let emptyExif = ExifMetadata()
        
        // 無相機資訊時，應被保護禁止加入
        settings.addItem(.camera, exif: emptyExif)
        #expect(settings.activeItems.isEmpty)
        
        // spacer 無需 EXIF，隨時可加入
        settings.addItem(.spacer, exif: emptyExif)
        #expect(settings.activeItems == [.spacer])
        
        // 有相機資訊時，允許加入
        let validExif = ExifMetadata(make: "Leica", model: "M11")
        settings.addItem(.camera, exif: validExif)
        #expect(settings.activeItems == [.spacer, .camera])
    }
}

