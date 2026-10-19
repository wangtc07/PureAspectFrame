import SwiftUI

/// 【比例】分頁視圖
public struct RatioTabView: View {
    @Binding var canvasRatio: CanvasRatio
    @Binding var isLandscape: Bool
    @Binding var internalRatio: InternalCropRatio
    @Binding var isZeroCrop: Bool
    
    public init(
        canvasRatio: Binding<CanvasRatio>,
        isLandscape: Binding<Bool> = .constant(false),
        internalRatio: Binding<InternalCropRatio>,
        isZeroCrop: Binding<Bool>
    ) {
        self._canvasRatio = canvasRatio
        self._isLandscape = isLandscape
        self._internalRatio = internalRatio
        self._isZeroCrop = isZeroCrop
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 1. 外部比例選擇列（含原圖比例、SNS 與拍立得實體規格）
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("外部畫布比例")
                            .font(.headline)
                        Spacer()
                        
                        // 右上：橫式 / 直式 切換開關
                        HStack(spacing: 2) {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isLandscape = false
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "rectangle.portrait")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("直式")
                                        .font(.caption2.bold())
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .contentShape(Capsule())
                                .background {
                                    if !isLandscape {
                                        Capsule().fill(Color.accentColor)
                                    } else {
                                        Capsule().fill(Color.clear)
                                    }
                                }
                                .foregroundStyle(!isLandscape ? Color.white : Color.primary)
                            }
                            .buttonStyle(.borderless)
                            
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isLandscape = true
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "rectangle")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("橫式")
                                        .font(.caption2.bold())
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .contentShape(Capsule())
                                .background {
                                    if isLandscape {
                                        Capsule().fill(Color.accentColor)
                                    } else {
                                        Capsule().fill(Color.clear)
                                    }
                                }
                                .foregroundStyle(isLandscape ? Color.white : Color.primary)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(2)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                        .sensoryFeedback(.selection, trigger: isLandscape)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CanvasRatio.allCases) { ratio in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        canvasRatio = ratio
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        CanvasRatioIconView(
                                            ratio: ratio,
                                            isLandscape: isLandscape,
                                            isSelected: canvasRatio == ratio
                                        )
                                        Text(ratio.displayName(isLandscape: isLandscape))
                                            .font(.caption2.bold())
                                    }
                                    .frame(minWidth: 72, minHeight: 48)
                                    .padding(.horizontal, 6)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(canvasRatio == ratio ? Color.accentColor : Color.primary.opacity(0.06))
                                    }
                                    .foregroundStyle(canvasRatio == ratio ? Color.white : Color.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
                
                // 2. 內部比例與零裁切
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("零裁切（原圖比例）")
                                .font(.headline)
                            Text("開啟後鎖定原圖原始比例，不作任何裁切")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $isZeroCrop)
                            .labelsHidden()
                    }
                    
                    Divider()
                        .opacity(0.3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("內部相片框比例")
                                .font(.subheadline.bold())
                            Spacer()
                            if isZeroCrop {
                                Text("已鎖定原圖比例")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            } else {
                                Text(internalRatio.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(InternalCropRatio.allCases) { r in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        internalRatio = r
                                    }
                                } label: {
                                    Text(r.rawValue)
                                        .font(.caption.bold())
                                        .frame(maxWidth: .infinity, minHeight: 36)
                                        .background {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(internalRatio == r && !isZeroCrop ? Color.accentColor : Color.primary.opacity(0.06))
                                        }
                                        .foregroundStyle(internalRatio == r && !isZeroCrop ? Color.white : Color.primary)
                                }
                                .buttonStyle(.plain)
                                .disabled(isZeroCrop)
                                .opacity(isZeroCrop ? 0.4 : 1.0)
                            }
                        }
                    }
                }
                .padding()
                .liquidGlass(cornerRadius: 16)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

/// 各畫布比例之專屬專用圖示視圖（依比例幾何、橫直式自適應縮放）
public struct CanvasRatioIconView: View {
    public let ratio: CanvasRatio
    public let isLandscape: Bool
    public let isSelected: Bool
    
    public init(ratio: CanvasRatio, isLandscape: Bool, isSelected: Bool) {
        self.ratio = ratio
        self.isLandscape = isLandscape
        self.isSelected = isSelected
    }
    
    public var body: some View {
        let strokeColor = isSelected ? Color.white : Color.primary
        let fillColor = isSelected ? Color.white.opacity(0.35) : Color.primary.opacity(0.12)
        
        Group {
            switch ratio {
            case .original:
                // 原圖比例：照片畫框圖示
                Image(systemName: "photo")
                    .font(.system(size: 13, weight: .medium))
            case .square1x1:
                // 1:1 正方形
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1.3)
                    .frame(width: 14, height: 14)
            case .ig4x5:
                // 4:5 (直式) 或 5:4 (橫式)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1.3)
                    .frame(width: isLandscape ? 15 : 12, height: isLandscape ? 12 : 15)
            case .xhs3x4:
                // 3:4 (直式) 或 4:3 (橫式)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1.3)
                    .frame(width: isLandscape ? 15 : 11.2, height: isLandscape ? 11.2 : 15)
            case .story9x16:
                // 9:16 (直式) 或 16:9 (橫式)
                RoundedRectangle(cornerRadius: 2.2, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1.3)
                    .frame(width: isLandscape ? 16 : 9, height: isLandscape ? 9 : 16)
            case .landscape16x9:
                // 16:9 (橫式) 或 9:16 (直式)
                RoundedRectangle(cornerRadius: 2.2, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 1.3)
                    .frame(width: isLandscape ? 16 : 9, height: isLandscape ? 9 : 16)
            case .polaroidMini:
                // Mini 拍立得
                polaroidBadge(
                    outerW: isLandscape ? 16 : 11,
                    outerH: isLandscape ? 11 : 16,
                    innerW: isLandscape ? 10 : 7,
                    innerH: isLandscape ? 7 : 10,
                    strokeColor: strokeColor,
                    fillColor: fillColor
                )
            case .polaroidSquare:
                // Square 拍立得
                polaroidBadge(
                    outerW: isLandscape ? 16 : 13,
                    outerH: isLandscape ? 13 : 16,
                    innerW: isLandscape ? 10 : 9,
                    innerH: isLandscape ? 9 : 10,
                    strokeColor: strokeColor,
                    fillColor: fillColor
                )
            case .polaroidWide:
                // Wide 拍立得
                polaroidBadge(
                    outerW: isLandscape ? 16 : 14,
                    outerH: isLandscape ? 14 : 16,
                    innerW: isLandscape ? 12 : 10,
                    innerH: isLandscape ? 8 : 10,
                    strokeColor: strokeColor,
                    fillColor: fillColor
                )
            }
        }
        .frame(width: 18, height: 18)
    }
    
    @ViewBuilder
    private func polaroidBadge(
        outerW: CGFloat,
        outerH: CGFloat,
        innerW: CGFloat,
        innerH: CGFloat,
        strokeColor: Color,
        fillColor: Color
    ) -> some View {
        ZStack(alignment: isLandscape ? .leading : .top) {
            RoundedRectangle(cornerRadius: 1.8, style: .continuous)
                .strokeBorder(strokeColor, lineWidth: 1.2)
                .frame(width: outerW, height: outerH)
            
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(fillColor)
                .frame(width: innerW, height: innerH)
                .padding(isLandscape ? .leading : .top, 1.8)
                .padding(isLandscape ? .trailing : .bottom, 3.2)
        }
    }
}
