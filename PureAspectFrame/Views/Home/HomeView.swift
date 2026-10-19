import SwiftUI
import SwiftData
import PhotosUI
import Photos

/// 主頁視圖（遵循 ChekiLens 與 iOS 26 原生 Liquid Glass 設計語言）
public struct HomeView: View {
    @Query(sort: \ArtworkRecord.createdAt, order: .reverse) private var artworks: [ArtworkRecord]
    @Environment(\.modelContext) private var modelContext
    
    // 相片選取狀態
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var loadedCGImage: CGImage? = DemoImageProvider.makeDemoImage()
    @State private var loadedExif: ExifMetadata = DemoImageProvider.demoExif
    
    // 漸進式載入與提示狀態
    @State private var isImportingPhoto: Bool = false
    @State private var importStatusText: String = ""
    
    // 導航目的地
    private enum HomeSheet: Identifiable {
        case settings
        case quickImport

        var id: Int { hashValue }
    }
    @State private var activeSheet: HomeSheet?
    @State private var showingFullEditor: Bool = false
    @State private var isQuickImportMode: Bool = false
    
    // 多選與批次操作狀態
    @State private var isSelectMode: Bool = false
    @State private var selectionState: ArtworkSelectionState = ArtworkSelectionState()
    @State private var showingBatchDeleteAlert: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var exportItems: [Any] = []
    
    public init(initialSelectMode: Bool = false, initialSelection: Set<UUID> = []) {
        self._isSelectMode = State(initialValue: initialSelectMode)
        self._selectionState = State(initialValue: ArtworkSelectionState(selectedIDs: initialSelection))
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // 1. 主要內容：相片列表或無作品空狀態
            if artworks.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                artworksGridView
            }
            
            // 2. 頂部懸浮透明玻璃工具列（完全移除「作品」與「PureAspect...」標題，移除「全部/已存圖」切換）
            topFloatingHeaderBar
            
