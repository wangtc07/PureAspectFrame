import SwiftUI

/// 相容性導向：轉接至 Chrome.swift 之 iOS 26 原生 Liquid Glass 實作
public struct LiquidGlassLegacyModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var isInteractive: Bool = true
    
    public func body(content: Content) -> some View {
        content.liquidGlass(cornerRadius: cornerRadius, interactive: isInteractive)
    }
}
