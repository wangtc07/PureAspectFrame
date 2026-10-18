import XCTest
import CoreGraphics
import ImageIO
@testable import PureAspectFrame

final class ImageDecodingTests: XCTestCase {
    
    /// 建立包含指定 EXIF Orientation 的記憶體合成 JPEG 圖片 Data
    private func createTestImageData(width: Int, height: Int, orientation: UInt32) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        ctx.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let cgImage = ctx.makeImage()!
        
        let mutableData = NSMutableData()
        let dest = CGImageDestinationCreateWithData(mutableData as CFMutableData, "public.jpeg" as CFString, 1, nil)!
        let properties: [CFString: Any] = [
            kCGImagePropertyOrientation: orientation
        ]
        CGImageDestinationAddImage(dest, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(dest)
        return mutableData as Data
    }
    
    /// 驗證 EXIF Orientation 8 (旋轉 270 度 / 逆時針 90 度) 能被正確解碼轉正為直向圖片
    func testOrientedCGImageDecodesOrientation8Correctly() {
        // 原圖物理像素寬 300，高 150 (橫向)
        // EXIF Orientation 8 表示相機垂直手持拍攝，展示時應轉正為寬 150，高 300 (直向)
        let data = createTestImageData(width: 300, height: 150, orientation: 8)
        
        // 呼叫 ImageDecodingService 解碼轉正
        guard let orientedImage = ImageDecodingService.createOrientedCGImage(from: data) else {
            XCTFail("解碼 oriented CGImage 失敗")
            return
        }
        
        // 轉正後寬度應為 150，高度應為 300
        XCTAssertEqual(orientedImage.width, 150, "轉正後圖片寬度應為 150")
        XCTAssertEqual(orientedImage.height, 300, "轉正後圖片高度應為 300")
    }
    
    /// 驗證指定 maxPixelSize 能進行快速硬體降採樣，同時保持正確的直向旋轉
    func testOrientedCGImageWithMaxPixelSizeDownsamplesCorrectly() {
        let data = createTestImageData(width: 4000, height: 2000, orientation: 8)
        
        // 要求最大邊長為 1000px 的預覽圖
        guard let thumbImage = ImageDecodingService.createOrientedCGImage(from: data, maxPixelSize: 1000) else {
            XCTFail("生成降採樣縮圖失敗")
            return
        }
        
        // 轉正後最大邊應在高度 (1000)，寬度應按比例縮小為 500
        XCTAssertEqual(thumbImage.height, 1000, "降採樣後高度應為 1000")
        XCTAssertEqual(thumbImage.width, 500, "降採樣後寬度應為 500")
    }
    
    /// 驗證 inspectImage 能在不完整解碼點陣圖的情況下快速獲取圖片方向與原始像素尺寸
    func testInspectImageExtractsOrientationAndPixelSize() {
        let data = createTestImageData(width: 800, height: 600, orientation: 6) // Orientation 6: 90 CW
        
        let info = ImageDecodingService.inspectImage(from: data)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.orientation, 6)
        XCTAssertEqual(info?.pixelSize.width, 800)
        XCTAssertEqual(info?.pixelSize.height, 600)
    }
    
    /// 若磁碟存在真實測試照片 TestData/DSCF0100.jpg，驗證其 EXIF 8 轉正後尺寸為直向 8736 x 11648
    func testRealFixturedImageOrientation() throws {
        let fixturePath = "TestData/DSCF0100.jpg"
        let fileURL = URL(fileURLWithPath: fixturePath)
        guard FileManager.default.fileExists(atPath: fixturePath),
              let data = try? Data(contentsOf: fileURL) else {
            // 本機若無測試檔案則略過此項真實檔案測試
            return
        }
        
        // 快速生成 1600px 預覽縮圖
        guard let preview = ImageDecodingService.createOrientedCGImage(from: data, maxPixelSize: 1600) else {
            XCTFail("無法生成真實照片之預覽縮圖")
            return
        }
        
        // GFX100S II 原圖是 11648 x 8736，Orientation 8
        // 轉正後應為直向 (高度 > 寬度)
        XCTAssertGreaterThan(preview.height, preview.width, "真實相片轉正後高度應大於寬度（直向）")
        XCTAssertEqual(preview.height, 1600, "最大邊長應為 1600")
        XCTAssertEqual(preview.width, 1200, "寬度依比例應為 1200")
    }
}
