import SwiftUI

// MARK: - 尺寸常數（全 App 遵照 Apple HIG 與 ChekiLens 設計風格）

public enum ChromeMetrics {
    public static let circle: CGFloat = 44
    public static let capsuleHeight: CGFloat = 44
    public static let iconPointSize: CGFloat = 17
    public static let capsuleHPadding: CGFloat = 16
    public static let edgeHorizontal: CGFloat = 16
    public static let edgeBottom: CGFloat = 12
    public static let groupSpacing: CGFloat = 12
}

public enum ChromeInk {
    case primary
    case white
    case secondary

    public var color: Color {
        switch self {
        case .primary: return .primary
        case .white: return .white
        case .secondary: return .secondary
        }
    }
}

public enum ChromeFallbackStroke {
    case primary
    case white

    public var color: Color {
        switch self {
        case .primary: return .primary.opacity(0.14)
        case .white: return .white.opacity(0.16)
        }
    }
}

// MARK: - iOS 26 原生透明液態玻璃修飾器 (Liquid Glass)

private struct ChromeInkModifier: ViewModifier {
    var ink: ChromeInk?

    func body(content: Content) -> some View {
        if let ink {
            content.foregroundStyle(ink.color).tint(ink.color)
        } else {
            content
        }
    }
}

private struct OptionalHorizontalPadding: ViewModifier {
    var padding: CGFloat?

    func body(content: Content) -> some View {
        if let padding {
            content.padding(.horizontal, padding)
        } else {
            content
        }
    }
}

private struct OptionalFixedHeight: ViewModifier {
    var height: CGFloat?

    func body(content: Content) -> some View {
        if let height {
            content.frame(height: height)
        } else {
            content
        }
    }
}

private struct LiquidGlassCircleModifier: ViewModifier {
    var size: CGFloat
    var ink: ChromeInk?
    var fallbackStroke: ChromeFallbackStroke

    func body(content: Content) -> some View {
        let framed = content
            .modifier(ChromeInkModifier(ink: ink))
            .frame(width: size, height: size)
        if #available(iOS 26.0, *) {
            framed
                .contentShape(Circle())
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            framed
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(fallbackStroke.color, lineWidth: 0.6))
        }
    }
}

private struct LiquidGlassCapsuleModifier: ViewModifier {
    var height: CGFloat?
    var horizontalPadding: CGFloat?
    var ink: ChromeInk?
    var interactive: Bool
    var fallbackStroke: ChromeFallbackStroke

    func body(content: Content) -> some View {
        let framed = content
            .modifier(ChromeInkModifier(ink: ink))
            .modifier(OptionalHorizontalPadding(padding: horizontalPadding))
            .modifier(OptionalFixedHeight(height: height))
        if #available(iOS 26.0, *) {
            if interactive {
                framed
                    .contentShape(Capsule())
                    .glassEffect(.regular.interactive(), in: .capsule)
            } else {
                framed.glassEffect(.regular, in: .capsule)
            }
        } else {
            framed
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(fallbackStroke.color, lineWidth: 0.6))
        }
    }
}

private struct LiquidGlassRoundedRectModifier: ViewModifier {
    var cornerRadius: CGFloat
    var interactive: Bool
    var fallbackStroke: ChromeFallbackStroke

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).strokeBorder(fallbackStroke.color, lineWidth: 0.6))
        }
    }
}

public extension View {
    func liquidGlassCircle(
        size: CGFloat = ChromeMetrics.circle,
        ink: ChromeInk? = nil,
        fallbackStroke: ChromeFallbackStroke = .primary
    ) -> some View {
        modifier(LiquidGlassCircleModifier(size: size, ink: ink, fallbackStroke: fallbackStroke))
    }

    func liquidGlassCapsule(
        height: CGFloat? = ChromeMetrics.capsuleHeight,
        horizontalPadding: CGFloat? = ChromeMetrics.capsuleHPadding,
        ink: ChromeInk? = nil,
        interactive: Bool = true,
        fallbackStroke: ChromeFallbackStroke = .primary
    ) -> some View {
        modifier(
            LiquidGlassCapsuleModifier(
                height: height,
                horizontalPadding: horizontalPadding,
                ink: ink,
                interactive: interactive,
                fallbackStroke: fallbackStroke
            )
        )
    }

    func liquidGlass(
        cornerRadius: CGFloat = 16,
        interactive: Bool = true,
        fallbackStroke: ChromeFallbackStroke = .primary
    ) -> some View {
        modifier(
            LiquidGlassRoundedRectModifier(
                cornerRadius: cornerRadius,
                interactive: interactive,
                fallbackStroke: fallbackStroke
            )
        )
    }
}

// MARK: - 共用透明玻璃按鈕元件

public struct ChromeCircleButton: View {
    public let systemName: String
    public var ink: ChromeInk = .primary
    public var accessibilityLabel: String
    public let action: () -> Void

    public init(
        systemName: String,
        ink: ChromeInk = .primary,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.ink = ink
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                .liquidGlassCircle(size: ChromeMetrics.circle, ink: ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

public struct ChromeCapsuleButton<Label: View>: View {
    public var ink: ChromeInk = .primary
    public var accessibilityLabel: String
    public let action: () -> Void
    @ViewBuilder public var label: () -> Label

    public init(
        ink: ChromeInk = .primary,
        accessibilityLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.ink = ink
        self.accessibilityLabel = accessibilityLabel
        self.action = action
        self.label = label
    }

    public var body: some View {
        Button(action: action) {
            label()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .liquidGlassCapsule(
                    height: ChromeMetrics.capsuleHeight,
                    horizontalPadding: ChromeMetrics.capsuleHPadding,
                    ink: ink
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 工具列標準圖示按鈕 (比照 ChekiLens: xmark 與 checkmark，由系統工具列原生渲染玻璃底與邊緣，避免雙重邊框)

public struct CloseToolbarButton: View {
    public var accessibilityLabel: String = "取消"
    public let action: () -> Void

    public init(accessibilityLabel: String = "取消", action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

public struct ConfirmToolbarButton: View {
    public var accessibilityLabel: String = "完成"
    public let action: () -> Void

    public init(accessibilityLabel: String = "完成", action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - iOS 系統設定行標籤 (彩色圓角方塊圖示 + 標題與副標題)

public struct SettingsRowLabel: View {
    public let title: String
    public let subtitle: String?
    public let systemImage: String
    public let iconColor: Color

    public init(title: String, subtitle: String? = nil, systemImage: String, iconColor: Color) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.iconColor = iconColor
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconColor.gradient)
                    .frame(width: 28, height: 28)
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
