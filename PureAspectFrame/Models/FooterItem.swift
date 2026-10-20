import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

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
    
    /// 檢查該積木在目前照片中是否具備有效資訊（若無資訊則應於倉庫禁選）
    public func hasAvailableInformation(exif: ExifMetadata, customText: String = "") -> Bool {
        switch self {
        case .logo:
            return exif.detectedBrand != .unknown || !(exif.make?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        case .camera:
            return !exif.cameraDisplayString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .lens:
            return !exif.lensDisplayString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .parameters:
            return !exif.parametersDisplayString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .date:
            return exif.dateTimeOriginal != nil
        case .customText:
            return !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .spacer:
            return true
        }
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
    
    /// 虛擬 pt 參考畫布短邊基準（將畫布短邊 min(width, height) 正規化為 1000 虛擬 pt）
    public static let referenceShortSidePt: CGFloat = 1000.0
    
    /// 虛擬 pt 調整範圍（支援最低 0.0 pt 到 36.0 pt）
    public static let fontSizePtRange: ClosedRange<Double> = 0.0...36.0
    
    /// 底欄字體大小比例（相對於畫布短邊，0.0 ~ 0.036 對應 0.0 ~ 36.0 虛擬 pt）
    public var fontSizeScale: Double = 0.018
    
    /// 底欄文字虛擬 pt 數值（以畫布短邊 1000 虛擬 pt 為基準之大寫字母實際高度 Cap Height，支援最低 0 pt）
    public var fontSizePt: Double {
        get { max(0.0, fontSizeScale * Double(Self.referenceShortSidePt)) }
        set { fontSizeScale = max(0.0, newValue / Double(Self.referenceShortSidePt)) }
    }
    
    /// 底欄文字顏色（自訂十六進位值，預設為灰色 #8E8E93 以搭配白底）
    public var textColorHex: String = "#8E8E93"
    
    public init() {}
    
    /// 計算在指定畫布像素/點尺寸下，大寫字母實際視覺高度 (Cap Height)
    /// 以畫布短邊 min(canvasWidth, canvasHeight) 為基準，確保不同長寬比與不同畫素下文字視覺大小一致
    public func targetCapHeight(canvasWidth: CGFloat, canvasHeight: CGFloat) -> CGFloat {
        guard isEnabled, fontSizeScale > 0 else { return 0.0 }
        let shortSide = min(max(0, canvasWidth), max(0, canvasHeight))
        return shortSide * CGFloat(fontSizeScale)
    }
    
    /// 將目標大寫字母高度 (Cap Height) 換算為系統字體所需的實際 Point Size (Em 框高度)
    public func resolvedFontPointSize(canvasWidth: CGFloat, canvasHeight: CGFloat) -> CGFloat {
        let capH = targetCapHeight(canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        guard capH > 0 else { return 0.0 }
        #if canImport(UIKit)
        let refFont = UIFont.systemFont(ofSize: 100.0, weight: .medium)
        let capRatio = max(0.1, refFont.capHeight / 100.0)
        return capH / capRatio
        #else
        return capH / 0.7046
        #endif
    }
    
    /// 計算在指定畫布尺寸下的底欄預留高度（直接與畫布短邊及文字實際高度連動，最低為 0）
    public func resolvedFooterHeight(canvasWidth: CGFloat, canvasHeight: CGFloat) -> CGFloat {
        let capH = targetCapHeight(canvasWidth: canvasWidth, canvasHeight: canvasHeight)
        guard capH > 0 else { return 0.0 }
        return capH * 3.2
    }
    
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
    
    /// 新增積木至底欄（若提供 exif 則驗證是否具備資訊，spacer 最多 2 個，其他積木不重複）
    public mutating func addItem(_ item: FooterItemType, exif: ExifMetadata? = nil) {
        if let exif = exif {
            guard item.hasAvailableInformation(exif: exif, customText: customText) else { return }
        }
        if item == .spacer {
            let currentSpacers = activeItems.filter { $0 == .spacer }.count
            guard currentSpacers < 2 else { return }
        } else {
            guard !activeItems.contains(item) else { return }
        }
        activeItems.append(item)
    }
}

