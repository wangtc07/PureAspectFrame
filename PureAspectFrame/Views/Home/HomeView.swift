import SwiftUI
import SwiftData
import PhotosUI
import Photos

/// 主頁視圖（遵循 ChekiLens 與 iOS 26 原生 Liquid Glass 設計語言）
public struct HomeView: View {
    /// UI 設計規範常數（對齊 iOS 系統相簿選擇介面與右側垂直堆疊圖示按鈕）
    public static let topTrailingButtonOrder: [String] = ["settings", "select"]
    public static let selectionUsesSystemPhotosStyle: Bool = true
    public static let selectionCloseButtonIcon: String = "xmark"
    public static let selectionBottomExportIcon: String = "square.and.arrow.up"
    public static let selectionBottomDeleteIcon: String = "trash"
    public static let selectionBadgeAlignment: Alignment = .bottomTrailing
    public static let selectionShowsUnselectedCircle: Bool = false
    public static let importButtonsShowIconOnly: Bool = true
    public static let importButtonsAreRightAlignedVerticalStack: Bool = true
    public static let quickImportIconName: String = "bolt.fill"
    public static let customEditIconName: String = "plus"
    
    public static func selectionStatusText(count: Int) -> String {
        count > 0 ? "已選取 \(count) 張" : "選取項目"
    }

    private static let modeControlMinWidth: CGFloat = 96
    
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
    @Namespace private var homeChrome
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
            Color(.systemGroupedBackground)
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
    
    // MARK: - 頂部懸浮工具列 (對齊 iOS 系統相簿選擇 UI 與「設定 -> 選擇」按鈕順序)
    private var topFloatingHeaderBar: some View {
        HStack(alignment: .center) {
            Spacer()
            topModeControls
        }
        .padding(.horizontal, ChromeMetrics.edgeHorizontal)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemGroupedBackground).opacity(0.85),
                    Color(.systemGroupedBackground).opacity(0.35),
                    Color(.systemGroupedBackground).opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    private var topModeControls: some View {
        GlassEffectContainer(spacing: ChromeMetrics.groupSpacing) {
            HStack(spacing: ChromeMetrics.groupSpacing) {
                leadingModeControl
                if isSelectMode || !artworks.isEmpty {
                    trailingModeControl
                }
            }
        }
        .animation(.smooth(duration: 0.35), value: isSelectMode)
    }

