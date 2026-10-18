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

// MARK: - 工具列標準圖示按鈕 (比照 ChekiLens: xmark 與 checkmark)

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
                .font(.system(size: 16, weight: .semibold))
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
                .font(.system(size: 16, weight: .semibold))
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
