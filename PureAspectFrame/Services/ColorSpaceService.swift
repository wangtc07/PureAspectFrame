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
    
    // MARK: - 色彩格式轉換 (HSB / RGB / Hex)
    
    /// 將 RGB (0.0 ~ 1.0) 轉換為 Hex 字串 (例如 "#1C1C1E")
    public static func rgbToHex(r: Double, g: Double, b: Double) -> String {
        let redInt = Int((min(max(r, 0.0), 1.0) * 255.0).rounded())
        let greenInt = Int((min(max(g, 0.0), 1.0) * 255.0).rounded())
        let blueInt = Int((min(max(b, 0.0), 1.0) * 255.0).rounded())
        return String(format: "#%02X%02X%02X", redInt, greenInt, blueInt)
    }
    
    /// 將 Hex 字串轉換為 RGB (0.0 ~ 1.0)，失敗返回 nil
    public static func hexToRgb(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        guard cleanHex.count == 6 else { return nil }
        
        var rgbValue: UInt64 = 0
        guard Scanner(string: cleanHex).scanHexInt64(&rgbValue) else { return nil }
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        return (r: r, g: g, b: b)
    }
    
    /// 將 RGB (0.0 ~ 1.0) 轉換為 HSB (0.0 ~ 1.0)
    public static func rgbToHsb(r: Double, g: Double, b: Double) -> (h: Double, s: Double, b: Double) {
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal
        
        var h: Double = 0
        if delta > 1e-5 {
            if maxVal == r {
                h = (g - b) / delta
                if h < 0 { h += 6.0 }
            } else if maxVal == g {
                h = ((b - r) / delta) + 2.0
            } else {
                h = ((r - g) / delta) + 4.0
            }
            h /= 6.0
        }
        
        let s: Double = maxVal > 1e-5 ? (delta / maxVal) : 0
        let brightness: Double = maxVal
        return (h: h, s: s, b: brightness)
    }
    
    /// 將 HSB (0.0 ~ 1.0) 轉換為 RGB (0.0 ~ 1.0)
    public static func hsbToRgb(h: Double, s: Double, b: Double) -> (r: Double, g: Double, b: Double) {
        if s < 1e-5 {
            return (r: b, g: b, b: b)
        }
        let hSector = (h.truncatingRemainder(dividingBy: 1.0) + (h < 0 ? 1.0 : 0)) * 6.0
        let sectorIndex = Int(floor(hSector)) % 6
        let f = hSector - Double(sectorIndex)
        let p = b * (1.0 - s)
        let q = b * (1.0 - s * f)
        let t = b * (1.0 - s * (1.0 - f))
        
        switch sectorIndex {
        case 0: return (r: b, g: t, b: p)
        case 1: return (r: q, g: b, b: p)
        case 2: return (r: p, g: b, b: t)
        case 3: return (r: p, g: q, b: b)
        case 4: return (r: t, g: p, b: b)
        default: return (r: b, g: p, b: q)
        }
    }
    
    /// 將 Hex 字串轉換為 HSB (0.0 ~ 1.0)，失敗返回 nil
    public static func hexToHsb(_ hex: String) -> (h: Double, s: Double, b: Double)? {
        guard let rgb = hexToRgb(hex) else { return nil }
        return rgbToHsb(r: rgb.r, g: rgb.g, b: rgb.b)
    }
    
    /// 將 HSB (0.0 ~ 1.0) 轉換為 Hex 字串
    public static func hsbToHex(h: Double, s: Double, b: Double) -> String {
        let rgb = hsbToRgb(h: h, s: s, b: b)
        return rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
    }
}
