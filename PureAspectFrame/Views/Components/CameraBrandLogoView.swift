import SwiftUI

/// 相機品牌向量圖示與經典字標
public struct CameraBrandLogoView: View {
    public var brand: CameraBrand
    public var height: CGFloat = 16
    
    public init(brand: CameraBrand, height: CGFloat = 16) {
        self.brand = brand
        self.height = height
    }
    
    public var body: some View {
        Group {
            switch brand {
            case .leica:
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: height, height: height)
                        .overlay {
                            Text("L")
                                .font(.system(size: height * 0.7, weight: .bold, design: .serif))
                                .italic()
                                .foregroundStyle(.white)
                        }
                    Text("Leica")
                        .font(.system(size: height * 0.9, weight: .bold, design: .serif))
                        .italic()
                }
            case .sony:
                Text("SONY")
                    .font(.system(size: height * 0.85, weight: .black, design: .default))
                    .tracking(2.0)
            case .canon:
                Text("Canon")
                    .font(.system(size: height * 0.95, weight: .bold, design: .serif))
            case .nikon:
                Text("Nikon")
                    .font(.system(size: height * 0.9, weight: .heavy, design: .default))
                    .italic()
            case .fujifilm:
                HStack(spacing: 2) {
                    Text("FUJIFILM")
                        .font(.system(size: height * 0.85, weight: .black, design: .default))
                        .tracking(1.0)
                    Circle()
                        .fill(Color.red)
                        .frame(width: 4, height: 4)
                }
            case .apple:
                Image(systemName: "apple.logo")
                    .font(.system(size: height))
            case .hasselblad:
                Text("HASSELBLAD")
                    .font(.system(size: height * 0.7, weight: .black, design: .monospaced))
                    .tracking(1.5)
            case .ricoh:
                Text("RICOH")
                    .font(.system(size: height * 0.85, weight: .bold, design: .default))
                    .tracking(1.0)
            case .lumix:
                Text("LUMIX")
                    .font(.system(size: height * 0.85, weight: .heavy, design: .default))
                    .italic()
            case .zeiss:
                Text("ZEISS")
                    .font(.system(size: height * 0.85, weight: .bold, design: .default))
                    .foregroundStyle(.blue)
            case .olympus:
                Text("OLYMPUS")
                    .font(.system(size: height * 0.85, weight: .heavy, design: .default))
            case .unknown:
                Image(systemName: "camera.fill")
                    .font(.system(size: height * 0.9))
            }
        }
    }
}
