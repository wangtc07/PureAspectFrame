import Foundation

/// 底欄積木類型
public enum FooterItemType: String, CaseIterable, Identifiable, Codable, Sendable {
    case logo = "品牌標誌"
    case camera = "相機機身"
    case lens = "鏡頭型號"
    case parameters = "拍攝參數"
    case date = "拍攝日期"
    case customText = "自訂簽名"
    case spacer = "間距調整"
    
    public var id: String { rawValue }
    
    public var isSpacer: Bool {
        self == .spacer
    }
    
    /// 取得尚未被使用的積木列表（下方倉庫動態過濾，spacer 最多可使用 2 個）
    public static func unusedItems(active: [FooterItemType]) -> [FooterItemType] {
        var list = allCases.filter { $0 != .spacer && !active.contains($0) }
        let spacerCount = active.filter { $0 == .spacer }.count
        if spacerCount < 2 {
            list.append(.spacer)
        }
        return list
    }
}

/// 底欄樣式與積木排版設定
public struct FooterSettings: Codable, Equatable, Sendable {
    /// 是否在相片下方顯示資訊底欄
    public var isEnabled: Bool = true
    
    /// 上方畫布底欄中已啟用的積木（左右排列順序，預設中間放置 spacer 分割左右兩側）
    public var activeItems: [FooterItemType] = [.logo, .camera, .spacer, .lens, .parameters]
    
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
    
    /// 依據 .spacer 分割出的區塊段落（Sections）
    /// - 0 個 spacer: 1 個 section -> 全部置中
    /// - 1 個 spacer: 2 個 sections -> section 0 靠左, section 1 靠右
    /// - 2 個 spacer: 3 個 sections -> section 0 靠左, section 1 置中, section 2 靠右
    public var layoutSections: [[FooterItemType]] {
        var sections: [[FooterItemType]] = [[]]
        for item in activeItems {
            if item == .spacer {
                sections.append([])
            } else {
                sections[sections.count - 1].append(item)
            }
        }
        return sections
    }
    
    /// 移動積木位置
    public mutating func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard activeItems.indices.contains(sourceIndex) else { return }
        let target = max(0, min(destinationIndex, activeItems.count - 1))
        guard sourceIndex != target else { return }
        let item = activeItems.remove(at: sourceIndex)
        activeItems.insert(item, at: target)
    }
    
    /// 交換相鄰或任意兩個積木位置
    public mutating func swapItems(at i: Int, with j: Int) {
        guard activeItems.indices.contains(i), activeItems.indices.contains(j), i != j else { return }
        activeItems.swapAt(i, j)
    }
    
    /// 新增積木至底欄（spacer 最多 2 個，其他積木不重複）
    public mutating func addItem(_ item: FooterItemType) {
        if item == .spacer {
            let currentSpacers = activeItems.filter { $0 == .spacer }.count
            guard currentSpacers < 2 else { return }
        } else {
            guard !activeItems.contains(item) else { return }
        }
        activeItems.append(item)
    }
}

