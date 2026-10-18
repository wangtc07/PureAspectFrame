import Foundation
import SwiftData

/// 歷史輸出作品記錄模型 (SwiftData)
@Model
public final class ArtworkRecord {
    public var id: UUID
    public var title: String
    /// 儲存策略：保留輸出圖片 (fullImage) 或 僅保留設定 (settingsOnly)
    public var storagePolicyRaw: String
    /// 相片庫 PHAsset identifier 或檔案 Security-Scoped Bookmark
    public var assetLocalIdentifier: String?
    public var bookmarkData: Data?
    
    /// 預覽用小縮圖（方便列表秒開）
    @Attribute(.externalStorage)
    public var thumbnailData: Data?
    
    /// 完整渲染完成圖檔（當 policy == .fullImage 時存在）
    @Attribute(.externalStorage)
    public var exportedImageData: Data?
    
    /// 當時套用之完整設定 JSON
    public var settingsJSON: String
    
    /// 拍攝 EXIF 資訊 JSON
    public var exifJSON: String?
    
    /// 佔用硬碟空間大約位元組數 (Bytes)
    public var diskSizeBytes: Int64
    
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled",
        storagePolicy: StoragePolicy = .settingsOnly,
        assetLocalIdentifier: String? = nil,
        bookmarkData: Data? = nil,
        thumbnailData: Data? = nil,
        exportedImageData: Data? = nil,
        settingsJSON: String = "{}",
        exifJSON: String? = nil,
        diskSizeBytes: Int64 = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.storagePolicyRaw = storagePolicy.rawValue
        self.assetLocalIdentifier = assetLocalIdentifier
        self.bookmarkData = bookmarkData
        self.thumbnailData = thumbnailData
        self.exportedImageData = exportedImageData
        self.settingsJSON = settingsJSON
        self.exifJSON = exifJSON
        self.diskSizeBytes = diskSizeBytes
        self.createdAt = createdAt
    }
    
    public var storagePolicy: StoragePolicy {
        StoragePolicy(rawValue: storagePolicyRaw) ?? .settingsOnly
    }
}
