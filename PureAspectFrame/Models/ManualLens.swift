import Foundation
import SwiftData

/// 手動老鏡設備庫模型 (SwiftData)
@Model
public final class ManualLens {
    public var id: UUID
    public var name: String
    public var focalLength: Double
    public var maxAperture: Double
    public var brand: String
    public var isFavorite: Bool
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        focalLength: Double,
        maxAperture: Double,
        brand: String = "",
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.focalLength = focalLength
        self.maxAperture = maxAperture
        self.brand = brand
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }
    
    public var displayTitle: String {
        let apertureStr: String
        if maxAperture.truncatingRemainder(dividingBy: 1) == 0 {
            apertureStr = "\(Int(maxAperture))"
        } else if (maxAperture * 10).truncatingRemainder(dividingBy: 1) == 0 {
            apertureStr = String(format: "%.1f", maxAperture)
        } else {
            apertureStr = String(format: "%.2f", maxAperture)
        }
        return "\(name) (\(Int(focalLength))mm f/\(apertureStr))"
    }
}