    @ViewBuilder
    private var leadingModeControl: some View {
        if isSelectMode {
            let isAllSelected = !artworks.isEmpty && selectionState.selectedIDs.count == artworks.count
            Button {
                selectionState.toggleSelectAll(from: artworks.map(\.id))
            } label: {
                Text(isAllSelected ? "取消全選" : "全選")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .frame(minWidth: Self.modeControlMinWidth, minHeight: ChromeMetrics.capsuleHeight)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_select_all_button")
            .glassEffect(.regular.interactive(), in: .capsule)
            .glassEffectID("home-leading", in: homeChrome)
        } else {
            Button {
                activeSheet = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                    .frame(width: ChromeMetrics.circle, height: ChromeMetrics.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("設定")
            .accessibilityIdentifier("home_settings_button")
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID("home-leading", in: homeChrome)
        }
    }

    @ViewBuilder
    private var trailingModeControl: some View {
        if isSelectMode {
            Button {
                isSelectMode = false
                selectionState.deselectAll()
            } label: {
                Image(systemName: Self.selectionCloseButtonIcon)
                    .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                    .frame(width: ChromeMetrics.circle, height: ChromeMetrics.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("結束選擇")
            .accessibilityIdentifier("home_select_done_button")
            .glassEffect(.regular.interactive(), in: .circle)
            .glassEffectID("home-trailing", in: homeChrome)
        } else {
            Button {
                isSelectMode = true
                selectionState.deselectAll()
            } label: {
                Text("選擇")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .frame(minWidth: Self.modeControlMinWidth, minHeight: ChromeMetrics.capsuleHeight)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_select_button")
            .glassEffect(.regular.interactive(), in: .capsule)
            .glassEffectID("home-trailing", in: homeChrome)
        }
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
            
            Button {
                loadDemoPhoto(quickImport: false)
            } label: {
                Text("載入示範相片")
                    .font(.subheadline.weight(.semibold))
                    .liquidGlassCapsule(height: ChromeMetrics.capsuleHeight, horizontalPadding: 18, ink: .primary)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - 歷史作品網格視圖
    private var artworksGridView: some View {
        GeometryReader { proxy in
            let columnCount = max(3, Int(proxy.size.width / 180))
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columnCount),
                    spacing: 2
                ) {
                    ForEach(artworks) { record in
                        artworkCardView(for: record)
                    }
                }
                .padding(2)
                .padding(.top, 64)
                .padding(.bottom, 80)
            }
        }
    }
    
    // MARK: - 單一作品卡片視圖（選擇狀態完全對齊 iOS 系統相簿：右下角藍色白邊打勾、未選取不顯示空圓圈）
    @ViewBuilder
    private func artworkCardView(for record: ArtworkRecord) -> some View {
        let isSelected = selectionState.isSelected(record.id)
        
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let thumbData = record.thumbnailData,
                   let uiImg = UIImage(data: thumbData) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelectMode && isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 24)
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 1.8)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .padding(8)
                    .accessibilityIdentifier("artwork_selected_\(record.id.uuidString)")
                }
            }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectMode {
                #if canImport(UIKit)
                UISelectionFeedbackGenerator().selectionChanged()
                #endif
                selectionState.toggle(record.id)
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
        .accessibilityLabel(record.title)
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - 底部浮動液態玻璃操作列
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
    }
    
    // MARK: - 多選模式底部操作列（100% 參考系統相簿第三張圖：左圓形分享鈕 + 中間選取數量文字 + 右圓形垃圾桶刪除鈕）
    private var selectionBottomButtons: some View {
        let count = selectionState.selectedIDs.count
        return HStack(alignment: .center) {
            // 左下：圓形分享導出按鈕
            Button {
                exportSelectedArtworks()
            } label: {
                Image(systemName: Self.selectionBottomExportIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .liquidGlassCircle(size: ChromeMetrics.circle, ink: count > 0 ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .opacity(count > 0 ? 1.0 : 0.45)
            .accessibilityLabel("導出")
            .accessibilityIdentifier("home_batch_export_button")
            
            Spacer()
            
            // 中間：選取數量狀態文字
            Text(Self.selectionStatusText(count: count))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityIdentifier("home_selection_status_text")
            
            Spacer()
            
            // 右下：圓形垃圾桶刪除按鈕
            Button {
                showingBatchDeleteAlert = true
            } label: {
                Image(systemName: Self.selectionBottomDeleteIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .liquidGlassCircle(size: ChromeMetrics.circle, ink: count > 0 ? .primary : .secondary)
            }
            .buttonStyle(.plain)
            .disabled(count == 0)
            .opacity(count > 0 ? 1.0 : 0.45)
            .accessibilityLabel("刪除")
            .accessibilityIdentifier("home_batch_delete_button")
        }
    }
    
    // MARK: - 一般模式右側垂直堆疊圖示按鈕（快速導入 + 自訂編輯，僅顯示 Icon）
    private var bottomButtonsContent: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 12) {
                // 上方：快速導入圓形圖示按鈕
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: Self.quickImportIconName)
                        .font(.system(size: 19, weight: .semibold))
                        .liquidGlassCircle(size: ChromeMetrics.circle, ink: .primary)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { isQuickImportMode = true })
                .accessibilityLabel("快速導入")
                .accessibilityIdentifier("home_quick_import_button")
                
                // 下方：自訂編輯圓形圖示按鈕
                PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: Self.customEditIconName)
                        .font(.system(size: 21, weight: .bold))
                        .liquidGlassCircle(size: ChromeMetrics.circle, ink: .primary)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { isQuickImportMode = false })
                .accessibilityLabel("自訂編輯")
                .accessibilityIdentifier("home_custom_edit_button")
            }
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
