import Foundation
import CoreGraphics

/// 四邊留白指示方向
public enum PaddingEdge: String, CaseIterable, Identifiable, Codable, Sendable {
    case top = "上"
    case bottom = "下"
    case left = "左"
    case right = "右"
    
    public var id: String { rawValue }
}

/// 留白與圓角數值單位
public enum MeasurementUnit: String, CaseIterable, Identifiable, Codable, Sendable {
    case percent = "%"
    case pixel = "px"
    
    public var id: String { rawValue }
}

/// 四邊留白與邊框調整設定
public struct BorderSettings: Codable, Equatable, Sendable {
    /// 留白單位
    public var unit: MeasurementUnit = .percent
    
    /// 上下左右留白數值（% 或 px）
    public var paddingTop: CGFloat = 20
    public var paddingBottom: CGFloat = 20
    public var paddingLeft: CGFloat = 20
    public var paddingRight: CGFloat = 20
    
    /// 目前是否處於「🔗 連結編輯模式」（點選尺標可指派/移除邊到目前編輯的連結組）
    public var isLinkedActive: Bool = false
    
    /// 連結組（固定兩個欄位：A = 索引 0、B = 索引 1）。
    /// 一條邊最多只屬於一組；成員少於 2 條邊的組不構成連結。預設 A 組為四邊連動。
    public var linkGroups: [Set<PaddingEdge>] = [Set(PaddingEdge.allCases), []]
    
    /// 連結編輯模式下，目前正在編輯的連結組索引（0 = A、1 = B）
    public var activeLinkSlot: Int = 0
    
    /// 當前選中調整的邊（在上方畫布白框或下方圖示中被高亮選中者）
    public var selectedEdges: Set<PaddingEdge> = Set(PaddingEdge.allCases)
    
    /// 照片圓角數值（% 或 px）
    public var cornerRadius: CGFloat = 0
    /// 照片圓角單位
    public var cornerRadiusUnit: MeasurementUnit = .percent
    
    public init() {}
    
    /// 所有已構成連結（成員 ≥ 2）的邊集合（兩組聯集）
    public var linkedEdges: Set<PaddingEdge> {
        linkGroups.filter { $0.count >= 2 }.reduce(into: Set<PaddingEdge>()) { $0.formUnion($1) }
    }
    
    /// 直接設定 A / B 兩組成員（若兩組有重疊，B 組讓位給 A 組）
    public mutating func setLinkGroups(a: Set<PaddingEdge>, b: Set<PaddingEdge>) {
        linkGroups = [a, b.subtracting(a)]
    }
    
    /// 某邊所屬的連結組索引（不論該組是否已構成連結；未歸屬則為 nil）
    public func groupIndex(of edge: PaddingEdge) -> Int? {
        linkGroups.firstIndex { $0.contains(edge) }
    }
    
    /// 某邊實際連動的邊集合：所屬組成員 ≥ 2 時為整組，否則僅自身
    public func linkedPeers(of edge: PaddingEdge) -> Set<PaddingEdge> {
        if let idx = groupIndex(of: edge), linkGroups[idx].count >= 2 {
            return linkGroups[idx]
        }
        return [edge]
    }
    
