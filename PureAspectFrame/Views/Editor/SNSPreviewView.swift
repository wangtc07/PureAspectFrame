import SwiftUI

/// SNS 平台種類
public enum SNSTargetPlatform: String, CaseIterable, Identifiable {
    case instagram = "Instagram"
    case threads = "Threads"
    case xTwitter = "X (Twitter)"
    case redBook = "小紅書"
    
    public var id: String { rawValue }
    
    public var postCornerRadius: CGFloat {
        switch self {
        case .instagram: return 0
        case .threads: return 12
        case .xTwitter: return 16
        case .redBook: return 8
        }
    }
}

/// SNS 發佈模擬預覽視圖
public struct SNSPreviewView: View {
    var renderedImage: CGImage?
    var slices: [CGImage]
    
    @State private var selectedPlatform: SNSTargetPlatform = .instagram
    @Environment(\.dismiss) private var dismiss
    
    public init(renderedImage: CGImage?, slices: [CGImage]) {
        self.renderedImage = renderedImage
        self.slices = slices
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 平台切換分頁標籤
                Picker("發佈平台", selection: $selectedPlatform) {
                    ForEach(SNSTargetPlatform.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // 模擬社群動態卡片
                VStack(alignment: .leading, spacing: 10) {
                    // 模擬社群貼文頭部
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.accentColor.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.white)
                                    .font(.caption)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("pureaspect.photo")
                                .font(.caption.bold())
                            Text(selectedPlatform.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    
                    // 圖片展示區（單圖或多圖切割輪播）
                    if !slices.isEmpty && slices.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: selectedPlatform == .instagram ? 0 : 4) {
                                ForEach(0..<slices.count, id: \.self) { idx in
                                    Image(decorative: slices[idx], scale: 1.0)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 320)
                                        .clipShape(RoundedRectangle(cornerRadius: selectedPlatform.postCornerRadius, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    } else if let img = renderedImage {
                        Image(decorative: img, scale: 1.0)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 340)
                            .clipShape(RoundedRectangle(cornerRadius: selectedPlatform.postCornerRadius, style: .continuous))
                            .padding(.horizontal, 12)
                    }
                    
                    // 模擬點讚互動列
                    HStack(spacing: 16) {
                        Image(systemName: "heart")
                        Image(systemName: "bubble.right")
                        Image(systemName: "paperplane")
                        Spacer()
                        Image(systemName: "bookmark")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                }
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("SNS 發佈預覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
}
