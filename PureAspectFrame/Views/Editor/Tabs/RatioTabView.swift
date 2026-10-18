import SwiftUI

/// 【比例】分頁視圖
public struct RatioTabView: View {
    @Binding var canvasRatio: CanvasRatio
    @Binding var internalRatio: InternalCropRatio
    @Binding var isZeroCrop: Bool
    
    public init(
        canvasRatio: Binding<CanvasRatio>,
        internalRatio: Binding<InternalCropRatio>,
        isZeroCrop: Binding<Bool>
    ) {
        self._canvasRatio = canvasRatio
        self._internalRatio = internalRatio
        self._isZeroCrop = isZeroCrop
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 1. 外部比例選擇列（含 SNS 與拍立得實體規格）
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("外部畫布比例")
                            .font(.headline)
                        Spacer()
                        Text(canvasRatio.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                                        Image(systemName: ratio.isPolaroid ? "photo.fill.on.rectangle.fill" : "aspectratio")
                                            .font(.system(size: 14))
                                        Text(ratio.rawValue)
                                            .font(.caption2.bold())
                                    }
                                    .frame(minWidth: 70, minHeight: 48)
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