    // MARK: - Codable（相容舊版單組 linkedEdges）
    private enum CodingKeys: String, CodingKey {
        case unit, paddingTop, paddingBottom, paddingLeft, paddingRight
        case isLinkedActive, linkGroups, activeLinkSlot, linkedEdges, selectedEdges
        case cornerRadius, cornerRadiusUnit
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        unit = try c.decodeIfPresent(MeasurementUnit.self, forKey: .unit) ?? unit
        paddingTop = try c.decodeIfPresent(CGFloat.self, forKey: .paddingTop) ?? paddingTop
        paddingBottom = try c.decodeIfPresent(CGFloat.self, forKey: .paddingBottom) ?? paddingBottom
        paddingLeft = try c.decodeIfPresent(CGFloat.self, forKey: .paddingLeft) ?? paddingLeft
        paddingRight = try c.decodeIfPresent(CGFloat.self, forKey: .paddingRight) ?? paddingRight
        isLinkedActive = try c.decodeIfPresent(Bool.self, forKey: .isLinkedActive) ?? isLinkedActive
        activeLinkSlot = try c.decodeIfPresent(Int.self, forKey: .activeLinkSlot) ?? activeLinkSlot
        selectedEdges = try c.decodeIfPresent(Set<PaddingEdge>.self, forKey: .selectedEdges) ?? selectedEdges
        cornerRadius = try c.decodeIfPresent(CGFloat.self, forKey: .cornerRadius) ?? cornerRadius
        cornerRadiusUnit = try c.decodeIfPresent(MeasurementUnit.self, forKey: .cornerRadiusUnit) ?? cornerRadiusUnit
        if let groups = try c.decodeIfPresent([Set<PaddingEdge>].self, forKey: .linkGroups), groups.count == 2 {
            linkGroups = groups
        } else if let legacy = try c.decodeIfPresent(Set<PaddingEdge>.self, forKey: .linkedEdges) {
            linkGroups = [legacy, []]
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(unit, forKey: .unit)
        try c.encode(paddingTop, forKey: .paddingTop)
        try c.encode(paddingBottom, forKey: .paddingBottom)
        try c.encode(paddingLeft, forKey: .paddingLeft)
        try c.encode(paddingRight, forKey: .paddingRight)
        try c.encode(isLinkedActive, forKey: .isLinkedActive)
        try c.encode(linkGroups, forKey: .linkGroups)
        try c.encode(activeLinkSlot, forKey: .activeLinkSlot)
        try c.encode(selectedEdges, forKey: .selectedEdges)
        try c.encode(cornerRadius, forKey: .cornerRadius)
        try c.encode(cornerRadiusUnit, forKey: .cornerRadiusUnit)
    }
    
    /// 獲取特定邊的目前留白數值
    public func padding(for edge: PaddingEdge) -> CGFloat {
        switch edge {
        case .top: return paddingTop
        case .bottom: return paddingBottom
        case .left: return paddingLeft
        case .right: return paddingRight
        }
    }
    
    /// 在「🔗 連結編輯模式」下，將邊指派到目前編輯的連結組（activeLinkSlot）。
    /// 已在該組 → 移除；在另一組 → 從另一組移到此組（一條邊只屬於一組）；未歸屬 → 加入此組。
    public mutating func toggleEdgeInLinkMode(_ edge: PaddingEdge) {
        let slot = min(max(activeLinkSlot, 0), linkGroups.count - 1)
        if linkGroups[slot].contains(edge) {
            linkGroups[slot].remove(edge)
        } else {
            for i in linkGroups.indices { linkGroups[i].remove(edge) }
            linkGroups[slot].insert(edge)
        }
    }
    
    /// 使用者點選某一邊進行調整：若該邊屬於已構成連結的組，則整組同步選中；否則單獨選中該邊
    @discardableResult
    public mutating func selectEdgeForAdjustment(_ edge: PaddingEdge) -> Set<PaddingEdge> {
        if isLinkedActive {
            toggleEdgeInLinkMode(edge)
            selectedEdges = [edge]
        } else {
            selectedEdges = linkedPeers(of: edge)
        }
        return selectedEdges
    }
    
    /// 更新留白數值（連結編輯模式下只改單邊；否則同步更新該邊所屬連結組的所有邊）
    public mutating func updatePadding(for edge: PaddingEdge, value: CGFloat) {
        let targets: Set<PaddingEdge> = isLinkedActive ? [edge] : linkedPeers(of: edge)
        for target in targets {
            switch target {
            case .top: paddingTop = value
            case .bottom: paddingBottom = value
            case .left: paddingLeft = value
            case .right: paddingRight = value
            }
        }
    }
}
