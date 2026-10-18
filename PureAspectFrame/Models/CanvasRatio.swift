import Foundation
import CoreGraphics

/// 畫布外部比例列舉（包含一般 SNS 比例與拍立得三大實體規格）
public enum CanvasRatio: String, CaseIterable, Identifiable, Codable, Sendable {
    case ig4x5 = "4:5 (IG)"
    case square1x1 = "1:1"
    case xhs3x4 = "3:4 (小紅書)"
    case story9x16 = "9:16 (Story)"
    case landscape16x9 = "16:9"
    case polaroidMini = "Mini (54×86)"
    case polaroidSquare = "Square (72×86)"
    case polaroidWide = "Wide (108×86)"
    
    public var id: String { rawValue }
    
    /// 寬除以高之寬高比 (Width / Height)
    public var aspectRatio: CGFloat {
        switch self {
        case .ig4x5:
            return 4.0 / 5.0
        case .square1x1:
            return 1.0
        case .xhs3x4:
            return 3.0 / 4.0
        case .story9x16:
            return 9.0 / 16.0
        case .landscape16x9:
            return 16.0 / 9.0
        case .polaroidMini:
            return 54.0 / 86.0
        case .polaroidSquare:
            return 72.0 / 86.0
        case .polaroidWide:
            return 108.0 / 86.0
        }
    }
    
    /// 是否為拍立得規格
    public var isPolaroid: Bool {
        switch self {
        case .polaroidMini, .polaroidSquare, .polaroidWide:
            return true
        default:
            return false
        }
    }
    
    /// 計算給定基準寬度下的畫布像素尺寸
    public func targetPixelSize(baseWidth: CGFloat = 1080) -> CGSize {
        let height = (baseWidth / aspectRatio).rounded()
        return CGSize(width: baseWidth, height: height)
    }
}

/// 照片內部裁切比例
public enum InternalCropRatio: String, CaseIterable, Identifiable, Codable, Sendable {
    case free = "自由"
    case square1x1 = "1:1"
    case r4x5 = "4:5"
    case r3x2 = "3:2"
    case r16x9 = "16:9"
    
    public var id: String { rawValue }
    
    public var ratioValue: CGFloat? {
        switch self {
        case .free:
            return nil
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
