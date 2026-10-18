import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Settings") {
            SettingsView()
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-Editor") {
            let img = DemoImageProvider.makeDemoImage()
            EditorView(sourceImage: img, initialExif: DemoImageProvider.demoExif)
        } else if ProcessInfo.processInfo.arguments.contains("-UITestScreen-QuickImport") {
            let img = DemoImageProvider.makeDemoImage()
            QuickImportView(sourceImage: img, exifMetadata: DemoImageProvider.demoExif)
        } else {
            HomeView()
        }
    }
}

#Preview {
    ContentView()
}
