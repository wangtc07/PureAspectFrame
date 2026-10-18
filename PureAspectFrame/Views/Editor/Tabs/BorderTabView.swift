import SwiftUI

/// 【邊框】分頁視圖
public struct BorderTabView: View {
    @Binding var borderSettings: BorderSettings
    @Binding var backgroundMode: BackgroundMode
    
    @State private var showingHSBPicker: Bool = false
    @State private var customH: Double = 0.0
    @State private var customS: Double = 0.0
    @State private var customB: Double = 0.95
    @State private var frostedBlur: Double = 25.0
    
    public init(
        borderSettings: Binding<BorderSettings>,
        backgroundMode: Binding<BackgroundMode>
    ) {
        self._borderSettings = borderSettings
        self._backgroundMode = backgroundMode
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. 留白控制與持久化連結
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("四邊留白")
                            .font(.headline)
                        Spacer()
                        // 單位切換 (% / px)
                        Picker("單位", selection: $borderSettings.unit) {
                            Text("%").tag(MeasurementUnit.percent)
                            Text("px").tag(MeasurementUnit.pixel)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 90)
                    }
                    
                    // 連結模式與四邊指示鈕
                    HStack(spacing: 8) {
                        // 🔗 連結編輯模式切換鈕
                        Button {
                            borderSettings.isLinkedActive.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: borderSettings.isLinkedActive ? "link.circle.fill" : "link")
                                Text(borderSettings.isLinkedActive ? "編輯連結中" : "🔗 連結")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background {
                                Capsule()
                                    .fill(borderSettings.isLinkedActive ? Color.accentColor : Color.primary.opacity(0.08))
                            }
                            .foregroundStyle(borderSettings.isLinkedActive ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // 四邊圖示加選/選中狀態
                        ForEach(PaddingEdge.allCases) { edge in
                            let isLinked = borderSettings.linkedEdges.contains(edge)
                            let isSelected = borderSettings.selectedEdges.contains(edge)
                            
                            Button {
                                borderSettings.selectEdgeForAdjustment(edge)
                            } label: {
                                VStack(spacing: 2) {
                                    Text(edge.rawValue)
                                        .font(.caption2.bold())
                                    if isLinked {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(width: 38, height: 32)
                                .background {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.primary.opacity(0.05))
                                        .overlay {
                                            if isSelected {
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .strokeBorder(Color.blue, lineWidth: 1.5)
                                            }
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // 留白數值調整滑桿
                    let activeEdge = borderSettings.selectedEdges.first ?? .top
                    let currentVal = borderSettings.padding(for: activeEdge)
                    let maxRange: CGFloat = borderSettings.unit == .percent ? 40 : 300
                    
                    HStack(spacing: 12) {
                        Slider(
                            value: Binding(
                                get: { currentVal },
                                set: { borderSettings.updatePadding(for: activeEdge, value: $0) }
                            ),
                            in: 0...maxRange
                        )
                        
                        EditableNumberBadge(
                            value: Binding(
                                get: { currentVal },
                                set: { borderSettings.updatePadding(for: activeEdge, value: $0) }
                            ),
                            unit: borderSettings.unit.rawValue,
                            range: 0...maxRange
                        )
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                
                // 2. 背景模式 (黑 / 白 / 自訂 / 毛玻璃)
                VStack(alignment: .leading, spacing: 12) {
                    Text("背景外觀")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        // 白
                        Button {
                            backgroundMode = .white
                        } label: {
                            HStack {
                                Circle().fill(Color.white).frame(width: 14, height: 14).overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                                Text("白").font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(backgroundMode == .white ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                        
                        // 黑
                        Button {
                            backgroundMode = .black
                        } label: {
                            HStack {
                                Circle().fill(Color.black).frame(width: 14, height: 14)
                                Text("黑").font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(backgroundMode == .black ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                        
                        // 自訂
                        Button {
                            showingHSBPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "paintpalette.fill").font(.caption)
                                Text("自訂").font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(
                                {
                                    if case .customHSB = backgroundMode { return Color.accentColor.opacity(0.2) }
                                    return Color.primary.opacity(0.05)
                                }()
                            ))
                        }
                        .buttonStyle(.plain)
                        
                        // 毛玻璃
                        Button {
                            backgroundMode = .frostedGlass(blurRadius: frostedBlur)
                        } label: {
                            HStack {
                                Image(systemName: "sparkles").font(.caption)
                                Text("毛玻璃").font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(RoundedRectangle(cornerRadius: 10).fill(
                                {
                                    if case .frostedGlass = backgroundMode { return Color.accentColor.opacity(0.2) }
                                    return Color.primary.opacity(0.05)
                                }()
                            ))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if case .frostedGlass = backgroundMode {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("模糊程度")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.0f px", frostedBlur))
                                    .font(.caption.monospaced())
                            }
                            Slider(value: $frostedBlur, in: 5...60) { _ in
                                backgroundMode = .frostedGlass(blurRadius: frostedBlur)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                
                // 3. 相片圓角
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("相片圓角")
                            .font(.headline)
                        Spacer()
                        Picker("單位", selection: $borderSettings.cornerRadiusUnit) {
                            Text("%").tag(MeasurementUnit.percent)
                            Text("px").tag(MeasurementUnit.pixel)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 90)
                    }
                    
                    let maxRadius: CGFloat = borderSettings.cornerRadiusUnit == .percent ? 50 : 100
                    HStack(spacing: 12) {
                        Slider(value: $borderSettings.cornerRadius, in: 0...maxRadius)
                        
                        EditableNumberBadge(
                            value: $borderSettings.cornerRadius,
                            unit: borderSettings.cornerRadiusUnit.rawValue,
                            range: 0...maxRadius
                        )
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $showingHSBPicker) {
            HSBColorPickerView(hue: $customH, saturation: $customS, brightness: $customB)
                .onDisappear {
                    backgroundMode = .customHSB(hue: customH, saturation: customS, brightness: customB)
                }
        }
    }
}
