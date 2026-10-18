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
                    
                    // 連結模式與四邊邊界尺標大圖示調整列
                    HStack(spacing: 16) {
                        // 1. 大圖示：包含上下左右示意（羅馬字 I / H），可直接點選各邊
                        PaddingBoxWidget(
                            selectedEdges: borderSettings.selectedEdges,
                            linkedEdges: borderSettings.linkedEdges,
                            isLinkedActive: borderSettings.isLinkedActive,
                            onSelectEdge: { edge in
                                borderSettings.selectEdgeForAdjustment(edge)
                            },
                            onSelectAll: {
                                borderSettings.selectedEdges = Set(PaddingEdge.allCases)
                            }
                        )
                        
                        // 2. 數值滑桿與連結控制區
                        VStack(spacing: 8) {
                            HStack {
                                selectedEdgesDescription
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(borderSettings.isLinkedActive ? Color.accentColor : Color.secondary)
                                
                                Spacer()
                                
                                // 🔗 連結模式切換按鈕（純圖示）
                                Button {
                                    borderSettings.isLinkedActive.toggle()
                                } label: {
                                    Image(systemName: borderSettings.isLinkedActive ? "link.circle.fill" : "link")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 32, height: 26)
                                        .background {
                                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                                .fill(borderSettings.isLinkedActive ? Color.accentColor : Color.primary.opacity(0.06))
                                        }
                                        .foregroundStyle(borderSettings.isLinkedActive ? Color.white : Color.primary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(borderSettings.isLinkedActive ? "完成編輯連結" : "編輯四邊連結")
                            }
                            
                            // 留白數值調整滑桿
                            let activeEdge = borderSettings.selectedEdges.first ?? .top
                            let currentVal = borderSettings.padding(for: activeEdge)
                            let maxRange: CGFloat = borderSettings.unit == .percent ? 40 : 300
                            
                            HStack(spacing: 8) {
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
                            if case let .customHSB(h, s, b) = backgroundMode {
                                customH = h
                                customS = s
                                customB = b
                            }
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
                .onChange(of: customH) { _, newH in
                    backgroundMode = .customHSB(hue: newH, saturation: customS, brightness: customB)
                }
                .onChange(of: customS) { _, newS in
                    backgroundMode = .customHSB(hue: customH, saturation: newS, brightness: customB)
                }
                .onChange(of: customB) { _, newB in
                    backgroundMode = .customHSB(hue: customH, saturation: customS, brightness: newB)
                }
                .onDisappear {
                    backgroundMode = .customHSB(hue: customH, saturation: customS, brightness: customB)
                }
        }
    }
    
    // MARK: - 當前選中邊界說明
    private var selectedEdgesDescription: Text {
        if borderSettings.isLinkedActive {
            return Text("點選邊界加入/移除連結")
        }
        let selected = borderSettings.selectedEdges
        if selected.count == 4 {
            return Text("四邊連動調整")
        } else if selected.count == 2 && selected.contains(.top) && selected.contains(.bottom) {
            return Text("上下邊界")
        } else if selected.count == 2 && selected.contains(.left) && selected.contains(.right) {
            return Text("左右邊界")
        } else if let first = selected.first {
            return Text("\(first.rawValue)邊界")
        } else {
            return Text("四邊留白")
        }
    }
}
