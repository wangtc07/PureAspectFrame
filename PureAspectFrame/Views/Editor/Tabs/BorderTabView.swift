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
                    
                    // 尺標大圖示 + 連結組與數值調整
                    HStack(alignment: .top, spacing: 16) {
                        // 1. 大圖示：包含上下左右示意（羅馬字 I / H），可直接點選各邊
                        PaddingBoxWidget(
                            selectedEdges: borderSettings.selectedEdges,
                            linkGroups: borderSettings.linkGroups,
                            isLinkedActive: borderSettings.isLinkedActive,
                            activeLinkSlot: borderSettings.activeLinkSlot,
                            onSelectEdge: { edge in
                                borderSettings.selectEdgeForAdjustment(edge)
                            },
                            onSelectAll: {
                                borderSettings.selectedEdges = Set(PaddingEdge.allCases)
                            }
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            // 2. 連結組 A / B（最多兩組）+ 連結編輯開關
                            HStack(spacing: 6) {
                                linkGroupChip(0)
                                linkGroupChip(1)
                                Spacer(minLength: 0)
                                
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        borderSettings.isLinkedActive.toggle()
                                    }
                                } label: {
                                    let on = borderSettings.isLinkedActive
                                    let color = LinkGroupStyle.color(borderSettings.activeLinkSlot)
                                    Image(systemName: on ? "checkmark" : "link.badge.plus")
                                        .font(.system(size: 14, weight: .semibold))
                                        .frame(width: 32, height: 28)
                                        .foregroundStyle(on ? Color.white : Color.primary)
                                        .background {
                                            Capsule().fill(on ? color : Color.primary.opacity(0.07))
                                        }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(borderSettings.isLinkedActive ? "完成編輯連結" : "編輯連結組")
                            }
                            
                            // 3. 狀態列：目前在編輯連結，或正在調整哪些邊
                            Text(statusText.text)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(statusText.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
                            // 4. 留白數值調整滑桿
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
    
    // MARK: - 連結組狀態顯示
    /// 邊集合的簡短名稱（上下左右順序；四邊 → 「四邊」）
    private func edgeNames(_ edges: Set<PaddingEdge>) -> String {
        if edges.count == 4 { return "四邊" }
        return [PaddingEdge.top, .bottom, .left, .right]
            .filter { edges.contains($0) }
            .map(\.rawValue)
            .joined()
    }
    
    /// 狀態列：明確說明目前處於「編輯連結」或「調整數值」，以及調整的是哪些邊
    private var statusText: (text: String, color: Color) {
        let slot = borderSettings.activeLinkSlot
        if borderSettings.isLinkedActive {
            return ("編輯連結 \(LinkGroupStyle.name(slot))：點選尺標加入／移除", LinkGroupStyle.color(slot))
        }
        let selected = borderSettings.selectedEdges
        let names = edgeNames(selected)
        if let first = selected.first, let idx = borderSettings.groupIndex(of: first),
           borderSettings.linkGroups[idx].count >= 2, borderSettings.linkGroups[idx] == selected {
            return ("調整 \(names)（連結 \(LinkGroupStyle.name(idx))）", LinkGroupStyle.color(idx))
        }
        if selected.count == 4 { return ("調整四邊", .secondary) }
        return ("調整 \(names)（單獨）", .secondary)
    }
    
    /// 連結組晶片：顯示 A / B 組目前成員。連結編輯模式下點選＝切換編輯中的組；一般模式下點選＝選取該組
    private func linkGroupChip(_ slot: Int) -> some View {
        let members = borderSettings.linkGroups[slot]
        let color = LinkGroupStyle.color(slot)
        let isEditingSlot = borderSettings.isLinkedActive && borderSettings.activeLinkSlot == slot
        let isEmpty = members.isEmpty
        return Button {
            if borderSettings.isLinkedActive {
                borderSettings.activeLinkSlot = slot
            } else if members.count >= 2 {
                borderSettings.selectedEdges = members
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "link")
                    .font(.system(size: 10, weight: .bold))
                Text("\(LinkGroupStyle.name(slot)) \(isEmpty ? "—" : edgeNames(members))")
                    .font(.caption.weight(.semibold))
            }
            .padding(.horizontal, 9)
            .frame(height: 28)
            .foregroundStyle(isEditingSlot ? Color.white : (isEmpty ? Color.secondary : color))
            .background {
                Capsule()
                    .fill(isEditingSlot ? color : color.opacity(isEmpty ? 0.06 : 0.14))
                    .overlay {
                        Capsule().strokeBorder(color.opacity(isEmpty ? 0.25 : 0.6),
                                               style: StrokeStyle(lineWidth: 1, dash: isEmpty ? [3, 2] : []))
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("連結組 \(LinkGroupStyle.name(slot))：\(isEmpty ? "未設定" : edgeNames(members))")
    }
}