            // 3. 漸進式導入提示浮動膠囊（Liquid Glass 風格）
            if isImportingPhoto {
                VStack {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.regular)
                        Text(importStatusText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .liquidGlassCapsule(height: 44, horizontalPadding: 20, ink: .primary)
                    .padding(.top, 64)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isImportingPhoto)
                .zIndex(100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionFloatingBar
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .settings:
                SettingsView()
            case .quickImport:
                QuickImportView(
                    sourceImage: Binding(
                        get: { loadedCGImage ?? DemoImageProvider.makeDemoImage() },
                        set: { loadedCGImage = $0 }
                    ),
                    exifMetadata: loadedExif
                )
            }
        }
        .fullScreenCover(isPresented: $showingFullEditor) {
            EditorView(
                sourceImage: Binding(
                    get: { loadedCGImage ?? DemoImageProvider.makeDemoImage() },
                    set: { loadedCGImage = $0 }
                ),
                initialExif: loadedExif
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareActivityView(activityItems: exportItems)
        }
        .confirmationDialog(
            "確定要刪除選取的 \(selectionState.selectedIDs.count) 個作品嗎？",
            isPresented: $showingBatchDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("刪除 \(selectionState.selectedIDs.count) 個作品", role: .destructive) {
                deleteSelectedArtworks()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("刪除後將無法復原。")
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let item = newItem else { return }
            isImportingPhoto = true
            importStatusText = "正在載入相片預覽..."
            
            Task {
                var previewLoaded = false
                
                // 1. 若可獲取 PhotoKit 本機快取，嘗試直接取得即時低畫質/縮圖（通常 <10ms，無需等待 iCloud）
                if let localId = item.itemIdentifier {
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
                    if let asset = fetchResult.firstObject {
                        let options = PHImageRequestOptions()
                        options.deliveryMode = .fastFormat
                        options.isNetworkAccessAllowed = false
                        options.isSynchronous = false
                        
                        PHImageManager.default().requestImage(
                            for: asset,
                            targetSize: CGSize(width: 1600, height: 1600),
                            contentMode: .aspectFit,
                            options: options
                        ) { uiImage, _ in
                            guard let uiImage = uiImage, !previewLoaded else { return }
                            if let data = uiImage.jpegData(compressionQuality: 0.8),
                               let cg = ImageDecodingService.createOrientedCGImage(from: data, maxPixelSize: 1600) {
                                Task { @MainActor in
                                    guard !previewLoaded else { return }
                                    previewLoaded = true
                                    loadedCGImage = cg
                                    if isQuickImportMode {
                                        activeSheet = .quickImport
                                    } else {
                                        showingFullEditor = true
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 2. 異步下載完整相片 Data（支援 iCloud 異步下載）
                importStatusText = "正在下載高畫質原圖..."
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let exif = ExifParserService.parse(imageData: data)
                    loadedExif = exif
                    
                    // 若前一步未能取得快取縮圖，先以 ImageIO 硬體降採樣生成 1600px 快速圖
                    if !previewLoaded {
                        if let fastCG = ImageDecodingService.createOrientedCGImage(from: data, maxPixelSize: 1600) {
                            previewLoaded = true
                            loadedCGImage = fastCG
                            if isQuickImportMode {
                                activeSheet = .quickImport
                            } else {
                                showingFullEditor = true
                            }
                        }
                    }
                    
                    // 3. 在背景生成無損完整解析度轉正 CGImage 並無縫升級為原圖
                    if let fullCG = ImageDecodingService.createOrientedCGImage(from: data, maxPixelSize: nil) {
                        loadedCGImage = fullCG
                    }
                }
                
                isImportingPhoto = false
                selectedPhotoItem = nil
            }
        }
        .onAppear {
            if loadedCGImage == nil {
                loadedCGImage = DemoImageProvider.makeDemoImage()
                loadedExif = DemoImageProvider.demoExif
            }
        }
    }
    
    // MARK: - 頂部懸浮工具列 (對齊 ChekiLens LibraryView 規範)
    private var topFloatingHeaderBar: some View {
        HStack(alignment: .center) {
            if isSelectMode {
                // 多選模式：顯示已選取數量
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("已選取 \(selectionState.selectedIDs.count) 項")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .liquidGlassCapsule(height: 32, horizontalPadding: 12, ink: .primary, interactive: false)
            } else if !artworks.isEmpty {
                let totalBytes = artworks.reduce(0) { $0 + $1.diskSizeBytes }
                let totalMB = Double(totalBytes) / (1024 * 1024)
                Text("\(artworks.count) 個項目 · 已用 \(String(format: "%.1f MB", totalMB))")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .liquidGlassCapsule(height: 32, horizontalPadding: 12, ink: .secondary, interactive: false)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if isSelectMode {
                    // 全選 / 取消全選按鈕
                    let allIDs = artworks.map(\.id)
                    let isAllSelected = selectionState.selectedIDs.count == artworks.count && !artworks.isEmpty
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectionState.toggleSelectAll(from: allIDs)
                        }
                    } label: {
                        Text(isAllSelected ? "取消全選" : "全選")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .liquidGlassCapsule(height: 32, horizontalPadding: 10, ink: .primary)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_select_all_button")
                    
                    // 完成按鈕
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelectMode = false
                            selectionState.deselectAll()
                        }
                    } label: {
                        Text("完成")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .liquidGlassCapsule(height: 32, horizontalPadding: 12, ink: .primary)
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home_select_done_button")
                } else {
                    if !artworks.isEmpty {
                        // 選擇按鈕 (右上)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSelectMode = true
                                selectionState.deselectAll()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                Text("選擇")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .liquidGlassCapsule(height: 32, horizontalPadding: 10, ink: .primary)
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home_select_button")
                    }
                    
                    ChromeCircleButton(
                        systemName: "gearshape",
                        ink: .primary,
                        accessibilityLabel: "設定",
                        action: { activeSheet = .settings }
                    )
                }
            }
        }
        .padding(.horizontal, ChromeMetrics.edgeHorizontal)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0.85),
                    Color(.systemBackground).opacity(0.35),
                    Color(.systemBackground).opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - 空狀態視圖 (Liquid Glass 示範體驗)
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "photo.stack")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.tertiary)
            
            Text("尚未有任何作品")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("選取相片開始自由裁切、白框直調與底欄資訊排版")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            
            VStack(spacing: 12) {
                Button {
                    loadDemoPhoto(quickImport: false)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("載入示範相片 (Leica M11 樣張)")
                    }
                    .font(.subheadline.weight(.semibold))
                    .liquidGlassCapsule(height: ChromeMetrics.capsuleHeight, horizontalPadding: 18, ink: .primary)
                }
                .buttonStyle(.plain)
                
                Button {
                    loadDemoPhoto(quickImport: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("示範相片快速導入體驗")
                    }
                    .font(.caption.weight(.medium))
                    .liquidGlassCapsule(height: 36, horizontalPadding: 14, ink: .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - 歷史作品網格視圖
    private var artworksGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                ForEach(artworks) { record in
                    artworkCardView(for: record)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 64)
            .padding(.bottom, 80)
        }
    }
    
    // MARK: - 單一作品卡片視圖
    @ViewBuilder
    private func artworkCardView(for record: ArtworkRecord) -> some View {
        let isSelected = selectionState.isSelected(record.id)
        
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                if let thumbData = record.thumbnailData,
                   let uiImg = UIImage(data: thumbData) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 180)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(height: 140)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
                
                HStack(alignment: .top) {
                    if isSelectMode {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.white.opacity(0.9))
                            .background {
                                if !isSelected {
                                    Circle().fill(Color.black.opacity(0.35))
                                }
                            }
                            .padding(6)
                    }
                    
                    Spacer()
                    
                    Text(record.storagePolicy == .fullImage ? "已存圖" : "僅設定")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .liquidGlassCapsule(height: 20, horizontalPadding: 6, ink: .primary, interactive: false)
                        .padding(6)
                }
            }
            
