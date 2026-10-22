import Foundation
import CoreGraphics

/// 畫布外部比例列舉（包含原圖比例、一般 SNS 比例與拍立得三大實體規格）
public enum CanvasRatio: String, CaseIterable, Identifiable, Codable, Sendable {
    case original = "原圖比例"
    case ig4x5 = "4:5 (IG)"
    case square1x1 = "1:1"
    case xhs3x4 = "3:4 (小紅書)"
    case story9x16 = "9:16 (Story)"
    case landscape16x9 = "16:9"
    case polaroidMini = "Mini (54×86)"
    case polaroidSquare = "Square (72×86)"
    case polaroidWide = "Wide (108×86)"
    
    public var id: String { rawValue }
    
    /// 依橫直式切換動態顯示標題
    public func displayName(isLandscape: Bool) -> String {
        switch self {
        case .original:
            return "原圖比例"
        case .ig4x5:
            return isLandscape ? "5:4 (IG)" : "4:5 (IG)"
        case .square1x1:
            return "1:1"
        case .xhs3x4:
            return isLandscape ? "4:3 (小紅書)" : "3:4 (小紅書)"
        case .story9x16:
            return isLandscape ? "16:9 (Story)" : "9:16 (Story)"
        case .landscape16x9:
            return isLandscape ? "16:9" : "9:16"
        case .polaroidMini:
            return isLandscape ? "Mini (86×54)" : "Mini (54×86)"
        case .polaroidSquare:
            return isLandscape ? "Square (86×72)" : "Square (72×86)"
        case .polaroidWide:
            return isLandscape ? "Wide (108×86)" : "Wide (86×108)"
        }
    }
    
    /// 寬除以高之寬高比 (Width / Height)，支援橫直式與相片比例自適應
    public func aspectRatio(isLandscape: Bool = false, photoAspectRatio: CGFloat = 1.0) -> CGFloat {
        switch self {
        case .original:
            let baseAspect = max(0.01, photoAspectRatio)
            if isLandscape {
                return max(baseAspect, 1.0 / baseAspect)
            } else {
                return min(baseAspect, 1.0 / baseAspect)
            }
        case .ig4x5:
            return isLandscape ? (5.0 / 4.0) : (4.0 / 5.0)
        case .square1x1:
            return 1.0
        case .xhs3x4:
            return isLandscape ? (4.0 / 3.0) : (3.0 / 4.0)
        case .story9x16:
            return isLandscape ? (16.0 / 9.0) : (9.0 / 16.0)
        case .landscape16x9:
            return isLandscape ? (16.0 / 9.0) : (9.0 / 16.0)
        case .polaroidMini:
            return isLandscape ? (86.0 / 54.0) : (54.0 / 86.0)
        case .polaroidSquare:
            return isLandscape ? (86.0 / 72.0) : (72.0 / 86.0)
        case .polaroidWide:
            return isLandscape ? (108.0 / 86.0) : (86.0 / 108.0)
        }
    }
    
    /// 計算給定基準寬度下的畫布像素尺寸（支援橫直式與原圖比例）
    public func targetPixelSize(
        baseWidth: CGFloat = 1080,
        isLandscape: Bool = false,
        photoAspectRatio: CGFloat = 1.0
    ) -> CGSize {
        let aspect = aspectRatio(isLandscape: isLandscape, photoAspectRatio: photoAspectRatio)
        let height = (baseWidth / aspect).rounded()
        return CGSize(width: baseWidth, height: height)
    }
}

/// 照片內部裁切比例（已刪除「自由」）
public enum InternalCropRatio: String, CaseIterable, Identifiable, Codable, Sendable {
    case square1x1 = "1:1"
    case r4x5 = "4:5"
    case r3x2 = "3:2"
    case r16x9 = "16:9"
    
    public init?(rawValue: String) {
        switch rawValue {
        case "1:1": self = .square1x1
        case "4:5": self = .r4x5
        case "3:2": self = .r3x2
        case "16:9": self = .r16x9
        case "自由": self = .square1x1
        default: return nil
        }
    }
    
    public var id: String { rawValue }
    
    public var ratioValue: CGFloat {
        switch self {
        case .square1x1:
            return 1.0
        case .r4x5:
            return 4.0 / 5.0
        case .r3x2:
            return 3.0 / 2.0
        case .r16x9:
            return 16.0 / 9.0
        }
    }
}
