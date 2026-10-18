import SwiftUI

/// 支援直接點選輸入數值的標籤框
public struct EditableNumberBadge: View {
    @Binding var value: CGFloat
    var unit: String
    var title: String? = nil
    var range: ClosedRange<CGFloat> = 0...200
    
    @State private var isEditing: Bool = false
    @State private var textInput: String = ""
    
    public init(
        value: Binding<CGFloat>,
        unit: String,
        title: String? = nil,
        range: ClosedRange<CGFloat> = 0...200
    ) {
        self._value = value
        self.unit = unit
        self.title = title
        self.range = range
    }
    
    public var body: some View {
        Button {
            textInput = String(format: "%.0f", value)
            isEditing = true
        } label: {
            HStack(spacing: 3) {
                if let t = title {
                    Text(t)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(String(format: "%.0f", value))
                    .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 0.8)
                    }
            }
        }
        .buttonStyle(.plain)
        .alert("修改數值", isPresented: $isEditing) {
            TextField("請輸入數值 (\(unit))", text: $textInput)
                .keyboardType(.numberPad)
            Button("確定") {
                if let doubleVal = Double(textInput) {
                    let clamped = min(max(CGFloat(doubleVal), range.lowerBound), range.upperBound)
                    value = clamped
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("請輸入 \(title ?? "數值")，範圍 \(Int(range.lowerBound)) ~ \(Int(range.upperBound)) \(unit)")
        }
    }
}
