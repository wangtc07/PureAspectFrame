import Foundation

/// 作品儲存策略
public enum StoragePolicy: String, CaseIterable, Identifiable, Codable, Sendable {
    case fullImage = "保留輸出圖片"
    case settingsOnly = "僅保留設定"
    
    public var id: String { rawValue }
}
