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
    
    /// 目前是否處於「🔗 連結編輯模式」（點選可加選/減選邊）
    public var isLinkedActive: Bool = false
    
    /// 已持久化連結的邊集合（預設四邊全開連結）
    public var linkedEdges: Set<PaddingEdge> = Set(PaddingEdge.allCases)
    
    /// 當前選中調整的邊（在上方畫布白框或下方圖示中被高亮選中者）
    public var selectedEdges: Set<PaddingEdge> = Set(PaddingEdge.allCases)
    
    /// 照片圓角數值（% 或 px）
    public var cornerRadius: CGFloat = 0
    /// 照片圓角單位
    public var cornerRadiusUnit: MeasurementUnit = .percent
    
    public init() {}
    
    /// 獲取特定邊的目前留白數值
    public func padding(for edge: PaddingEdge) -> CGFloat {
        switch edge {
        case .top: return paddingTop
        case .bottom: return paddingBottom
        case .left: return paddingLeft
        case .right: return paddingRight
        }
    }
    
    /// 在「🔗 連結編輯模式」下加選或減選邊
    public mutating func toggleEdgeInLinkMode(_ edge: PaddingEdge) {
        if linkedEdges.contains(edge) {
            linkedEdges.remove(edge)
        } else {
            linkedEdges.insert(edge)
        }
    }
    
    /// 使用者點選某一邊進行調整：若該邊屬於已連結群組，則群組內所有邊同步選中；否則單獨選中該邊
    @discardableResult
    public mutating func selectEdgeForAdjustment(_ edge: PaddingEdge) -> Set<PaddingEdge> {
        if isLinkedActive {
            toggleEdgeInLinkMode(edge)
            selectedEdges = [edge]
            return selectedEdges
        } else {
            if linkedEdges.contains(edge) {
                selectedEdges = linkedEdges
            } else {
                selectedEdges = [edge]
            }
            return selectedEdges
        }
    }
    
    /// 更新留白數值（若該邊在選中集合或連結集合中，同步更新受影響的邊）
    public mutating func updatePadding(for edge: PaddingEdge, value: CGFloat) {
        let targets: Set<PaddingEdge>
        if isLinkedActive {
            targets = [edge]
        } else if linkedEdges.contains(edge) {
            targets = linkedEdges
        } else {
            targets = [edge]
        }
        
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
