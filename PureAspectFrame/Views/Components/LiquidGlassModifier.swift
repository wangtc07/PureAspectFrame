import SwiftUI

/// Apple 原生風格 Liquid Glass 毛玻璃修飾器
public struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var isInteractive: Bool = true
    
    public func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
            }
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 16, isInteractive: Bool = true) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius, isInteractive: isInteractive))
    }
}
