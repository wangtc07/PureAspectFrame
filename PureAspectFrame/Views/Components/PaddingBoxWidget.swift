import SwiftUI

/// 連結組的視覺識別（A = 藍、B = 橘）
public enum LinkGroupStyle {
    public static func color(_ index: Int) -> Color {
        index == 0 ? .blue : .orange
    }
    public static func name(_ index: Int) -> String {
        index == 0 ? "A" : "B"
    }
}

/// 邊界尺標圖形：上/下為羅馬字 I，左/右為羅馬字 H（外側線 = 畫布邊、內側線 = 相片邊）
struct CaliperShape: Shape {
    let edge: PaddingEdge
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch edge {
        case .top, .bottom:
            let outerY = edge == .top ? rect.minY + 7 : rect.maxY - 7
            let innerY = edge == .top ? rect.maxY - 3 : rect.minY + 3
            let x0 = rect.minX + 10, x1 = rect.maxX - 10
            p.move(to: CGPoint(x: x0, y: outerY)); p.addLine(to: CGPoint(x: x1, y: outerY))
            p.move(to: CGPoint(x: x0, y: innerY)); p.addLine(to: CGPoint(x: x1, y: innerY))
            p.move(to: CGPoint(x: rect.midX, y: outerY)); p.addLine(to: CGPoint(x: rect.midX, y: innerY))
        case .left, .right:
            let outerX = edge == .left ? rect.minX + 7 : rect.maxX - 7
            let innerX = edge == .left ? rect.maxX - 3 : rect.minX + 3
            let y0 = rect.minY + 10, y1 = rect.maxY - 10
            p.move(to: CGPoint(x: outerX, y: y0)); p.addLine(to: CGPoint(x: outerX, y: y1))
            p.move(to: CGPoint(x: innerX, y: y0)); p.addLine(to: CGPoint(x: innerX, y: y1))
            p.move(to: CGPoint(x: outerX, y: rect.midY)); p.addLine(to: CGPoint(x: innerX, y: rect.midY))
        }
        return p
    }
}

/// 四邊留白邊界尺標大圖示元件 (一個大圖示整合上下左右邊界尺標與點選調整)
///
/// 狀態一眼可辨：
/// - 已連結的邊：尺標與底色塊使用該組顏色（A 藍 / B 橘），同色 = 一起連動
/// - 目前調整中的邊：尺標加粗、底色加深並加外框
/// - 連結編輯模式：外框改為編輯組顏色的虛線，中央顯示連結圖示
public struct PaddingBoxWidget: View {
    public let selectedEdges: Set<PaddingEdge>
    public let linkGroups: [Set<PaddingEdge>]
    public var isLinkedActive: Bool = false
    public var activeLinkSlot: Int = 0
    public let onSelectEdge: (PaddingEdge) -> Void
    public var onSelectAll: (() -> Void)? = nil
    
    public init(
        selectedEdges: Set<PaddingEdge>,
        linkGroups: [Set<PaddingEdge>],
        isLinkedActive: Bool = false,
        activeLinkSlot: Int = 0,
        onSelectEdge: @escaping (PaddingEdge) -> Void,
        onSelectAll: (() -> Void)? = nil
    ) {
        self.selectedEdges = selectedEdges
        self.linkGroups = linkGroups
        self.isLinkedActive = isLinkedActive
        self.activeLinkSlot = activeLinkSlot
        self.onSelectEdge = onSelectEdge
        self.onSelectAll = onSelectAll
    }
    
    private var modeColor: Color { LinkGroupStyle.color(activeLinkSlot) }
    
    public var body: some View {
        ZStack {
            // 1. 底層容器；連結編輯模式時改為編輯組顏色的虛線框
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isLinkedActive ? modeColor.opacity(0.08) : Color.secondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isLinkedActive ? modeColor : Color.primary.opacity(0.1),
                            style: StrokeStyle(lineWidth: isLinkedActive ? 1.5 : 1, dash: isLinkedActive ? [4, 3] : [])
                        )
                )
            
            // 2. 中央相片方塊：點選全選
            Button {
                onSelectAll?()
            } label: {
                let allSelected = selectedEdges.count == 4
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(allSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.18))
                    .frame(width: 30, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(allSelected ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .overlay {
                        if isLinkedActive {
                            Image(systemName: "link")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(modeColor)
                        } else if allSelected {
                            Image(systemName: "square.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("全選四邊留白")
            
            // 3. 四方位尺標（觸控區互不重疊）
            VStack { caliper(.top); Spacer() }
            VStack { Spacer(); caliper(.bottom) }
            HStack { caliper(.left); Spacer() }
            HStack { Spacer(); caliper(.right) }
        }
        .frame(width: 74, height: 74)
        .animation(.easeInOut(duration: 0.15), value: isLinkedActive)
    }
    
    // MARK: - 單邊尺標
    private func groupIndex(of edge: PaddingEdge) -> Int? {
        linkGroups.firstIndex { $0.contains(edge) }
    }
    
    private func caliper(_ edge: PaddingEdge) -> some View {
        let isSelected = selectedEdges.contains(edge)
        let group = groupIndex(of: edge)
        let baseColor: Color = group.map { LinkGroupStyle.color($0) } ?? .secondary
        let strokeColor: Color = {
            if let group { return LinkGroupStyle.color(group) }
            return isSelected ? .accentColor : .secondary.opacity(0.5)
        }()
        let isVertical = edge == .left || edge == .right
        let size = isVertical ? CGSize(width: 23, height: 38) : CGSize(width: 38, height: 23)
        let groupName = group.map { "，連結 \(LinkGroupStyle.name($0))" } ?? "，未連結"
        
        return Button {
            onSelectEdge(edge)
        } label: {
            ZStack {
                if group != nil || isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(baseColor.opacity(isSelected ? 0.30 : 0.16))
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(strokeColor, lineWidth: 1.2)
                            }
                        }
                        .padding(1)
                }
                CaliperShape(edge: edge)
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: isSelected ? 2.8 : 1.8, lineCap: .round))
            }
            .frame(width: size.width, height: size.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(edge.rawValue)邊界尺標\(groupName)")
    }
}
