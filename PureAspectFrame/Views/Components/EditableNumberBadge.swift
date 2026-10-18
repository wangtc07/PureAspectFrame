import SwiftUI

/// 支援直接點選/雙擊輸入數值與滑動滾輪式直調的標籤框
public struct EditableNumberBadge: View {
    @Binding var value: CGFloat
    var unit: String
    var title: String? = nil
    var range: ClosedRange<CGFloat> = 0...200
    var requireDoubleTapToEdit: Bool = true
    var enableScrubber: Bool = true
    var onSelect: (() -> Void)? = nil
    
    @State private var isEditing: Bool = false
    @State private var textInput: String = ""
    @State private var isDragging: Bool = false
    @State private var dragStartValue: CGFloat = 0
    @State private var lastFeedbackInt: Int? = nil
    
    public init(
        value: Binding<CGFloat>,
        unit: String,
        title: String? = nil,
        range: ClosedRange<CGFloat> = 0...200,
        requireDoubleTapToEdit: Bool = true,
        enableScrubber: Bool = true,
        onSelect: (() -> Void)? = nil
    ) {
        self._value = value
        self.unit = unit
        self.title = title
        self.range = range
        self.requireDoubleTapToEdit = requireDoubleTapToEdit
        self.enableScrubber = enableScrubber
        self.onSelect = onSelect
    }
    
    /// 計算滑動滾輪式調整後的新數值 (往上滑 translationY < 0 增加數值，往下滑減少)
    public static func calculateScrubbedValue(
        startValue: CGFloat,
        translationY: CGFloat,
        sensitivity: CGFloat = 3.0,
        range: ClosedRange<CGFloat>
    ) -> CGFloat {
        let deltaPoints = -translationY
        let deltaValue = deltaPoints / sensitivity
        let newValue = startValue + deltaValue
        return min(max(newValue, range.lowerBound), range.upperBound)
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            if isDragging {
                Image(systemName: "arrow.up.and.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
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
                        .strokeBorder(isDragging ? Color.accentColor : Color.primary.opacity(0.15), lineWidth: isDragging ? 1.5 : 0.8)
                }
        }
        .scaleEffect(isDragging ? 1.08 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
        .contentShape(Capsule())
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { gesture in
                    guard enableScrubber else { return }
                    if !isDragging {
                        isDragging = true
                        dragStartValue = value
                        lastFeedbackInt = Int(round(value))
                    }
                    let scrubbed = Self.calculateScrubbedValue(
                        startValue: dragStartValue,
                        translationY: gesture.translation.height,
                        sensitivity: 3.0,
                        range: range
                    )
                    value = scrubbed
                    
                    let roundedInt = Int(round(scrubbed))
                    if roundedInt != lastFeedbackInt {
                        lastFeedbackInt = roundedInt
                        #if canImport(UIKit)
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        #endif
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    lastFeedbackInt = nil
                }
        )
        .onTapGesture(count: 2) {
            textInput = String(format: "%.0f", value)
            isEditing = true
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }
        .onTapGesture(count: 1) {
            if !requireDoubleTapToEdit {
                textInput = String(format: "%.0f", value)
                isEditing = true
            } else {
                onSelect?()
            }
        }
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