            Text(record.title)
                .font(.caption.bold())
                .lineLimit(1)
            Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .liquidGlass(cornerRadius: 16)
        .overlay {
            if isSelectMode && isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectMode {
                #if canImport(UIKit)
                UISelectionFeedbackGenerator().selectionChanged()
                #endif
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    selectionState.toggle(record.id)
                }
            }
        }
        .contextMenu {
            Button {
                exportSingleArtwork(record)
            } label: {
                Label("導出作品", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive) {
                deleteSingleArtwork(record)
            } label: {
                Label("刪除作品", systemImage: "trash")
            }
        }
        .accessibilityIdentifier("artwork_card_\(record.id.uuidString)")
        .accessibilityLabel("\(record.title)，\(record.storagePolicy == .fullImage ? "已存圖" : "僅設定")")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - 底部浮動液態玻璃操作列 (完全對齊 ChekiLens 原生透明液態玻璃風格)
    private var bottomActionFloatingBar: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: ChromeMetrics.groupSpacing) {
                    if isSelectMode {
                        selectionBottomButtons
                    } else {
                        bottomButtonsContent
                    }
                }
            } else {
                if isSelectMode {
                    selectionBottomButtons
                } else {
                    bottomButtonsContent
                }
            }
        }
        .padding(.horizontal, ChromeMetrics.edgeHorizontal)
        .padding(.bottom, ChromeMetrics.edgeBottom)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelectMode)
    }
    
    // MARK: - 多選模式底部操作按鈕（導出與刪除）
    private var selectionBottomButtons: some View {
        let count = selectionState.selectedIDs.count
        return HStack(spacing: ChromeMetrics.groupSpacing) {
            // 導出所選按鈕
            Button {
                exportSelectedArtworks()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                    Text(count > 0 ? "導出 (\(count))" : "導出")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .liquidGlassCapsule(
                    height: ChromeMetrics.capsuleHeight,
                    ink: count > 0 ? .primary : .secondary
                )
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .opacity(count > 0 ? 1.0 : 0.45)
            .accessibilityIdentifier("home_batch_export_button")
            
            // 刪除所選按鈕
            Button {
                showingBatchDeleteAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: ChromeMetrics.iconPointSize, weight: .bold))
                    Text(count > 0 ? "刪除 (\(count))" : "刪除")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .background {
                    Capsule()
                        .fill(count > 0 ? Color.red.opacity(0.18) : Color.primary.opacity(0.05))
                        .overlay {
                            if count > 0 {
                                Capsule().strokeBorder(Color.red.opacity(0.4), lineWidth: 1)
                            }
                        }
                }
                .foregroundStyle(count > 0 ? Color.red : Color.secondary)
                .frame(height: ChromeMetrics.capsuleHeight)
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .opacity(count > 0 ? 1.0 : 0.45)
            .accessibilityIdentifier("home_batch_delete_button")
        }
    }
    
    private var bottomButtonsContent: some View {
        HStack(spacing: ChromeMetrics.groupSpacing) {
            // 快速導入按鈕（透明液態玻璃膠囊）
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                    Text("快速導入")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .liquidGlassCapsule(height: ChromeMetrics.capsuleHeight, ink: .primary)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { isQuickImportMode = true })
            
            // 自訂編輯按鈕（透明液態玻璃膠囊）
            PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: ChromeMetrics.iconPointSize, weight: .bold))
                    Text("自訂編輯")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .liquidGlassCapsule(height: ChromeMetrics.capsuleHeight, ink: .primary)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { isQuickImportMode = false })
        }
    }
    
    // MARK: - 作品導出與刪除操作
    private func exportSingleArtwork(_ record: ArtworkRecord) {
        if let img = ArtworkExportHelper.exportImage(for: record) {
            exportItems = [img]
            showingShareSheet = true
        }
    }
    
    private func deleteSingleArtwork(_ record: ArtworkRecord) {
        withAnimation {
            selectionState.selectedIDs.remove(record.id)
            modelContext.delete(record)
            try? modelContext.save()
            if artworks.isEmpty {
                isSelectMode = false
            }
        }
    }
    
    private func exportSelectedArtworks() {
        let selectedRecords = artworks.filter { selectionState.isSelected($0.id) }
        let images = ArtworkExportHelper.exportImages(for: selectedRecords)
        if !images.isEmpty {
            exportItems = images
            showingShareSheet = true
        }
    }
    
    private func deleteSelectedArtworks() {
        withAnimation {
            for record in artworks where selectionState.isSelected(record.id) {
                modelContext.delete(record)
            }
            try? modelContext.save()
            selectionState.deselectAll()
            isSelectMode = false
        }
    }
    
    private func loadDemoPhoto(quickImport: Bool = false) {
        loadedExif = DemoImageProvider.demoExif
        loadedCGImage = DemoImageProvider.makeDemoImage()
        if quickImport {
            activeSheet = .quickImport
        } else {
            showingFullEditor = true
        }
    }
}
