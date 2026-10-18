import Foundation

/// 作品儲存策略
public enum StoragePolicy: String, CaseIterable, Identifiable, Codable, Sendable {
    case fullImage = "保留輸出圖片"
    case settingsOnly = "僅保留設定"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .fullImage:
            return "保留輸出圖片：直接儲存渲染後的完整高解析圖檔至本機。"
        case .settingsOnly:
            return "僅保留設定：只儲存相片參照與編輯設定，瀏覽或再次導出時即時重繪，大幅節省空間。"
        }
    }
}
