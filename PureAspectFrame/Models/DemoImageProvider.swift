import Foundation
import CoreGraphics

/// 提供應用程式內建之示範樣張影像與 EXIF 資訊
public struct DemoImageProvider {
    public static func makeDemoImage(width: Int = 1600, height: Int = 1067) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        // 暖色調攝影風格漸層
        let colors = [
            CGColor(red: 0.15, green: 0.25, blue: 0.45, alpha: 1.0),
            CGColor(red: 0.85, green: 0.65, blue: 0.45, alpha: 1.0)
        ] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)!
        
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
            options: []
        )
        
        // 日系主體幾何構圖
        context.setFillColor(CGColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 0.9))
        context.fillEllipse(in: CGRect(x: CGFloat(width) * 0.25, y: CGFloat(height) * 0.2, width: CGFloat(width) * 0.5, height: CGFloat(height) * 0.6))
        
        return context.makeImage()!
    }
    
    public static var demoExif: ExifMetadata {
        ExifMetadata(
            make: "LEICA CAMERA AG",
            model: "LEICA M11",
            lensModel: "Summilux-M 35mm f/1.4 ASPH.",
            focalLength: 35.0,
            fNumber: 1.4,
            shutterSpeed: "1/500",
            iso: 64,
            dateTimeOriginal: Date()
        )
    }
}
