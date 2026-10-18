import SwiftUI

/// HSB 色相、飽和度、亮度色彩選擇器
public struct HSBColorPickerView: View {
    @Binding var hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double
    @Environment(\.dismiss) private var dismiss
    
    public init(hue: Binding<Double>, saturation: Binding<Double>, brightness: Binding<Double>) {
        self._hue = hue
        self._saturation = saturation
        self._brightness = brightness
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 即時色彩預覽圓
                Circle()
                    .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                    }
                    .shadow(radius: 10)
                    .padding(.top, 16)
                
                VStack(spacing: 16) {
                    // 色相 (Hue 0 ~ 1)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("色相 (Hue)")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f°", hue * 360))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $hue, in: 0...1)
                            .tint(.purple)
                    }
                    
                    // 飽和度 (Saturation 0 ~ 1)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("飽和度 (Saturation)")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f%%", saturation * 100))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $saturation, in: 0...1)
                            .tint(.blue)
                    }
                    
                    // 亮度 (Brightness 0 ~ 1)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("亮度 (Brightness)")
                                .font(.subheadline)
                            Spacer()
                            Text(String(format: "%.0f%%", brightness * 100))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $brightness, in: 0...1)
                            .tint(.orange)
                    }
                }
                .padding(20)
                .liquidGlass(cornerRadius: 20)
                
                Spacer()
            }
            .padding()
            .navigationTitle("自訂 HSB 背景色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
