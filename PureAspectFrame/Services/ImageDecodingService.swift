import Foundation
import CoreGraphics
import ImageIO

/// 提供基於 ImageIO 的高質量方向轉正、硬體加速降採樣縮圖與影像元資料探勘服務
public final class ImageDecodingService: Sendable {
    
    /// 依據圖片的 EXIF Orientation 幾何方向建立轉正後的 CGImage
    /// - Parameters:
    ///   - data: 原始圖片 Data
    ///   - maxPixelSize: 可選的最大邊長像素（若提供則在解碼時利用 ImageIO 進行硬體降採樣，顯著節省記憶體並加速顯示；若為 nil 則輸出完整解析度之轉正圖檔）
    /// - Returns: 轉正後的 CGImage，若解碼失敗則回傳 nil
    public static func createOrientedCGImage(from data: Data, maxPixelSize: CGFloat? = nil) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        var options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        
        if let maxPixelSize = maxPixelSize, maxPixelSize > 0 {
            options[kCGImageSourceThumbnailMaxPixelSize] = maxPixelSize
        } else {
            // 當未指定 maxPixelSize 時，檢驗圖片原始物理長寬之最大值，確保以最大邊長輸出完整解析度並套用 transform 轉正
            if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
               let width = properties[kCGImagePropertyPixelWidth as String] as? CGFloat,
               let height = properties[kCGImagePropertyPixelHeight as String] as? CGFloat {
                let maxDimension = max(width, height)
                if maxDimension > 0 {
                    options[kCGImageSourceThumbnailMaxPixelSize] = maxDimension
                }
            }
        }
        
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
    
    /// 快速檢驗圖片方向與物理尺寸（不加載完整點陣圖至記憶體）
    public static func inspectImage(from data: Data) -> (orientation: UInt32, pixelSize: CGSize)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        
        let orientation = (properties[kCGImagePropertyOrientation as String] as? UInt32) ?? 1
        let width = (properties[kCGImagePropertyPixelWidth as String] as? CGFloat) ?? 0
        let height = (properties[kCGImagePropertyPixelHeight as String] as? CGFloat) ?? 0
        
        return (orientation: orientation, pixelSize: CGSize(width: width, height: height))
    }
}
