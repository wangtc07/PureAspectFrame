import Testing
import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
@testable import PureAspectFrame

struct ExifAndStorageTests {
    // MARK: - ExifMetadata Tests
    @Test func testExifFormattingAndBrandDetection() {
        var exif = ExifMetadata()
        exif.make = "SONY"
        exif.model = "ILCE-7RM5"
        exif.lensModel = "FE 50mm F1.2 GM"
        exif.focalLength = 50.0
        exif.fNumber = 1.2
        exif.shutterSpeed = "1/500"
        exif.iso = 100
        
        #expect(exif.detectedBrand == .sony)
        #expect(exif.cameraDisplayString == "SONY ILCE-7RM5")
        #expect(exif.lensDisplayString == "FE 50mm F1.2 GM")
        #expect(exif.parametersDisplayString == "50mm  f/1.2  1/500s  ISO 100")
    }
    
    @Test func testExifShutterSpeedFormatting() {
        #expect(ExifMetadata.formatShutterSpeed(0.002) == "1/500s")
        #expect(ExifMetadata.formatShutterSpeed(0.5) == "1/2s")
        #expect(ExifMetadata.formatShutterSpeed(2.0) == "2s")
    }
    
    @Test func testBrandDetectionFromVariousMakes() {
        #expect(CameraBrand.detect(from: "LEICA CAMERA AG") == .leica)
        #expect(CameraBrand.detect(from: "FUJIFILM") == .fujifilm)
        #expect(CameraBrand.detect(from: "Canon") == .canon)
        #expect(CameraBrand.detect(from: "NIKON CORPORATION") == .nikon)
        #expect(CameraBrand.detect(from: "RICOH IMAGING COMPANY, LTD.") == .ricoh)
        #expect(CameraBrand.detect(from: "HASSELBLAD") == .hasselblad)
        #expect(CameraBrand.detect(from: "Apple") == .apple)
        #expect(CameraBrand.detect(from: "Panasonic") == .lumix)
    }

    // MARK: - BackgroundMode Tests
    @Test func testBackgroundModeProperties() {
        let black = BackgroundMode.black
        let white = BackgroundMode.white
        let custom = BackgroundMode.customHSB(hue: 0.5, saturation: 0.8, brightness: 0.9)
        let frosted = BackgroundMode.frostedGlass(blurRadius: 30)

        #expect(black.isFrosted == false)
        #expect(white.isFrosted == false)
        #expect(custom.isFrosted == false)
        #expect(frosted.isFrosted == true)
        #expect(frosted.blurRadius == 30)
    }

    // MARK: - StorageMode Tests
    @Test func testStoragePolicySettings() {
        #expect(StoragePolicy.fullImage.description.contains("保留輸出圖片"))
        #expect(StoragePolicy.settingsOnly.description.contains("僅保留設定"))
    }
}
