import Testing
import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif
@testable import PureAspectFrame

struct ImageRendererTests {
    // Helper to generate a solid test CGImage
    private func makeTestImage(width: Int = 800, height: Int = 600) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )!
        context.setFillColor(CGColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    @Test func testRenderCanvasBasicDimensions() {
        let testImage = makeTestImage(width: 800, height: 600)
        let ratio = CanvasRatio.ig4x5 // 4:5
        let border = BorderSettings()
        let background = BackgroundMode.white
        let footer = FooterSettings()
        let exif = ExifMetadata(make: "LEICA", model: "M11", lensModel: "50mm f/1.4")
        
        let targetWidth: CGFloat = 1080
        let rendered = ImageRendererService.render(
            image: testImage,
            canvasRatio: ratio,
            internalRatio: .square1x1,
            isZeroCrop: false,
            borderSettings: border,
            backgroundMode: background,
            footerSettings: footer,
            exif: exif,
            baseWidth: targetWidth
        )
        
        #expect(rendered != nil)
        #expect(rendered?.width == 1080)
        #expect(rendered?.height == 1350)
    }

    @Test func testRenderSplitSlices() {
        let testImage = makeTestImage(width: 1200, height: 600)
        var split = SplitSettings()
        split.isEnabled = true
        split.splitCount = 3
        split.gapPx = 0
        
        let slices = ImageRendererService.renderSlices(
            image: testImage,
            canvasRatio: .landscape16x9,
            internalRatio: .square1x1,
            isZeroCrop: false,
            borderSettings: BorderSettings(),
            backgroundMode: .black,
            footerSettings: FooterSettings(),
            splitSettings: split,
            exif: ExifMetadata(),
            baseWidth: 1600
        )
        
        #expect(slices.count == 3)
        for slice in slices {
            #expect(slice.width > 0)
            #expect(slice.height > 0)
        }
    }
}
