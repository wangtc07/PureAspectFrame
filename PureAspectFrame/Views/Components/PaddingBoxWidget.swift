import SwiftUI

/// 四邊留白邊界尺標大圖示元件 (一個大圖示整合上下左右邊界尺標與點選調整)
public struct PaddingBoxWidget: View {
    public let selectedEdges: Set<PaddingEdge>
    public let linkedEdges: Set<PaddingEdge>
    public var isLinkedActive: Bool = false
    public let onSelectEdge: (PaddingEdge) -> Void
    public var onSelectAll: (() -> Void)? = nil
    
    public init(
        selectedEdges: Set<PaddingEdge>,
        linkedEdges: Set<PaddingEdge>,
        isLinkedActive: Bool = false,
        onSelectEdge: @escaping (PaddingEdge) -> Void,
        onSelectAll: (() -> Void)? = nil
    ) {
        self.selectedEdges = selectedEdges
        self.linkedEdges = linkedEdges
        self.isLinkedActive = isLinkedActive
        self.onSelectEdge = onSelectEdge
        self.onSelectAll = onSelectAll
    }
    
    public var body: some View {
        ZStack {
            // 1. 底層容器 (柔和圓角方塊背景)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(isLinkedActive ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.1), lineWidth: 1)
                )
            
            // 2. 中央相片本體示意方塊 (30x30) - 支援點選全選四邊
            Button {
                onSelectAll?()
            } label: {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(selectedEdges.count == 4 ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.18))
                    .frame(width: 30, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(selectedEdges.count == 4 ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .overlay {
                        if isLinkedActive {
                            Image(systemName: "link")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        } else if selectedEdges.count == 4 {
                            Image(systemName: "square.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(Color.accentColor.opacity(0.8))
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("全選四邊留白")
            
            // 3. 上方邊界尺標 (羅馬數字 I 示意: ━ | ━) - 頂部獨立觸控區
            VStack {
                topCaliper
                Spacer()
            }
            
            // 4. 下方邊界尺標 (羅馬數字 I 示意: ━ | ━) - 底部獨立觸控區
            VStack {
                Spacer()
                bottomCaliper
            }
            
            // 5. 左方邊界尺標 (羅馬數字 H 示意: | ━ |) - 左側獨立觸控區
            HStack {
                leftCaliper
                Spacer()
            }
            
            // 6. 右方邊界尺標 (羅馬數字 H 示意: | ━ |) - 右側獨立觸控區
            HStack {
                Spacer()
                rightCaliper
            }
        }
        .frame(width: 74, height: 74)
    }
    
    // MARK: - 上方尺標 (Top Caliper - 羅馬數字 I)
    private var topCaliper: some View {
        let isSelected = selectedEdges.contains(.top)
        let isLinked = linkedEdges.contains(.top)
        let strokeColor: Color = isSelected ? .accentColor : .secondary.opacity(0.45)
        let lineWidth: CGFloat = isSelected ? 2.5 : 1.5
        
        return Button {
            onSelectEdge(.top)
        } label: {
            ZStack {
                // 羅馬數字 I 尺標路徑
                Path { path in
                    // 外側邊界水平橫槓
                    path.move(to: CGPoint(x: 10, y: 7))
                    path.addLine(to: CGPoint(x: 28, y: 7))
                    // 內側相片邊界水平橫槓
                    path.move(to: CGPoint(x: 10, y: 20))
                    path.addLine(to: CGPoint(x: 28, y: 20))
                    // 垂直連接尺標 (形成羅馬字 I)
                    path.move(to: CGPoint(x: 19, y: 7))
                    path.addLine(to: CGPoint(x: 19, y: 20))
                }
                .stroke(strokeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 連結標記圓點
                if isLinked {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 3.5, height: 3.5)
                        .position(x: 19, y: 3.5)
                }
            }
            .frame(width: 38, height: 23)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("上邊界尺標")
    }
    
    // MARK: - 下方尺標 (Bottom Caliper - 羅馬數字 I)
    private var bottomCaliper: some View {
        let isSelected = selectedEdges.contains(.bottom)
        let isLinked = linkedEdges.contains(.bottom)
        let strokeColor: Color = isSelected ? .accentColor : .secondary.opacity(0.45)
        let lineWidth: CGFloat = isSelected ? 2.5 : 1.5
        
        return Button {
            onSelectEdge(.bottom)
        } label: {
            ZStack {
                // 羅馬數字 I 尺標路徑
                Path { path in
                    // 內側相片邊界水平橫槓
                    path.move(to: CGPoint(x: 10, y: 3))
                    path.addLine(to: CGPoint(x: 28, y: 3))
                    // 外側邊界水平橫槓
                    path.move(to: CGPoint(x: 10, y: 16))
                    path.addLine(to: CGPoint(x: 28, y: 16))
                    // 垂直連接尺標 (形成羅馬字 I)
                    path.move(to: CGPoint(x: 19, y: 3))
                    path.addLine(to: CGPoint(x: 19, y: 16))
                }
                .stroke(strokeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 連結標記圓點
                if isLinked {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 3.5, height: 3.5)
                        .position(x: 19, y: 19.5)
                }
            }
            .frame(width: 38, height: 23)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("下邊界尺標")
    }
    
    // MARK: - 左方尺標 (Left Caliper - 羅馬數字 H)
    private var leftCaliper: some View {
        let isSelected = selectedEdges.contains(.left)
        let isLinked = linkedEdges.contains(.left)
        let strokeColor: Color = isSelected ? .accentColor : .secondary.opacity(0.45)
        let lineWidth: CGFloat = isSelected ? 2.5 : 1.5
        
        return Button {
            onSelectEdge(.left)
        } label: {
            ZStack {
                // 羅馬數字 H 尺標路徑
                Path { path in
                    // 外側邊界垂直縱槓
                    path.move(to: CGPoint(x: 7, y: 10))
                    path.addLine(to: CGPoint(x: 7, y: 28))
                    // 內側相片邊界垂直縱槓
                    path.move(to: CGPoint(x: 20, y: 10))
                    path.addLine(to: CGPoint(x: 20, y: 28))
                    // 水平連接尺標 (形成羅馬字 H)
                    path.move(to: CGPoint(x: 7, y: 19))
                    path.addLine(to: CGPoint(x: 20, y: 19))
                }
                .stroke(strokeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 連結標記圓點
                if isLinked {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 3.5, height: 3.5)
                        .position(x: 3.5, y: 19)
                }
            }
            .frame(width: 23, height: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("左邊界尺標")
    }
    
    // MARK: - 右方尺標 (Right Caliper - 羅馬數字 H)
    private var rightCaliper: some View {
        let isSelected = selectedEdges.contains(.right)
        let isLinked = linkedEdges.contains(.right)
        let strokeColor: Color = isSelected ? .accentColor : .secondary.opacity(0.45)
        let lineWidth: CGFloat = isSelected ? 2.5 : 1.5
        
        return Button {
            onSelectEdge(.right)
        } label: {
            ZStack {
                // 羅馬數字 H 尺標路徑
                Path { path in
                    // 內側相片邊界垂直縱槓
                    path.move(to: CGPoint(x: 3, y: 10))
                    path.addLine(to: CGPoint(x: 3, y: 28))
                    // 外側邊界垂直縱槓
                    path.move(to: CGPoint(x: 16, y: 10))
                    path.addLine(to: CGPoint(x: 16, y: 28))
                    // 水平連接尺標 (形成羅馬字 H)
                    path.move(to: CGPoint(x: 3, y: 19))
                    path.addLine(to: CGPoint(x: 16, y: 19))
                }
                .stroke(strokeColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
                // 連結標記圓點
                if isLinked {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 3.5, height: 3.5)
                        .position(x: 19.5, y: 19)
                }
            }
            .frame(width: 23, height: 38)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("右邊界尺標")
    }
}
