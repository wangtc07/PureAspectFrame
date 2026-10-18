import Foundation

/// 底欄積木類型
public enum FooterItemType: String, CaseIterable, Identifiable, Codable, Sendable {
    case logo = "品牌標誌"
    case camera = "相機機身"
    case lens = "鏡頭型號"
    case parameters = "拍攝參數"
    case date = "拍攝日期"
    case customText = "自訂簽名"
    
    public var id: String { rawValue }
    
    /// 取得尚未被使用的積木列表（下方倉庫動態過濾）
    public static func unusedItems(active: [FooterItemType]) -> [FooterItemType] {
        allCases.filter { !active.contains($0) }
    }
}

/// 底欄樣式與積木排版設定
public struct FooterSettings: Codable, Equatable, Sendable {
    /// 是否在相片下方顯示資訊底欄
    public var isEnabled: Bool = true
    
    /// 上方畫布底欄中已啟用的積木（左右排列順序）
    public var activeItems: [FooterItemType] = [.logo, .camera, .lens, .parameters]
    
    /// 自訂文字內容（當 activeItems 包含 customText 時顯示）
    public var customText: String = "Shot on PureAspect"
    
    /// 底欄字體大小比例（相對於畫布基準高度，例如 0.018 ~ 0.035）
    public var fontSizeScale: Double = 0.024
    
    /// 底欄文字顏色（自訂十六進位值或黑白）
    public var textColorHex: String = "#333333"
    
    public init() {}
    
    /// 下方倉庫可用的未啟用積木
    public var availableUnusedItems: [FooterItemType] {
        FooterItemType.unusedItems(active: activeItems)
    }
}
