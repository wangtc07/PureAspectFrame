import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Settings") {
            SettingsView()
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
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Editor") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-QuickImport") {
            let img = DemoImageProvider.makeDemoImage()
            QuickImportView(sourceImage: img, exifMetadata: DemoImageProvider.demoExif)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-ColorPicker") {
            ColorPickerTestContainer()
        } else {
            HomeView()
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
