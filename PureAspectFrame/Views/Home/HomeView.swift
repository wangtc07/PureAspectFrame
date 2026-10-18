import SwiftUI
import SwiftData
import PhotosUI

/// 主頁視圖（遵循 ChekiLens 設計風格語言：去除非必要標題、頂部浮動標題與設定、清晰分段、底部標準雙膠囊按鈕）
public struct HomeView: View {
    @Query(sort: \ArtworkRecord.createdAt, order: .reverse) private var artworks: [ArtworkRecord]
    @Environment(\.modelContext) private var modelContext
    
    // 篩選模式：全部 / 已存圖 / 僅設定
    @State private var filterMode: StorageFilter = .all
    
    // 相片選取狀態
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var loadedCGImage: CGImage? = DemoImageProvider.makeDemoImage()
    @State private var loadedExif: ExifMetadata = DemoImageProvider.demoExif
    
    // 導航目的地
    private enum HomeSheet: Identifiable {
        case settings
        case quickImport

        var id: Int { hashValue }
    }
    @State private var activeSheet: HomeSheet?
    @State private var showingFullEditor: Bool = false
    @State private var isQuickImportMode: Bool = false
    
    public enum StorageFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case fullImage = "已存圖"
        case settingsOnly = "僅設定"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var filteredArtworks: [ArtworkRecord] {
        switch filterMode {
        case .all:
            return artworks
        case .fullImage:
            return artworks.filter { $0.storagePolicy == .fullImage }
        case .settingsOnly:
            return artworks.filter { $0.storagePolicy == .settingsOnly }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
                // 1. 頂部自訂 Header（比照 ChekiLens LibraryView 規範，移除冗餘純英標題）
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("作品")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        let totalBytes = artworks.reduce(0) { $0 + $1.diskSizeBytes }
                        let totalMB = Double(totalBytes) / (1024 * 1024)
                        Text(artworks.isEmpty ? "尚未有任何作品" : "\(filteredArtworks.count) 個項目 · 已用 \(String(format: "%.1f MB", totalMB))")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // 設定按鈕（44pt 圓形玻璃材質，對齊 ChekiLens ChromeMetrics）
                    Button {
                        activeSheet = .settings
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                            .frame(width: ChromeMetrics.circle, height: ChromeMetrics.circle)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    .accessibilityLabel("設定")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)
                
                // 2. 空間篩選分段控制（僅在有作品時強調篩選，乾淨俐落）
                Picker("作品篩選", selection: $filterMode) {
                    ForEach(StorageFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // 3. 歷史作品網格或空狀態
                if filteredArtworks.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "photo.stack")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("尚未有任何作品")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("選取相片開始自由裁切、白框直調與底欄資訊排版")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        VStack(spacing: 10) {
                            Button {
                                loadDemoPhoto(quickImport: false)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                    Text("載入示範相片 (Leica M11 樣張)")
                                }
                                .font(.subheadline.weight(.semibold))
                                .frame(height: ChromeMetrics.capsuleHeight)
                                .padding(.horizontal, ChromeMetrics.capsuleHPadding)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Capsule())
                            
                            Button {
                                loadDemoPhoto(quickImport: true)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "bolt.fill")
                                    Text("示範相片快速導入體驗")
                                }
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        }
                        .padding(.top, 12)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                            ForEach(filteredArtworks) { record in
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack(alignment: .topTrailing) {
                                        if let thumbData = record.thumbnailData,
                                           let uiImg = UIImage(data: thumbData) {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 180)
                                                .background(Color.secondary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color.secondary.opacity(0.1))
                                                .frame(height: 140)
                                                .overlay {
                                                    Image(systemName: "photo")
                                                        .foregroundStyle(.secondary)
                                                }
                                        }
                                        
                                        // 儲存模式標籤
                                        Text(record.storagePolicy == .fullImage ? "已存圖" : "僅設定")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                            .padding(6)
                                    }
                                    
                                    Text(record.title)
                                        .font(.caption.bold())
                                        .lineLimit(1)
                                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(16)
                    }
                }
                
                // 4. 底部主要操作按鈕：「快速導入」與「自訂編輯」（高度 44pt，對齊 ChekiLens Chrome 規範）
                HStack(spacing: ChromeMetrics.groupSpacing) {
                    // 快速導入按鈕
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text("快速導入")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: ChromeMetrics.capsuleHeight)
                        .background {
                            RoundedRectangle(cornerRadius: ChromeMetrics.capsuleHeight / 2.0, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                        }
                        .foregroundStyle(Color.primary)
                    }
                    .simultaneousGesture(TapGesture().onEnded { isQuickImportMode = true })
                    
                    // 新增編輯按鈕
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("自訂編輯")
                        }
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity, minHeight: ChromeMetrics.capsuleHeight)
                        .background {
                            RoundedRectangle(cornerRadius: ChromeMetrics.capsuleHeight / 2.0, style: .continuous)
                                .fill(Color.accentColor)
                        }
                        .foregroundStyle(Color.white)
                    }
                    .simultaneousGesture(TapGesture().onEnded { isQuickImportMode = false })
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .settings:
                    SettingsView()
                case .quickImport:
                    if let cgImg = loadedCGImage {
                        QuickImportView(sourceImage: cgImg, exifMetadata: loadedExif)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingFullEditor) {
                if let cgImg = loadedCGImage {
                    EditorView(sourceImage: cgImg, initialExif: loadedExif)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        loadedExif = ExifParserService.parse(imageData: data)
                        if let uiImage = UIImage(data: data), let cg = uiImage.cgImage {
                            loadedCGImage = cg
                            if isQuickImportMode {
                                activeSheet = .quickImport
                            } else {
                                showingFullEditor = true
                            }
                        }
                    }
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
