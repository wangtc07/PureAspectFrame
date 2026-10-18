import Foundation
import CoreGraphics
import ImageIO

/// 提供透過 ImageIO 從相片 Data 或屬性字典提取完整 EXIF / TIFF / MakerNote 資訊的服務
public final class ExifParserService: Sendable {
    
    /// 從 CGImageSource 或屬性字典中解析 EXIF 元資料
    public static func parse(properties: [String: Any]) -> ExifMetadata {
        var metadata = ExifMetadata()
        
        let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        
        // 1. TIFF 屬性: Make, Model, DateTime
        if let make = tiff?[kCGImagePropertyTIFFMake as String] as? String {
            metadata.make = make.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let model = tiff?[kCGImagePropertyTIFFModel as String] as? String {
            metadata.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 2. EXIF 屬性: 鏡頭、焦距、光圈、快門、ISO、拍攝時間
        if let lens = exif?[kCGImagePropertyExifLensModel as String] as? String {
            metadata.lensModel = lens.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let focalLength = exif?[kCGImagePropertyExifFocalLength as String] as? NSNumber {
            metadata.focalLength = focalLength.doubleValue
        } else if let focalLength = exif?[kCGImagePropertyExifFocalLength as String] as? Double {
            metadata.focalLength = focalLength
        }
        
        if let focal35 = exif?[kCGImagePropertyExifFocalLenIn35mmFilm as String] as? NSNumber {
            metadata.focalLengthIn35mm = focal35.doubleValue
        }
        
        if let fNumber = exif?[kCGImagePropertyExifFNumber as String] as? NSNumber {
            metadata.fNumber = fNumber.doubleValue
        } else if let fNumber = exif?[kCGImagePropertyExifFNumber as String] as? Double {
            metadata.fNumber = fNumber
        }
        
        if let expTime = exif?[kCGImagePropertyExifExposureTime as String] as? NSNumber {
            let seconds = expTime.doubleValue
            if seconds > 0 {
                if seconds < 1.0 {
                    let denom = Int((1.0 / seconds).rounded())
                    metadata.shutterSpeed = "1/\(denom)"
                } else if seconds.truncatingRemainder(dividingBy: 1) == 0 {
                    metadata.shutterSpeed = "\(Int(seconds))"
                } else {
                    metadata.shutterSpeed = String(format: "%.1f", seconds)
                }
            }
        } else if let expTime = exif?[kCGImagePropertyExifExposureTime as String] as? Double {
            if expTime > 0 {
                if expTime < 1.0 {
                    let denom = Int((1.0 / expTime).rounded())
                    metadata.shutterSpeed = "1/\(denom)"
                } else {
                    metadata.shutterSpeed = "\(expTime)"
                }
            }
        }
        
        if let isoRatings = exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [NSNumber], let first = isoRatings.first {
            metadata.iso = first.intValue
        } else if let isoRatings = exif?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int], let first = isoRatings.first {
            metadata.iso = first
        } else if let iso = exif?[kCGImagePropertyExifISOSpeedRatings as String] as? NSNumber {
            metadata.iso = iso.intValue
        }
        
        return metadata
    }
    
    /// 從圖片二進制 Data 解析 EXIF
    public static func parse(imageData: Data) -> ExifMetadata {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return ExifMetadata()
        }
        return parse(properties: properties)
    }
}
