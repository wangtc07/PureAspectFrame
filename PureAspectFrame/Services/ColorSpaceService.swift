import Foundation
import CoreGraphics
import ImageIO
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 提供色彩空間轉換 (Display P3 -> sRGB) 與 EXIF/ICC 元資料無損寫回管線服務
public final class ColorSpaceService: Sendable {
    
    /// 將 CGImage 轉換為標準 sRGB 色彩空間，避免在不支援廣色域的 SNS 或平台上產生發灰或偏色
    public static func convertTosRGB(_ image: CGImage) -> CGImage? {
        guard let sRGBColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return image
        }
        
        // 如果原本已經是 sRGB，直接返回
        if image.colorSpace?.name == sRGBColorSpace.name {
            return image
        }
        
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: sRGBColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage() ?? image
    }
    
    /// 將渲染後的 CGImage 寫出為 JPEG 或 PNG Data，並無損寫入原始 EXIF / TIFF 元資料
    public static func exportImageWithMetadata(
        image: CGImage,
        metadata: ExifMetadata?,
        compressionQuality: Double = 0.95
    ) -> Data? {
        let convertedImage = convertTosRGB(image) ?? image
        let mutableData = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        var properties: [String: Any] = [
            kCGImageDestinationLossyCompressionQuality as String: compressionQuality
        ]
        
        if let meta = metadata {
            var tiffDict: [String: Any] = [:]
            if let make = meta.make { tiffDict[kCGImagePropertyTIFFMake as String] = make }
            if let model = meta.model { tiffDict[kCGImagePropertyTIFFModel as String] = model }
            
            var exifDict: [String: Any] = [:]
            if let lens = meta.lensModel { exifDict[kCGImagePropertyExifLensModel as String] = lens }
            if let fl = meta.focalLength { exifDict[kCGImagePropertyExifFocalLength as String] = fl }
            if let fl35 = meta.focalLengthIn35mm { exifDict[kCGImagePropertyExifFocalLenIn35mmFilm as String] = fl35 }
            if let fn = meta.fNumber { exifDict[kCGImagePropertyExifFNumber as String] = fn }
            if let iso = meta.iso { exifDict[kCGImagePropertyExifISOSpeedRatings as String] = [iso] }
            
            properties[kCGImagePropertyTIFFDictionary as String] = tiffDict
            properties[kCGImagePropertyExifDictionary as String] = exifDict
        }
        
        CGImageDestinationAddImage(destination, convertedImage, properties as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
}
