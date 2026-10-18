import Foundation
import CoreGraphics
#if canImport(SwiftUI)
import SwiftUI
#endif

/// 畫布背景模式（黑、白、自訂 HSB、毛玻璃）
public enum BackgroundMode: Codable, Equatable, Sendable {
    case black
    case white
    case customHSB(hue: Double, saturation: Double, brightness: Double)
    case frostedGlass(blurRadius: Double)
    
    public var isFrosted: Bool {
        if case .frostedGlass = self { return true }
        return false
    }
    
    public var blurRadius: Double? {
        if case let .frostedGlass(radius) = self { return radius }
        return nil
    }
    
    #if canImport(SwiftUI)
    public var swiftUIColor: Color {
        switch self {
        case .black:
            return .black
        case .white:
            return .white
        case let .customHSB(h, s, b):
            return Color(hue: h, saturation: s, brightness: b)
        case .frostedGlass:
            return .clear
        }
    }
    
    /// 預覽舞台預設深灰底色 Color (R: 28, G: 28, B: 30, #1C1C1E)
    public static let stageDarkColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)
    /// 預覽舞台動態切換之淺灰底色 Color (R: 245, G: 245, B: 245, #F5F5F5)
    public static let stageLightColor = Color(red: 245 / 255.0, green: 245 / 255.0, blue: 245 / 255.0)
    
    /// 預覽舞台自適應背景顏色
    public var stageBackgroundColor: Color {
        isDarkOrNearDarkGray ? Self.stageLightColor : Self.stageDarkColor
    }
    #endif
    
    // MARK: - 舞台預覽自適應背景色 (對比度優化)
    
    /// 預設預覽深灰底色十六進制碼：#1C1C1E (R: 28, G: 28, B: 30)
    public static let defaultStageDarkHex = "#1C1C1E"
    /// 遇深色動態切換之淺灰底色十六進制碼：#F5F5F5 (R: 245, G: 245, B: 245)
    public static let dynamicStageLightHex = "#F5F5F5"
    
    /// 判斷畫布背景是否為黑色、比 #1C1C1E 更深或接近深灰
    public var isDarkOrNearDarkGray: Bool {
        switch self {
        case .black:
            return true
        case .white:
            return false
        case let .customHSB(h, s, b):
            let luminance = Self.computeLuminance(h: h, s: s, b: b)
            // 當相對感知亮度 <= 0.38 時視為深色或接近深灰
            return luminance <= 0.38
        case .frostedGlass:
            return false
        }
    }
    
    /// 預覽舞台背景色之十六進制字串（用於除錯與測試驗證）
    public var stageBackgroundColorHex: String {
        isDarkOrNearDarkGray ? Self.dynamicStageLightHex : Self.defaultStageDarkHex
    }
    
    /// 計算 HSB 顏色之相對感知亮度 (Relative Luminance, 0.0 ~ 1.0)
    public static func computeLuminance(h: Double, s: Double, b: Double) -> Double {
        let c = b * s
        let x = c * (1.0 - abs((h * 6.0).truncatingRemainder(dividingBy: 2.0) - 1.0))
        let m = b - c
        
        let sector = Int((h * 6.0).truncatingRemainder(dividingBy: 6.0))
        let (rPrime, gPrime, bPrime): (Double, Double, Double) = {
            switch sector {
            case 0: return (c, x, 0)
            case 1: return (x, c, 0)
            case 2: return (0, c, x)
            case 3: return (0, x, c)
            case 4: return (x, 0, c)
            default: return (c, 0, x)
            }
        }()
        
        let r = rPrime + m
        let g = gPrime + m
        let bVal = bPrime + m
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * bVal
    }
}
