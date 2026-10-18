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
        let allItems = FooterItemType.allCases
        let activeItems: [FooterItemType] = [.logo, .camera]
        
        // Available items should only include unused items
        let unused = FooterItemType.unusedItems(active: activeItems)
        #expect(!unused.contains(.logo))
        #expect(!unused.contains(.camera))
        #expect(unused.contains(.lens))
        #expect(unused.contains(.parameters))
    }
}
