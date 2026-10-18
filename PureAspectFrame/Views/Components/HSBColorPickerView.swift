import SwiftUI

/// 支援 HSB、RGB 與 Hex 雙向連動之色彩選擇器
public struct HSBColorPickerView: View {
    @Binding var hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double
    @Environment(\.dismiss) private var dismiss
    
    public enum ColorPickerMode: String, CaseIterable, Identifiable {
        case hsb = "HSB"
        case rgb = "RGB"
        public var id: String { rawValue }
    }
    
    @State private var colorMode: ColorPickerMode
    @State private var red: Double = 0.0
    @State private var green: Double = 0.0
    @State private var blue: Double = 0.0
    @State private var hexInput: String = "FFFFFF"
    @FocusState private var isHexFocused: Bool
    
    public init(
        hue: Binding<Double>,
        saturation: Binding<Double>,
        brightness: Binding<Double>,
        initialMode: ColorPickerMode = .hsb
    ) {
        self._hue = hue
        self._saturation = saturation
        self._brightness = brightness
        self._colorMode = State(initialValue: initialMode)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // MARK: - 1. 上方色彩預覽區塊（含右下角 Hex 輸入欄位）
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                        .frame(height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 3)
                    
                    // 右下角 Hex 輸入欄位
                    HStack(spacing: 4) {
                        Text("#")
                            .font(.system(.subheadline, design: .monospaced, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        TextField("FFFFFF", text: $hexInput)
                            .font(.system(.subheadline, design: .monospaced, weight: .bold))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .frame(width: 72)
                            .focused($isHexFocused)
                            .onChange(of: hexInput) { _, newValue in
                                handleHexInputChange(newValue)
                            }
                            .onSubmit {
                                commitHexInput()
                            }
                            .onChange(of: isHexFocused) { _, focused in
                                if !focused {
                                    commitHexInput()
                                }
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .padding(12)
                }
                
                // MARK: - 2. HSB / RGB 分頁切換器 (Liquid Glass 自訂無縫切換列)
                HStack(spacing: 0) {
                    ForEach(ColorPickerMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                colorMode = mode
                                if mode == .rgb {
                                    syncRGBFromHSB()
                                } else {
                                    syncHSBFromRGB()
                                }
                            }
                        } label: {
                            Text(mode.rawValue)
                                .font(.subheadline.weight(colorMode == mode ? .semibold : .medium))
                                .foregroundStyle(colorMode == mode ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .background {
                                    if colorMode == mode {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(mode.rawValue) 模式")
                    }
                }
                .padding(3)
                .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // MARK: - 3. 滑桿控制區
                VStack(spacing: 16) {
                    if colorMode == .hsb {
                        hsbSlidersView
                    } else {
                        rgbSlidersView
                    }
                }
                .padding(18)
                .liquidGlass(cornerRadius: 20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .presentationDetents([.fraction(0.58), .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            syncRGBFromHSB()
        }
    }
    
    // MARK: - HSB 滑桿群組
    private var hsbSlidersView: some View {
        VStack(spacing: 14) {
            // 色相 (Hue 0 ~ 360°)
            HStack(spacing: 12) {
                Text("色相")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)
                
                GradientSlider(
                    value: $hue,
                    gradientColors: [
                        Color(hue: 0.0, saturation: 1.0, brightness: 1.0),
                        Color(hue: 0.167, saturation: 1.0, brightness: 1.0),
                        Color(hue: 0.333, saturation: 1.0, brightness: 1.0),
                        Color(hue: 0.5, saturation: 1.0, brightness: 1.0),
                        Color(hue: 0.667, saturation: 1.0, brightness: 1.0),
                        Color(hue: 0.833, saturation: 1.0, brightness: 1.0),
                        Color(hue: 1.0, saturation: 1.0, brightness: 1.0)
                    ],
                    onValueChanged: { _ in
                        syncRGBFromHSB()
                    }
                )
                
                SliderDirectValueInput(
                    value: $hue,
                    range: 0...360,
                    suffix: "°",
                    onCommit: {
                        syncRGBFromHSB()
                    }
                )
            }
            
            // 飽和度 (Saturation 0 ~ 100%)
            HStack(spacing: 12) {
                Text("飽和")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)
                
                GradientSlider(
                    value: $saturation,
                    gradientColors: [
                        Color(hue: hue, saturation: 0.0, brightness: max(brightness, 0.2)),
                        Color(hue: hue, saturation: 1.0, brightness: max(brightness, 0.2))
                    ],
                    onValueChanged: { _ in
                        syncRGBFromHSB()
                    }
                )
                
                SliderDirectValueInput(
                    value: $saturation,
                    range: 0...100,
                    suffix: "%",
                    onCommit: {
                        syncRGBFromHSB()
                    }
                )
            }
            
            // 亮度 (Brightness 0 ~ 100%)
            HStack(spacing: 12) {
                Text("亮度")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)
                
                GradientSlider(
                    value: $brightness,
                    gradientColors: [
                        Color(hue: hue, saturation: saturation, brightness: 0.0),
                        Color(hue: hue, saturation: saturation, brightness: 1.0)
                    ],
                    onValueChanged: { _ in
                        syncRGBFromHSB()
                    }
                )
                
                SliderDirectValueInput(
                    value: $brightness,
                    range: 0...100,
                    suffix: "%",
                    onCommit: {
                        syncRGBFromHSB()
                    }
                )
            }
        }
    }
    
    // MARK: - RGB 滑桿群組
    private var rgbSlidersView: some View {
        VStack(spacing: 14) {
            // 紅色 (Red 0 ~ 255)
            HStack(spacing: 12) {
                Text("紅")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)
                
                GradientSlider(
                    value: $red,
                    gradientColors: [
                        Color(red: 0.0, green: green, blue: blue),
                        Color(red: 1.0, green: green, blue: blue)
                    ],
                    onValueChanged: { _ in
                        syncHSBFromRGB()
                    }
                )
                
                SliderDirectValueInput(
                    value: $red,
                    range: 0...255,
                    suffix: "",
                    onCommit: {
                        syncHSBFromRGB()
                    }
                )
            }
            
            // 綠色 (Green 0 ~ 255)
            HStack(spacing: 12) {
                Text("綠")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)
                
                GradientSlider(
                    value: $green,
                    gradientColors: [
                        Color(red: red, green: 0.0, blue: blue),
                        Color(red: red, green: 1.0, blue: blue)
                    ],
                    onValueChanged: { _ in
                        syncHSBFromRGB()
                    }
                )
                
                SliderDirectValueInput(
                    value: $green,
                    range: 0...255,
                    suffix: "",
                    onCommit: {
                        syncHSBFromRGB()
                    }
                )
            }
            
            // 藍色 (Blue 0 ~ 255)
            HStack(spacing: 12) {
                Text("藍")
                    .font(.subheadline.weight(.medium))
                    .frame(width: 44, alignment: .leading)
                
                GradientSlider(
                    value: $blue,
                    gradientColors: [
                        Color(red: red, green: green, blue: 0.0),
                        Color(red: red, green: green, blue: 1.0)
                    ],
                    onValueChanged: { _ in
                        syncHSBFromRGB()
                    }
                )
                
                SliderDirectValueInput(
                    value: $blue,
                    range: 0...255,
                    suffix: "",
                    onCommit: {
                        syncHSBFromRGB()
                    }
                )
            }
        }
    }
    
    // MARK: - 數值同步邏輯
    
    private func syncRGBFromHSB() {
        let rgb = ColorSpaceService.hsbToRgb(h: hue, s: saturation, b: brightness)
        self.red = rgb.r
        self.green = rgb.g
        self.blue = rgb.b
        if !isHexFocused {
            self.hexInput = ColorSpaceService.rgbToHex(r: rgb.r, g: rgb.g, b: rgb.b)
                .replacingOccurrences(of: "#", with: "")
        }
    }
    
    private func syncHSBFromRGB() {
        let hsb = ColorSpaceService.rgbToHsb(r: red, g: green, b: blue)
        if hsb.s > 0.01 {
            self.hue = hsb.h
        }
        self.saturation = hsb.s
        self.brightness = hsb.b
        if !isHexFocused {
            self.hexInput = ColorSpaceService.rgbToHex(r: red, g: green, b: blue)
                .replacingOccurrences(of: "#", with: "")
        }
    }
    
    private func handleHexInputChange(_ newValue: String) {
        var clean = newValue.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("#") {
            clean.removeFirst()
        }
        let filtered = clean.filter { "0123456789ABCDEF".contains($0) }
        let trimmed = String(filtered.prefix(6))
        if trimmed != hexInput {
            hexInput = trimmed
        }
        if trimmed.count == 6 {
            applyHex(trimmed)
        }
    }
    
    private func commitHexInput() {
        let padded = hexInput.padding(toLength: 6, withPad: "0", startingAt: 0)
        applyHex(padded)
        hexInput = padded
    }
    
    private func applyHex(_ hex: String) {
        guard let rgb = ColorSpaceService.hexToRgb("#" + hex) else { return }
        self.red = rgb.r
        self.green = rgb.g
        self.blue = rgb.b
        let hsb = ColorSpaceService.rgbToHsb(r: rgb.r, g: rgb.g, b: rgb.b)
        if hsb.s > 0.01 {
            self.hue = hsb.h
        }
        self.saturation = hsb.s
        self.brightness = hsb.b
    }
}

// MARK: - 漸層軌道自訂滑桿 (GradientSlider)
public struct GradientSlider: View {
    @Binding var value: Double // 0.0 ... 1.0
    let gradientColors: [Color]
    var onValueChanged: ((Double) -> Void)? = nil
    
    public init(value: Binding<Double>, gradientColors: [Color], onValueChanged: ((Double) -> Void)? = nil) {
        self._value = value
        self.gradientColors = gradientColors
        self.onValueChanged = onValueChanged
    }
    
    public var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let thumbDiameter: CGFloat = 26
            let usableWidth = max(totalWidth - thumbDiameter, 1)
            let currentOffset = CGFloat(min(max(value, 0.0), 1.0)) * usableWidth
            
            ZStack(alignment: .leading) {
                // 漸層軌道
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 18)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .padding(.horizontal, thumbDiameter / 2)
                
                // 滑塊 (Thumb)
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1.5)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .offset(x: currentOffset)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let rawX = gesture.location.x - (thumbDiameter / 2)
                        let clampedX = min(max(rawX, 0), usableWidth)
                        let newValue = Double(clampedX / usableWidth)
                        value = newValue
                        onValueChanged?(newValue)
                    }
            )
        }
        .frame(height: 32)
    }
}

