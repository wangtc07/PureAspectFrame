import SwiftUI
import SwiftData
import PhotosUI

/// 快速導入模式視圖（選取照片後直接套用模板預覽，免顯示複雜編輯面板，一鍵快速導出）
public struct QuickImportView: View {
    @Binding var sourceImage: CGImage
    var exifMetadata: ExifMetadata
    
    @Query private var savedTemplates: [FrameTemplate]
    @State private var selectedTemplate: FrameTemplate?
    
    @State private var showingFullEditor: Bool = false
    @State private var showingShareSheet: Bool = false
    @State private var exportItems: [Any] = []
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    public init(sourceImage: Binding<CGImage>, exifMetadata: ExifMetadata) {
        self._sourceImage = sourceImage
        self.exifMetadata = exifMetadata
    }
    
    public init(sourceImage: CGImage, exifMetadata: ExifMetadata) {
        self._sourceImage = .constant(sourceImage)
        self.exifMetadata = exifMetadata
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 模板快速選擇列
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedTemplate = nil
                        } label: {
                            Text("預設 4:5 白邊")
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background {
                                    Capsule()
                                        .fill(selectedTemplate == nil ? Color.accentColor : Color.primary.opacity(0.06))
                                }
                                .foregroundStyle(selectedTemplate == nil ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(savedTemplates) { template in
                            Button {
                                selectedTemplate = template
                            } label: {
                                Text(template.name)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background {
                                        Capsule()
                                            .fill(selectedTemplate?.id == template.id ? Color.accentColor : Color.primary.opacity(0.06))
                                    }
                                    .foregroundStyle(selectedTemplate?.id == template.id ? Color.white : Color.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                // 完整免編輯欄畫布預覽 (Aspect-Fit)
                let activeRatio = selectedTemplate?.canvasRatio ?? .ig4x5
                let activeBorder = selectedTemplate?.borderSettings ?? BorderSettings()
                let activeBackground = selectedTemplate?.backgroundMode ?? .white
                let activeFooter = selectedTemplate?.footerSettings ?? FooterSettings()
                
                if let rendered = ImageRendererService.render(
                    image: sourceImage,
                    canvasRatio: activeRatio,
                    internalRatio: .free,
                    isZeroCrop: false,
                    borderSettings: activeBorder,
                    backgroundMode: activeBackground,
                    footerSettings: activeFooter,
                    exif: exifMetadata,
                    baseWidth: 1080
                ) {
                    Image(decorative: rendered, scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Group {
                    if #available(iOS 26.0, *) {
                        GlassEffectContainer(spacing: 12) {
                            quickImportBottomButtons(
                                ratio: activeRatio,
                                border: activeBorder,
                                background: activeBackground,
                                footer: activeFooter
                            )
                        }
                    } else {
                        quickImportBottomButtons(
                            ratio: activeRatio,
                            border: activeBorder,
                            background: activeBackground,
                            footer: activeFooter
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            .navigationTitle("快速導入預覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showingFullEditor) {
                EditorView(sourceImage: $sourceImage, initialExif: exifMetadata)
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareActivityView(activityItems: exportItems)
            }
        }
    }
    
    private func quickImportBottomButtons(
        ratio: CanvasRatio,
        border: BorderSettings,
        background: BackgroundMode,
        footer: FooterSettings
    ) -> some View {
        HStack(spacing: ChromeMetrics.groupSpacing) {
            Button {
                showingFullEditor = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                    Text("進階微調")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .liquidGlassCapsule(height: ChromeMetrics.capsuleHeight, ink: .primary)
            }
            .buttonStyle(.plain)
            
            Button {
                performQuickExport(
                    ratio: ratio,
                    border: border,
                    background: background,
                    footer: footer
                )
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: ChromeMetrics.iconPointSize, weight: .semibold))
                    Text("直接導出")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .liquidGlassCapsule(height: ChromeMetrics.capsuleHeight, ink: .primary)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func performQuickExport(
        ratio: CanvasRatio,
        border: BorderSettings,
        background: BackgroundMode,
        footer: FooterSettings
    ) {
        if let rendered = ImageRendererService.render(
            image: sourceImage,
            canvasRatio: ratio,
            internalRatio: .free,
            isZeroCrop: false,
            borderSettings: border,
            backgroundMode: background,
            footerSettings: footer,
            exif: exifMetadata,
            baseWidth: 1080
        ),
        let data = ColorSpaceService.exportImageWithMetadata(image: rendered, metadata: exifMetadata),
        let uiImg = UIImage(data: data) {
            exportItems = [uiImg]
            
            // 寫入歷史作品
            let record = ArtworkRecord(
                title: exifMetadata.cameraDisplayString.isEmpty ? "快速導出" : exifMetadata.cameraDisplayString,
                storagePolicy: .fullImage,
                thumbnailData: data,
                exportedImageData: data,
                diskSizeBytes: Int64(data.count)
            )
            modelContext.insert(record)
            showingShareSheet = true
        }
    }
}
