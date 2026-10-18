import SwiftUI
import SwiftData

/// 編輯器核心視圖（上下獨立分割佈局、Liquid Glass 導航與控制面板）
public struct EditorView: View {
    @Binding var sourceImage: CGImage
    var initialExif: ExifMetadata
    
    // 當前編輯狀態
    @State private var canvasRatio: CanvasRatio = .ig4x5
    @State private var internalRatio: InternalCropRatio = .free
    @State private var isZeroCrop: Bool = false
    @State private var borderSettings: BorderSettings = BorderSettings()
    @State private var backgroundMode: BackgroundMode = .white
    @State private var footerSettings: FooterSettings = FooterSettings()
    @State private var splitSettings: SplitSettings = SplitSettings()
    @State private var exifMetadata: ExifMetadata
    
    // 編輯器 UI 狀態
    @State private var selectedTab: EditorTab = .ratio
    @State private var showDistanceMarkers: Bool = false
    @State private var isBottomPanelCollapsed: Bool = false
    
    // 彈出式視圖
    @State private var showingTemplateSheet: Bool = false
    @State private var showingSNSPreview: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var exportItems: [Any] = []
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedTemplates: [FrameTemplate]
    
    public enum EditorTab: String, CaseIterable, Identifiable {
        case ratio = "比例"
        case border = "邊框"
        case footer = "底欄"
        case split = "切割"
        
        public var id: String { rawValue }
        public var icon: String {
            switch self {
            case .ratio: return "aspectratio"
            case .border: return "square.dashed"
            case .footer: return "text.below.photo"
            case .split: return "square.split.2x1"
            }
        }
    }
    public init(sourceImage: Binding<CGImage>, initialExif: ExifMetadata = ExifMetadata(), initialTab: EditorTab = .ratio) {
        self._sourceImage = sourceImage
        self.initialExif = initialExif
        self._exifMetadata = State(initialValue: initialExif)
        self._selectedTab = State(initialValue: initialTab)
    }
    
