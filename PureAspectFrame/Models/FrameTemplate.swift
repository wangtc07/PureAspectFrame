import Foundation
import SwiftData

/// 自訂畫布與排版模板模型 (SwiftData)
@Model
public final class FrameTemplate {
    public var id: UUID
    public var name: String
    public var canvasRatioRaw: String
    public var internalRatioRaw: String
    public var isZeroCrop: Bool
    
    // 邊框與留白設定以 JSON 格式持久化
    public var borderSettingsJSON: String
    // 背景設定以 JSON 格式持久化
    public var backgroundModeJSON: String
    // 底欄設定以 JSON 格式持久化
    public var footerSettingsJSON: String
    // 切割設定以 JSON 格式持久化
    public var splitSettingsJSON: String
    
    public var isBuiltIn: Bool
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        canvasRatio: CanvasRatio = .ig4x5,
        internalRatio: InternalCropRatio = .square1x1,
        isZeroCrop: Bool = false,
        borderSettings: BorderSettings = BorderSettings(),
        backgroundMode: BackgroundMode = .white,
        footerSettings: FooterSettings = FooterSettings(),
        splitSettings: SplitSettings = SplitSettings(),
        isBuiltIn: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.canvasRatioRaw = canvasRatio.rawValue
        self.internalRatioRaw = internalRatio.rawValue
        self.isZeroCrop = isZeroCrop
        
        let encoder = JSONEncoder()
        self.borderSettingsJSON = (try? String(data: encoder.encode(borderSettings), encoding: .utf8)) ?? "{}"
        self.backgroundModeJSON = (try? String(data: encoder.encode(backgroundMode), encoding: .utf8)) ?? "{}"
        self.footerSettingsJSON = (try? String(data: encoder.encode(footerSettings), encoding: .utf8)) ?? "{}"
        self.splitSettingsJSON = (try? String(data: encoder.encode(splitSettings), encoding: .utf8)) ?? "{}"
        
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }
    
    public var canvasRatio: CanvasRatio {
        CanvasRatio(rawValue: canvasRatioRaw) ?? .ig4x5
    }
    
    public var internalRatio: InternalCropRatio {
        InternalCropRatio(rawValue: internalRatioRaw) ?? .square1x1
    }
    
    public var borderSettings: BorderSettings {
        guard let data = borderSettingsJSON.data(using: .utf8),
              let settings = try? JSONDecoder().decode(BorderSettings.self, from: data) else {
            return BorderSettings()
        }
        return settings
    }
    
    public var backgroundMode: BackgroundMode {
        guard let data = backgroundModeJSON.data(using: .utf8),
              let mode = try? JSONDecoder().decode(BackgroundMode.self, from: data) else {
            return .white
        }
        return mode
    }
    
    public var footerSettings: FooterSettings {
        guard let data = footerSettingsJSON.data(using: .utf8),
              let settings = try? JSONDecoder().decode(FooterSettings.self, from: data) else {
            return FooterSettings()
        }
        return settings
    }
    
    public var splitSettings: SplitSettings {
        guard let data = splitSettingsJSON.data(using: .utf8),
              let settings = try? JSONDecoder().decode(SplitSettings.self, from: data) else {
            return SplitSettings()
        }
        return settings
    }
}
