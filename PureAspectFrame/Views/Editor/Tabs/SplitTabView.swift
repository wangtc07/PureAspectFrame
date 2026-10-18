import SwiftUI

/// 【切割】分頁視圖
public struct SplitTabView: View {
    @Binding var splitSettings: SplitSettings
    
    public init(splitSettings: Binding<SplitSettings>) {
        self._splitSettings = splitSettings
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. 橫向左右切割開關
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("橫向左右切割")
                                .font(.headline)
                            Text("將長圖或全景畫布無縫切成多張以供 SNS 輪播發布")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $splitSettings.isEnabled)
                            .labelsHidden()
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                
                if splitSettings.isEnabled {
                    // 2. 切割張數選擇 (2 ~ 10 張)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("切割張數")
                                .font(.headline)
                            Spacer()
                            Text("\(splitSettings.splitCount) 張")
                                .font(.subheadline.monospaced().bold())
                        }
                        
                        // 2, 3, 4, 5 張快捷鍵
                        HStack(spacing: 8) {
                            ForEach([2, 3, 4, 5], id: \.self) { count in
                                Button {
                                    splitSettings.splitCount = count
                                } label: {
                                    Text("\(count) 張")
                                        .font(.caption.bold())
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                        .background {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(splitSettings.splitCount == count ? Color.accentColor : Color.primary.opacity(0.06))
                                        }
                                        .foregroundStyle(splitSettings.splitCount == count ? Color.white : Color.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // 2 ~ 10 張滑桿微調
                        HStack(spacing: 12) {
                            Slider(
                                value: Binding(
                                    get: { Double(splitSettings.splitCount) },
                                    set: { splitSettings.splitCount = Int($0) }
                                ),
                                in: 2...10,
                                step: 1
                            )
                        }
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                    
                    // 3. 兩圖間隙調整與平台預設
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("兩圖間隙 (Gap)")
                                .font(.headline)
                            Spacer()
                            EditableNumberBadge(
                                value: $splitSettings.gapPx,
                                unit: "px",
                                range: 0...50
                            )
                        }
                        
                        // 平台預設快速套用
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SplitPlatformPreset.allCases) { p in
                                    Button {
                                        splitSettings.preset = p
                                        if p != .custom {
                                            splitSettings.gapPx = p.defaultGapPx
                                        }
                                    } label: {
                                        Text(p.rawValue)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background {
                                                Capsule()
                                                    .fill(splitSettings.preset == p ? Color.accentColor : Color.primary.opacity(0.06))
                                            }
                                            .foregroundStyle(splitSettings.preset == p ? Color.white : Color.primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        // 間隙滑桿
                        HStack(spacing: 12) {
                            Slider(value: $splitSettings.gapPx, in: 0...50, step: 1)
                        }
                    }
                    .padding()
                    .liquidGlass(cornerRadius: 16)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