    public init(sourceImage: CGImage, initialExif: ExifMetadata = ExifMetadata(), initialTab: EditorTab = .ratio) {
        self._sourceImage = .constant(sourceImage)
        self.initialExif = initialExif
        self._exifMetadata = State(initialValue: initialExif)
        self._selectedTab = State(initialValue: initialTab)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 上方主畫布舞台 (Aspect-Fit 獨立區域)
                CanvasStageView(
                    image: sourceImage,
                    canvasRatio: canvasRatio,
                    internalRatio: internalRatio,
                    isZeroCrop: isZeroCrop,
                    borderSettings: $borderSettings,
                    backgroundMode: backgroundMode,
                    footerSettings: footerSettings,
                    exifMetadata: exifMetadata,
                    showDistanceMarkers: $showDistanceMarkers,
                    isBottomPanelCollapsed: $isBottomPanelCollapsed
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(backgroundMode.stageBackgroundColor)
                .animation(.easeInOut(duration: 0.35), value: backgroundMode.stageBackgroundColor)
                
                // 下方編輯面板（支援收合與拉出）
                if isBottomPanelCollapsed {
                    // 收合時保留底部上拉指示箭頭
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isBottomPanelCollapsed = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.up")
                            Text("展開編輯欄位")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .liquidGlass(cornerRadius: 20)
                        .padding(.bottom, 8)
                    }
                    .buttonStyle(.plain)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    VStack(spacing: 0) {
                        // 分頁切換分段列
                        HStack(spacing: 6) {
                            ForEach(EditorTab.allCases) { tab in
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        selectedTab = tab
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: tab.icon)
                                            .font(.caption2)
                                        Text(tab.rawValue)
                                            .font(.subheadline.bold())
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 36)
                                    .contentShape(Capsule())
                                    .background {
                                        if selectedTab == tab {
                                            Capsule()
                                                .fill(Color.accentColor.opacity(0.18))
                                                .overlay {
                                                    Capsule().strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1)
                                                }
                                        }
                                    }
                                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        
                        Divider().opacity(0.3)
                        
                        // 分頁具體內容
                        Group {
                            switch selectedTab {
                            case .ratio:
                                RatioTabView(
                                    canvasRatio: $canvasRatio,
                                    internalRatio: $internalRatio,
                                    isZeroCrop: $isZeroCrop
                                )
                            case .border:
                                BorderTabView(
                                    borderSettings: $borderSettings,
                                    backgroundMode: $backgroundMode
                                )
                            case .footer:
                                FooterTabView(
                                    footerSettings: $footerSettings,
                                    exifMetadata: $exifMetadata
                                )
                            case .split:
                                SplitTabView(
                                    splitSettings: $splitSettings
                                )
                            }
                        }
                        .frame(height: 240)
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    // 模板鈕
                    Button {
                        showingTemplateSheet = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                    }
                    .accessibilityLabel("模板")
                    
                    // SNS 預覽鈕
                    Button {
                        showingSNSPreview = true
                    } label: {
                        Image(systemName: "eye")
                    }
                    .accessibilityLabel("SNS 預覽")
                    
                    // 導出分享鈕
                    Button {
                        performExport()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("導出").fontWeight(.semibold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingTemplateSheet) {
                templateManagementSheet
            }
            .sheet(isPresented: $showingSNSPreview) {
                let rendered = ImageRendererService.render(
                    image: sourceImage,
                    canvasRatio: canvasRatio,
                    internalRatio: internalRatio,
                    isZeroCrop: isZeroCrop,
                    borderSettings: borderSettings,
                    backgroundMode: backgroundMode,
                    footerSettings: footerSettings,
                    exif: exifMetadata
                )
                let slices = ImageRendererService.renderSlices(
                    image: sourceImage,
                    canvasRatio: canvasRatio,
                    internalRatio: internalRatio,
                    isZeroCrop: isZeroCrop,
                    borderSettings: borderSettings,
                    backgroundMode: backgroundMode,
                    footerSettings: footerSettings,
                    splitSettings: splitSettings,
                    exif: exifMetadata
                )
                SNSPreviewView(renderedImage: rendered, slices: slices)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareActivityView(activityItems: exportItems)
            }
        }
    }
    
    // MARK: - 模板管理面板
    @State private var templateNameInput: String = ""
    @ViewBuilder
    private var templateManagementSheet: some View {
        NavigationStack {
            List {
                Section("儲存目前設定為模板") {
                    HStack {
                        TextField("輸入模板名稱 (例如 拍立得日系白邊)", text: $templateNameInput)
                        Button("儲存") {
                            let template = FrameTemplate(
                                name: templateNameInput.isEmpty ? "自訂模板 \(Date().formatted(date: .numeric, time: .shortened))" : templateNameInput,
                                canvasRatio: canvasRatio,
                                internalRatio: internalRatio,
                                isZeroCrop: isZeroCrop,
                                borderSettings: borderSettings,
                                backgroundMode: backgroundMode,
                                footerSettings: footerSettings,
                                splitSettings: splitSettings
                            )
                            modelContext.insert(template)
                            templateNameInput = ""
                        }
                        .disabled(templateNameInput.isEmpty)
                    }
                }
                
                Section("已儲存模板") {
                    if savedTemplates.isEmpty {
                        Text("尚未儲存任何模板")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(savedTemplates) { t in
                            Button {
                                canvasRatio = t.canvasRatio
                                internalRatio = t.internalRatio
                                isZeroCrop = t.isZeroCrop
                                borderSettings = t.borderSettings
                                backgroundMode = t.backgroundMode
                                footerSettings = t.footerSettings
                                splitSettings = t.splitSettings
                                showingTemplateSheet = false
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(t.name).font(.headline)
                                    Text("\(t.canvasRatio.rawValue) · \(t.borderSettings.paddingTop)% 留白").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { idx in
                            for i in idx {
                                modelContext.delete(savedTemplates[i])
                            }
                        }
                    }
                }
            }
            .navigationTitle("模板管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showingTemplateSheet = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - 導出與儲存
    private func performExport() {
        if splitSettings.isEnabled && splitSettings.splitCount > 1 {
            let slices = ImageRendererService.renderSlices(
                image: sourceImage,
                canvasRatio: canvasRatio,
                internalRatio: internalRatio,
                isZeroCrop: isZeroCrop,
                borderSettings: borderSettings,
                backgroundMode: backgroundMode,
                footerSettings: footerSettings,
                splitSettings: splitSettings,
                exif: exifMetadata,
                baseWidth: 1080
            )
            var uiImages: [UIImage] = []
            for slice in slices {
                if let data = ColorSpaceService.exportImageWithMetadata(image: slice, metadata: exifMetadata),
                   let uiImg = UIImage(data: data) {
                    uiImages.append(uiImg)
                }
            }
            exportItems = uiImages
        } else {
            if let rendered = ImageRendererService.render(
                image: sourceImage,
                canvasRatio: canvasRatio,
                internalRatio: internalRatio,
                isZeroCrop: isZeroCrop,
                borderSettings: borderSettings,
                backgroundMode: backgroundMode,
                footerSettings: footerSettings,
                exif: exifMetadata,
                baseWidth: 1080
            ),
            let data = ColorSpaceService.exportImageWithMetadata(image: rendered, metadata: exifMetadata),
            let uiImg = UIImage(data: data) {
                exportItems = [uiImg]
                
                // 儲存至歷史作品記錄
                let record = ArtworkRecord(
                    title: exifMetadata.cameraDisplayString.isEmpty ? "純淨畫布" : exifMetadata.cameraDisplayString,
                    storagePolicy: .fullImage,
                    thumbnailData: data,
                    exportedImageData: data,
                    diskSizeBytes: Int64(data.count)
                )
                modelContext.insert(record)
            }
        }
        
        if !exportItems.isEmpty {
            showingShareSheet = true
        }
    }
}

/// 系統原生分享視圖 (UIActivityViewController)
public struct ShareActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
