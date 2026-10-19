import SwiftUI
import SwiftData

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Settings") {
            SettingsView()
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-FooterTab-TwoSpacers") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .footer, initialFooterSettings: {
                var f = FooterSettings()
                f.activeItems = [.logo, .camera, .spacer, .parameters, .spacer]
                return f
            }())
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-FooterTab-EmptyExif") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: ExifMetadata(), initialTab: .footer, initialFooterSettings: {
                var f = FooterSettings()
                f.activeItems = [.spacer]
                return f
            }())
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-FooterTab-NoSpacer") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .footer, initialFooterSettings: {
                var f = FooterSettings()
                f.activeItems = [.logo, .camera, .parameters]
                return f
            }())
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-FooterTab") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .footer)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-BorderTab-TwoGroups") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .border, initialBorderSettings: {
                var b = BorderSettings()
                b.setLinkGroups(a: [.top, .bottom], b: [.left, .right])
                b.selectedEdges = [.left, .right]
                return b
            }())
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-BorderTab-LinkEdit") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .border, initialBorderSettings: {
                var b = BorderSettings()
                b.setLinkGroups(a: [.top, .bottom], b: [.left])
                b.isLinkedActive = true
                b.activeLinkSlot = 1
                b.selectedEdges = [.left]
                return b
            }())
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-BorderTab-Markers") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .border, initialShowDistanceMarkers: true)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-BorderTab") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialTab: .border)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Editor-AdjustingImage") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(
                sourceImage: img,
                initialExif: DemoImageProvider.demoExif,
                initialOffset: CGSize(width: 45, height: -30),
                initialScale: 1.35,
                initialIsAdjustingImage: true
            )
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-RatioTab-Landscape") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif, initialIsLandscape: true)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Editor") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-QuickImport") {
            let img = DemoImageProvider.makeDemoImage()
            QuickImportView(sourceImage: img, exifMetadata: DemoImageProvider.demoExif)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-ColorPicker") {
            ColorPickerTestContainer()
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Home-SelectMode") {
            HomeTestContainer(initialSelectMode: true)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Home-WithArtworks") {
            HomeTestContainer(initialSelectMode: false)
        } else {
            HomeView()
        }
    }
}

private struct HomeTestContainer: View {
    var initialSelectMode: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Query private var artworks: [ArtworkRecord]
    
    var body: some View {
        HomeView(
            initialSelectMode: initialSelectMode,
            initialSelection: initialSelectMode && !artworks.isEmpty ? Set([artworks[0].id]) : []
        )
            .task {
                let desc = FetchDescriptor<ArtworkRecord>()
                if (try? modelContext.fetchCount(desc)) == 0 {
                    let img = UIImage(cgImage: DemoImageProvider.makeDemoImage())
                    let data = img.jpegData(compressionQuality: 0.8)
                    let r1 = ArtworkRecord(title: "Leica M11 街拍", storagePolicy: .fullImage, thumbnailData: data, exportedImageData: data, diskSizeBytes: 1024 * 500)
                    let r2 = ArtworkRecord(title: "富士經典底片配方", storagePolicy: .settingsOnly, thumbnailData: data, diskSizeBytes: 1024 * 12)
                    let r3 = ArtworkRecord(title: "索尼 A7R5 風景", storagePolicy: .fullImage, thumbnailData: data, exportedImageData: data, diskSizeBytes: 1024 * 850)
                    modelContext.insert(r1)
                    modelContext.insert(r2)
                    modelContext.insert(r3)
                    try? modelContext.save()
                }
            }
    }
}

private struct ColorPickerTestContainer: View {
    @State private var h: Double = 0.58
    @State private var s: Double = 0.75
    @State private var b: Double = 0.88
    @State private var isPresented: Bool = true
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            Text("自訂顏色選擇器測試背景")
                .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $isPresented) {
            HSBColorPickerView(
                hue: $h,
                saturation: $s,
                brightness: $b,
                initialMode: ProcessInfo.processInfo.arguments.contains("-RGB") ? .rgb : .hsb
            )
        }
    }
}

#Preview {
    ContentView()
}
