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
    #endif
}
