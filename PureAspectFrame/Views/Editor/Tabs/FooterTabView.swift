import SwiftUI
import SwiftData

/// 【底欄】分頁視圖
public struct FooterTabView: View {
    @Binding var footerSettings: FooterSettings
    @Binding var exifMetadata: ExifMetadata
    
    @Query private var manualLenses: [ManualLens]
    @Environment(\.modelContext) private var modelContext
    
    public enum FooterActiveSheet: String, Identifiable {
        case addLens
        case lensPicker
        case textColorPicker
        
        public var id: String { rawValue }
    }
    
    @State private var activeSheet: FooterActiveSheet? = nil
    @State private var newLensName: String = ""
    @State private var newLensFocal: String = "50"
    @State private var newLensAperture: String = "1.4"
    
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var layoutRevision: Int = 0
    
    // 文字顏色色彩選擇器狀態
    @State private var textH: Double = 0.0
    @State private var textS: Double = 0.0
    @State private var textB: Double = 0.58
    
    public init(
        footerSettings: Binding<FooterSettings>,
        exifMetadata: Binding<ExifMetadata>
    ) {
        self._footerSettings = footerSettings
        self._exifMetadata = exifMetadata
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                // 1. 底欄總開關與字體大小 (精簡單列)
                HStack(spacing: 10) {
                    Toggle("相片資訊底欄", isOn: $footerSettings.isEnabled)
                        .font(.subheadline.bold())
                        .fixedSize(horizontal: true, vertical: false)
                    
                    if footerSettings.isEnabled {
                        Spacer(minLength: 4)
                        HStack(spacing: 6) {
                            Text("字級")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: true, vertical: false)
                            Slider(value: $footerSettings.fontSizePt, in: FooterSettings.fontSizePtRange)
                                .frame(maxWidth: 96)
                            Text(String(format: "%.1f pt", footerSettings.fontSizePt))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .liquidGlass(cornerRadius: 14)
                
                if footerSettings.isEnabled {
                    // 2. 文字顏色選擇列 (預設灰色，支援黑、白與自訂顏色選擇器)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("文字顏色")
                                .font(.subheadline.bold())
                            Spacer()
                            Text(footerSettings.textColorHex)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            // 灰 (預設)
                            colorOptionButton(
                                title: "灰 (預設)",
                                color: Color(hex: "#8E8E93"),
                                isSelected: isTextColorPreset("#8E8E93")
                            ) {
                                footerSettings.textColorHex = "#8E8E93"
                            }
                            
                            // 黑
                            colorOptionButton(
                                title: "黑",
                                color: Color(hex: "#1C1C1E"),
                                isSelected: isTextColorPreset("#1C1C1E") || isTextColorPreset("#000000")
                            ) {
                                footerSettings.textColorHex = "#1C1C1E"
                            }
                            
                            // 白
                            colorOptionButton(
                                title: "白",
                                color: Color.white,
                                isSelected: isTextColorPreset("#FFFFFF")
                            ) {
                                footerSettings.textColorHex = "#FFFFFF"
                            }
                            
                            // 自訂 (打開 HSB/RGB/Hex 色彩選擇器)
                            Button {
                                prepareTextColorPicker()
                                activeSheet = .textColorPicker
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: footerSettings.textColorHex))
                                        .frame(width: 12, height: 12)
                                        .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 0.5))
                                    Image(systemName: "paintpalette.fill")
                                        .font(.system(size: 10))
                                    Text("自訂")
                                        .font(.caption.bold())
                                }
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .contentShape(RoundedRectangle(cornerRadius: 10))
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isCustomColorSelected ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("footer_text_color_custom")
                        }
                    }
                    .padding(10)
                    .liquidGlass(cornerRadius: 14)
                    
                    // 3. 當前底欄啟用之積木 (左右排列、拖動重排與長按互動)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("底欄已啟用積木")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("按住拖曳或點箭頭換順序")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if footerSettings.activeItems.isEmpty {
                            Text("尚未加入任何底欄積木，請由下方倉庫點選加入")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                let cardItems = footerSettings.activeItems.enumerated().map {
                                    ActiveCardItem(
                                        id: "\(layoutRevision)_\($0.offset)_\($0.element.rawValue)",
                                        index: $0.offset,
                                        item: $0.element
                                    )
                                }
                                HStack(spacing: 8) {
                                    ForEach(cardItems) { card in
                                        activeCardView(card: card)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            
                            // 排版模式即時反饋
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                    .foregroundStyle(Color.accentColor)
                                Text(currentAlignmentDescription)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(10)
                    .liquidGlass(cornerRadius: 14)
                    
                    // 4. 下方倉庫（僅顯示未被使用的資訊；若無資訊則禁選）
                    VStack(alignment: .leading, spacing: 8) {
                        Text("未使用的資訊積木（點選加入底欄）")
                            .font(.subheadline.bold())
                        
                        let unused = footerSettings.availableUnusedItems
                        if unused.isEmpty {
                            Text("所有積木皆已加入底欄")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(unused) { item in
                                    let hasInfo = item.hasAvailableInformation(exif: exifMetadata, customText: footerSettings.customText)
                                    Button {
                                        if hasInfo {
                                            addCard(item)
                                        }
                                    } label: {
                                        warehouseItemBadge(for: item, hasInfo: hasInfo)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!hasInfo)
                                    .opacity(hasInfo ? 1.0 : 0.45)
                                    .accessibilityIdentifier("footer_warehouse_\(item == .spacer ? "spacer" : item.rawValue)")
                                }
                            }
                        }
                    }
                    .padding(10)
                    .liquidGlass(cornerRadius: 14)
                    
                    // 5. 自訂文字輸入（若有加入 customText）
                    if footerSettings.activeItems.contains(.customText) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("自訂簽名 / 水印文字")
                                .font(.subheadline.bold())
                            TextField("請輸入簽名文字", text: $footerSettings.customText)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding()
                        .liquidGlass(cornerRadius: 16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .addLens:
                addLensSheetView
            case .lensPicker:
                lensPickerSheetView
            case .textColorPicker:
                textColorPickerSheetView
            }
        }
    }
    
    // MARK: - 工作表視圖
    private var addLensSheetView: some View {
        NavigationStack {
            Form {
                Section("鏡頭資訊") {
                    TextField("鏡頭名稱 (如 Noctilux 50/0.95)", text: $newLensName)
                    TextField("焦距 (mm)", text: $newLensFocal)
                        .keyboardType(.numberPad)
                    TextField("最大光圈 (如 1.4 或 0.95)", text: $newLensAperture)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("新增手動鏡頭")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { activeSheet = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存並套用") {
                        let focal = Double(newLensFocal) ?? 50.0
                        let aperture = Double(newLensAperture) ?? 1.4
                        let lens = ManualLens(name: newLensName, focalLength: focal, maxAperture: aperture)
                        modelContext.insert(lens)
                        exifMetadata.lensModel = lens.displayTitle
                        exifMetadata.focalLength = focal
                        exifMetadata.fNumber = aperture
                        activeSheet = nil
                    }
                    .disabled(newLensName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var lensPickerSheetView: some View {
        NavigationStack {
            List {
                if manualLenses.isEmpty {
                    Text("尚未建立任何手動鏡頭")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manualLenses) { lens in
                        Button {
                            exifMetadata.lensModel = lens.displayTitle
                            exifMetadata.focalLength = lens.focalLength
                            exifMetadata.fNumber = lens.maxAperture
                            activeSheet = nil
                        } label: {
                            VStack(alignment: .leading) {
                                Text(lens.name).font(.headline)
                                Text("\(Int(lens.focalLength))mm  f/\(lens.maxAperture)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("選擇手動老鏡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { activeSheet = nil }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("新增") {
                        activeSheet = .addLens
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var textColorPickerSheetView: some View {
        HSBColorPickerView(
            hue: $textH,
            saturation: $textS,
            brightness: $textB
        )
        .onChange(of: textH) { _, newH in
            footerSettings.textColorHex = ColorSpaceService.hsbToHex(h: newH, s: textS, b: textB)
        }
        .onChange(of: textS) { _, newS in
            footerSettings.textColorHex = ColorSpaceService.hsbToHex(h: textH, s: newS, b: textB)
        }
        .onChange(of: textB) { _, newB in
            footerSettings.textColorHex = ColorSpaceService.hsbToHex(h: textH, s: textS, b: newB)
        }
    }
    
    // MARK: - 文字顏色輔助方法
    private func isTextColorPreset(_ hex: String) -> Bool {
        footerSettings.textColorHex.uppercased() == hex.uppercased()
    }
    
    private var isCustomColorSelected: Bool {
        let hex = footerSettings.textColorHex.uppercased()
        return hex != "#8E8E93" && hex != "#1C1C1E" && hex != "#000000" && hex != "#FFFFFF"
    }
    
    private func prepareTextColorPicker() {
        if let hsb = ColorSpaceService.hexToHsb(footerSettings.textColorHex) {
            textH = hsb.h
            textS = hsb.s
            textB = hsb.b
        } else {
            textH = 0.0
            textS = 0.0
            textB = 0.58
        }
        activeSheet = .textColorPicker
    }
    
    @ViewBuilder
    private func colorOptionButton(title: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 0.5))
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity, minHeight: 34)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 當前排版狀態文字說明
    private var currentAlignmentDescription: String {
        let spacers = footerSettings.activeItems.filter { $0 == .spacer }.count
        if spacers == 0 {
            return "排版：全部置中（無放置間距）"
        } else if spacers == 1 {
            let spacerIdx = footerSettings.activeItems.firstIndex(of: .spacer) ?? 0
            if spacerIdx == 0 {
                return "排版：全部靠右"
            } else if spacerIdx == footerSettings.activeItems.count - 1 {
                return "排版：全部靠左"
            } else {
                return "排版：左右分欄（靠左 ⟷ 靠右）"
            }
        } else {
            let indices = footerSettings.activeItems.enumerated().compactMap { $0.element == .spacer ? $0.offset : nil }
            if indices.contains(footerSettings.activeItems.count - 1) {
                return "排版：置左 ＋ 置中"
            } else if indices.contains(0) {
                return "排版：置中 ＋ 靠右"
            } else {
                return "排版：三段分欄（靠左 ⟷ 置中 ⟷ 靠右）"
            }
        }
    }
    
    // MARK: - 倉庫積木徽章（無資訊時呈現禁選外觀）
    @ViewBuilder
    private func warehouseItemBadge(for item: FooterItemType, hasInfo: Bool) -> some View {
        HStack(spacing: 4) {
            if item == .spacer {
                SpacerIconBadge()
                Text("間距 |←→|")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: hasInfo ? "plus.circle" : "slash.circle")
                    .font(.caption2)
                    .foregroundStyle(hasInfo ? Color.primary : Color.secondary)
                Text(hasInfo ? item.rawValue : "\(item.rawValue) (無)")
                    .font(.caption.bold())
                    .foregroundStyle(hasInfo ? Color.primary : Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 34)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    item == .spacer
                        ? Color.accentColor.opacity(0.1)
                        : (hasInfo ? Color.primary.opacity(0.05) : Color.primary.opacity(0.02))
                )
                .overlay {
                    if !hasInfo && item != .spacer {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 0.8)
                    }
                }
        }
    }
    
    // MARK: - 已啟用積木卡片
    @ViewBuilder
    private func activeCardView(card: ActiveCardItem) -> some View {
        let index = card.index
        let item = card.item
        
        HStack(spacing: 5) {
            // 向左微調按鈕
            if index > 0 {
                Button {
                    swapCards(at: index, with: index - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("向左微調 \(item.rawValue)")
                .accessibilityIdentifier("footer_move_left_\(index)")
            }
            
            // 專屬拖曳手柄
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 16, height: 28)
                .contentShape(Rectangle())
                .accessibilityLabel("拖曳手柄 \(item.rawValue)")
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            if draggingIndex == nil {
                                draggingIndex = index
                                #if canImport(UIKit)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                #endif
                            }
                            dragOffset = value.translation.width
                            let threshold: CGFloat = 45
                            if dragOffset > threshold && index < footerSettings.activeItems.count - 1 {
                                swapCards(at: index, with: index + 1)
                                draggingIndex = index + 1
                                dragOffset = 0
                            } else if dragOffset < -threshold && index > 0 {
                                swapCards(at: index, with: index - 1)
                                draggingIndex = index - 1
                                dragOffset = 0
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                draggingIndex = nil
                                dragOffset = 0
                            }
                        }
                )
            
            // 積木圖示與標籤
            if item == .spacer {
                SpacerIconBadge()
                Text("間距 |←→|")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(item.rawValue)
                    .font(.caption.bold())
            }
            
            // 向右微調按鈕
            if index < footerSettings.activeItems.count - 1 {
                Button {
                    swapCards(at: index, with: index + 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("向右微調 \(item.rawValue)")
                .accessibilityIdentifier("footer_move_right_\(index)")
            }
            
            // 移除按鈕
            Button {
                removeCard(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("移除 \(item.rawValue)")
            .accessibilityIdentifier("footer_remove_\(index)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(item == .spacer ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            item == .spacer
                                ? Color.accentColor.opacity(0.6)
                                : (item == .lens ? Color.orange.opacity(0.7) : Color.primary.opacity(0.2)),
                            style: StrokeStyle(lineWidth: 1.2, dash: item == .spacer ? [2, 2] : [4, 2])
                        )
                }
        }
        .offset(x: draggingIndex == index ? dragOffset : 0)
        .scaleEffect(draggingIndex == index ? 1.05 : 1.0)
        .shadow(color: draggingIndex == index ? Color.black.opacity(0.2) : Color.clear, radius: 8, y: 4)
        .zIndex(draggingIndex == index ? 10 : 1)
        .contextMenu {
            if item == .lens {
                Button("選擇既有手動老鏡...") {
                    activeSheet = .lensPicker
                }
                Button("新增自訂手動鏡頭...") {
                    activeSheet = .addLens
                }
            }
            Button("從底欄移除", role: .destructive) {
                removeCard(at: index)
            }
        }
    }
    
    // MARK: - 積木操作輔助函式（嚴格觸發 Binding 狀態更新）
    private func swapCards(at i: Int, with j: Int) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            var updated = footerSettings
            updated.swapItems(at: i, with: j)
            footerSettings = updated
            layoutRevision += 1
        }
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    
    private func removeCard(at index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            guard index < footerSettings.activeItems.count else { return }
            var updated = footerSettings
            updated.activeItems.remove(at: index)
            footerSettings = updated
            layoutRevision += 1
        }
    }
    
    private func addCard(_ item: FooterItemType) {
        guard item.hasAvailableInformation(exif: exifMetadata, customText: footerSettings.customText) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            var updated = footerSettings
            updated.addItem(item, exif: exifMetadata)
            footerSettings = updated
            layoutRevision += 1
        }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
}

/// 彈性間距專屬圖示元件 (|←→|)
public struct SpacerIconBadge: View {
    public init() {}
    
    public var body: some View {
        HStack(spacing: 2.5) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary.opacity(0.85))
                .frame(width: 2, height: 11)
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 8, weight: .bold))
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.primary.opacity(0.85))
                .frame(width: 2, height: 11)
        }
    }
}

/// 底欄積木卡片內部動態識別項目
struct ActiveCardItem: Identifiable {
    let id: String
    let index: Int
    let item: FooterItemType
}


