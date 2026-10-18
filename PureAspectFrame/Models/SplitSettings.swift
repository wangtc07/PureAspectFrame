import Foundation
import CoreGraphics

/// 切割預設平台間隙規範
public enum SplitPlatformPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case custom = "自訂"
    case igCarousel = "IG 輪播 (無縫 0px)"
    case threads = "Threads (4px)"
    case xTwitter = "X / Twitter (8px)"
    
    public var id: String { rawValue }
    
    public var defaultGapPx: CGFloat {
        switch self {
        case .custom: return 0
        case .igCarousel: return 0
        case .threads: return 4
        case .xTwitter: return 8
        }
    }
}

/// 橫向左右切割設定與切割演算法
public struct SplitSettings: Codable, Equatable, Sendable {
    /// 是否啟用左右切割模式
    public var isEnabled: Bool = false
    
    /// 切割張數 (2 ~ 10)
    public var splitCount: Int = 2 {
        didSet {
            if splitCount < 2 { splitCount = 2 }
            if splitCount > 10 { splitCount = 10 }
        }
    }
    
    /// 兩圖間隙 (px)
    public var gapPx: CGFloat = 0
    
    /// 套用之預設平台
    public var preset: SplitPlatformPreset = .custom
    
    public init() {}
    
    /// 計算總畫布分割為 N 張後的各片裁切範圍 (CGRect)
    public func calculateSlices(totalWidth: CGFloat, totalHeight: CGFloat) -> [CGRect] {
        guard splitCount > 0 else { return [] }
        if splitCount == 1 {
            return [CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight)]
        }
        
        let count = CGFloat(splitCount)
        let totalGaps = (count - 1) * gapPx
        let availableWidth = max(0, totalWidth - totalGaps)
        let sliceWidth = availableWidth / count
        
        var slices: [CGRect] = []
        var currentX: CGFloat = 0
        
        for _ in 0..<splitCount {
            slices.append(CGRect(x: currentX, y: 0, width: sliceWidth, height: totalHeight))
            currentX += sliceWidth + gapPx
        }
        
        return slices
    }
}
