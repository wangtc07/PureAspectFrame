import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 首頁多選狀態模型
public struct ArtworkSelectionState: Sendable, Equatable {
    public var selectedIDs: Set<UUID> = []
    
    public init(selectedIDs: Set<UUID> = []) {
        self.selectedIDs = selectedIDs
    }
    
    public mutating func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
    
    public mutating func selectAll(from allIDs: [UUID]) {
        selectedIDs = Set(allIDs)
    }
    
    public mutating func deselectAll() {
        selectedIDs.removeAll()
    }
    
    public mutating func toggleSelectAll(from allIDs: [UUID]) {
        if selectedIDs.count == allIDs.count && !allIDs.isEmpty {
            deselectAll()
        } else {
            selectAll(from: allIDs)
        }
    }
    
    public func isSelected(_ id: UUID) -> Bool {
        selectedIDs.contains(id)
    }
}

/// 作品導出輔助工具
public enum ArtworkExportHelper {
    #if canImport(UIKit)
    public static func exportImage(for record: ArtworkRecord) -> UIImage? {
        if let data = record.exportedImageData, let img = UIImage(data: data) {
            return img
        }
        if let thumb = record.thumbnailData, let img = UIImage(data: thumb) {
            return img
        }
        return nil
    }
    
    public static func exportImages(for records: [ArtworkRecord]) -> [UIImage] {
        records.compactMap { exportImage(for: $0) }
    }
    #endif
}
