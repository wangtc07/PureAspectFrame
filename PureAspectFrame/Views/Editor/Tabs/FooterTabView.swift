import SwiftUI
import SwiftData

/// 【底欄】分頁視圖
public struct FooterTabView: View {
    @Binding var footerSettings: FooterSettings
    @Binding var exifMetadata: ExifMetadata
    
    @Query private var manualLenses: [ManualLens]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddLensSheet: Bool = false
    @State private var showingLensPickerSheet: Bool = false
    @State private var newLensName: String = ""
    @State private var newLensFocal: String = "50"
    @State private var newLensAperture: String = "1.4"
    
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0
    @State private var layoutRevision: Int = 0
    
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
                HStack(spacing: 12) {
                    Toggle("相片資訊底欄", isOn: $footerSettings.isEnabled)
                        .font(.subheadline.bold())
                    
                    if footerSettings.isEnabled {
                        Spacer()
                        HStack(spacing: 6) {
                            Text("字級")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Slider(value: $footerSettings.fontSizeScale, in: 0.015...0.038)
                                .frame(width: 90)
                            Text(String(format: "%.1f%%", footerSettings.fontSizeScale * 100))
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .liquidGlass(cornerRadius: 14)
                
                if footerSettings.isEnabled {
                    // 2. 當前底欄啟用之積木 (左右排列、拖動重排與長按互動)
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
                    
                    // 3. 下方倉庫（僅顯示未被使用的資訊）
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
                                    Button {
                                        addCard(item)
                                    } label: {
                                        warehouseItemBadge(for: item)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("footer_warehouse_\(item == .spacer ? "spacer" : item.rawValue)")
                                }
                            }
                        }
                    }
                    .padding(10)
                    .liquidGlass(cornerRadius: 14)
                    
                    // 4. 自訂文字輸入（若有加入 customText）
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
        .sheet(isPresented: $showingAddLensSheet) {
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
                        Button("取消") { showingAddLensSheet = false }
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
                            showingAddLensSheet = false
                        }
                        .disabled(newLensName.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingLensPickerSheet) {
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
                                showingLensPickerSheet = false
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
                        Button("關閉") { showingLensPickerSheet = false }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("新增") {
                            showingLensPickerSheet = false
                            showingAddLensSheet = true
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
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
    
    // MARK: - 倉庫積木徽章
    @ViewBuilder
    private func warehouseItemBadge(for item: FooterItemType) -> some View {
        HStack(spacing: 4) {
            if item == .spacer {
                SpacerIconBadge()
                Text("間距 |←→|")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: "plus.circle")
                    .font(.caption2)
                Text(item.rawValue)
                    .font(.caption.bold())
            }
        }
        .frame(maxWidth: .infinity, minHeight: 34)
        .contentShape(Rectangle())
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(item == .spacer ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.05))
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
                    showingLensPickerSheet = true
                }
                Button("新增自訂手動鏡頭...") {
                    showingAddLensSheet = true
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            var updated = footerSettings
            updated.addItem(item)
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