// MARK: - 滑桿直接數值輸入組件 (SliderDirectValueInput)
public struct SliderDirectValueInput: View {
    @Binding var value: Double // 0.0 ... 1.0
    let range: ClosedRange<Double> // 例如 0...360 或 0...100 或 0...255
    let suffix: String
    var onCommit: (() -> Void)? = nil
    
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    public init(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String,
        onCommit: (() -> Void)? = nil
    ) {
        self._value = value
        self.range = range
        self.suffix = suffix
        self.onCommit = onCommit
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                .focused($isFocused)
                .onChange(of: text) { _, newText in
                    handleTextChange(newText)
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        commitText()
                    }
                }
                .onSubmit {
                    commitText()
                }
            
            if !suffix.isEmpty {
                Text(suffix)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(width: 58, height: 30)
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            updateTextFromValue()
        }
        .onChange(of: value) { _, _ in
            if !isFocused {
                updateTextFromValue()
            }
        }
    }
    
    private func updateTextFromValue() {
        let displayVal = (value * (range.upperBound - range.lowerBound) + range.lowerBound).rounded()
        text = String(format: "%.0f", displayVal)
    }
    
    private func handleTextChange(_ newText: String) {
        guard isFocused else { return }
        let filtered = newText.filter { "0123456789".contains($0) }
        if filtered != newText {
            text = filtered
        }
        if let num = Double(filtered) {
            if num >= range.lowerBound && num <= range.upperBound {
                value = (num - range.lowerBound) / (range.upperBound - range.lowerBound)
                onCommit?()
            }
        }
    }
    
    private func commitText() {
        if let num = Double(text) {
            let clamped = min(max(num, range.lowerBound), range.upperBound)
            value = (clamped - range.lowerBound) / (range.upperBound - range.lowerBound)
            updateTextFromValue()
            onCommit?()
        } else {
            updateTextFromValue()
        }
    }
}
