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
    
    public var supportsPinchToMerge: Bool {
        self == .threads
    }
}

/// SNS 發佈模擬預覽視圖
public struct SNSPreviewView: View {
    var renderedImage: CGImage?
    var slices: [CGImage]
    
    @State private var selectedPlatform: SNSTargetPlatform
    @State private var instagramPageIndex: Int = 0
    @State private var isThreadsMerged: Bool
    @State private var threadsPinchScale: CGFloat = 1.0
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Threads 雙圖捏合幾何常數與計算
    public static func threadsGap(isMerged: Bool) -> CGFloat {
        isMerged ? 0.0 : 6.0
    }
    
    public static func threadsInnerCornerRadius(isMerged: Bool) -> CGFloat {
        isMerged ? 0.0 : 12.0
    }
    
    public init(
        renderedImage: CGImage?,
        slices: [CGImage],
        initialPlatform: SNSTargetPlatform = .instagram,
        initialInstagramPageIndex: Int = 0,
        initialIsThreadsMerged: Bool = false
    ) {
        self.renderedImage = renderedImage
        self.slices = slices
        self._selectedPlatform = State(initialValue: initialPlatform)
        self._instagramPageIndex = State(initialValue: initialInstagramPageIndex)
        self._isThreadsMerged = State(initialValue: initialIsThreadsMerged)
    }
    
    private var displayImages: [CGImage] {
        if !slices.isEmpty && slices.count > 1 {
            return slices
        } else if let img = renderedImage {
            return [img]
        }
        return []
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                // 1. 平台切換分段選擇器
                Picker("發佈平台", selection: $selectedPlatform) {
                    ForEach(SNSTargetPlatform.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // 2. Threads 捏合互動提示與控制按鈕
                if selectedPlatform == .threads && displayImages.count > 1 {
                    VStack(spacing: 6) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                isThreadsMerged.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isThreadsMerged ? "arrow.left.and.right" : "arrow.right.and.line.vertical.and.arrow.left")
                                Text(isThreadsMerged ? "點擊展開分隔 (兩圖分開)" : "點擊捏合拼接 (合而為一)")
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isThreadsMerged ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06), in: Capsule())
                            .foregroundStyle(isThreadsMerged ? Color.accentColor : Color.primary)
                            .overlay(Capsule().stroke(isThreadsMerged ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.12), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        Text("💡 支援雙指在圖片上捏合 (Pinch) 或點擊上方按鈕，即刻模擬 Threads 拼圖合體")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer(minLength: 4)
                
                // 3. 模擬社群貼文卡片
                VStack(alignment: .leading, spacing: 10) {
                    // 貼文作者資訊列
                    postHeaderView
                    
                    // 圖片展示區 (依各平台真實機制渲染)
                    switch selectedPlatform {
                    case .instagram:
                        instagramMediaView
                    case .threads:
                        threadsMediaView
                    case .xTwitter:
                        xTwitterMediaView
                    case .redBook:
                        redBookMediaView
                    }
                    
                    // 貼文互動按鈕列
                    postActionBarView
                }
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)
                
                Spacer(minLength: 4)
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
    
    // MARK: - 各平台貼文頭部資訊
    @ViewBuilder
    private var postHeaderView: some View {
        HStack(spacing: 10) {
            switch selectedPlatform {
            case .instagram:
                // IG 彩色限動漸層光環頭像
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(hex: "#F58529"), Color(hex: "#DD2A7B"), Color(hex: "#8134AF")],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        ),
                        lineWidth: 2
                    )
                    .background(Circle().fill(Color.accentColor.opacity(0.85)))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.white)
                            .font(.caption2)
                    }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("pureaspect.frame")
                        .font(.caption.bold())
                    Text("Taipei, Taiwan")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
            case .threads:
                // Threads 風格極簡黑色頭像
                Circle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "at")
                            .foregroundStyle(Color(uiColor: .systemBackground))
                            .font(.caption.bold())
                    }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text("pureaspect")
                            .font(.caption.bold())
                        Text("2h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text("Panorama split on Threads")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
            case .xTwitter:
                // X (Twitter) 頭像
                Circle()
                    .fill(Color.black)
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.white)
                            .font(.caption)
                    }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text("PureAspect")
                            .font(.caption.bold())
                        Text("@pureaspect · 3h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
            case .redBook:
                // 小紅書頭像
                Circle()
                    .fill(Color(hex: "#FF2442"))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.white)
                            .font(.caption)
                    }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("攝影美學筆記")
                        .font(.caption.bold())
                    Text("今日發布")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
    }
    
    // MARK: - Instagram 輪播展示 (單張獨立全寬、左右滑動換頁、右上角 1/N 標籤)
    @ViewBuilder
    private var instagramMediaView: some View {
        if displayImages.count > 1 {
            TabView(selection: $instagramPageIndex) {
                ForEach(0..<displayImages.count, id: \.self) { idx in
                    Image(decorative: displayImages[idx], scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 330)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 330)
            .clipShape(Rectangle()) // Instagram 貼文為 0 圓角
            .overlay(alignment: .topTrailing) {
                Text("\(instagramPageIndex + 1)/\(displayImages.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.65), in: Capsule())
                    .padding(10)
            }
        } else if let img = displayImages.first {
            Image(decorative: img, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 330)
                .clipShape(Rectangle())
        }
    }
    
    // MARK: - Threads 雙圖捏合展示 (支援雙指 Pinch 捏合合體與展開)
    @ViewBuilder
    private var threadsMediaView: some View {
        if displayImages.count > 1 {
            HStack(spacing: Self.threadsGap(isMerged: isThreadsMerged)) {
                ForEach(0..<displayImages.count, id: \.self) { idx in
                    Image(decorative: displayImages[idx], scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: Self.threadsInnerCornerRadius(isMerged: isThreadsMerged),
                                style: .continuous
                            )
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 12)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isThreadsMerged)
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        threadsPinchScale = scale
                        if scale < 0.9 && !isThreadsMerged {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isThreadsMerged = true
                            }
                        } else if scale > 1.15 && isThreadsMerged {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                isThreadsMerged = false
                            }
                        }
                    }
                    .onEnded { _ in
                        threadsPinchScale = 1.0
                    }
            )
        } else if let img = displayImages.first {
            Image(decorative: img, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 290)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 12)
        }
    }
    
    // MARK: - X (Twitter) 左右分欄展示
    @ViewBuilder
    private var xTwitterMediaView: some View {
        if displayImages.count > 1 {
            HStack(spacing: 4) {
                ForEach(0..<min(displayImages.count, 4), id: \.self) { idx in
                    Image(decorative: displayImages[idx], scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 12)
        } else if let img = displayImages.first {
            Image(decorative: img, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 12)
        }
    }
    
    // MARK: - 小紅書 輪播展示
    @ViewBuilder
    private var redBookMediaView: some View {
        if displayImages.count > 1 {
            TabView(selection: $instagramPageIndex) {
                ForEach(0..<displayImages.count, id: \.self) { idx in
                    Image(decorative: displayImages[idx], scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 310)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 310)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 12)
            .overlay(alignment: .topTrailing) {
                Text("\(instagramPageIndex + 1)/\(displayImages.count)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color.black.opacity(0.6), in: Capsule())
                    .padding(.trailing, 20)
                    .padding(.top, 8)
            }
        } else if let img = displayImages.first {
            Image(decorative: img, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 310)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 12)
        }
    }
    
    // MARK: - 各平台互動按鈕列
    @ViewBuilder
    private var postActionBarView: some View {
        switch selectedPlatform {
        case .instagram:
            HStack(spacing: 16) {
                Image(systemName: "heart")
                Image(systemName: "bubble.right")
                Image(systemName: "paperplane")
                
                Spacer()
                
                // IG 輪播圓點指示器 (Active 為藍色，Inactive 為淺灰)
                if displayImages.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<displayImages.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == instagramPageIndex ? Color(hex: "#0095F6") : Color.secondary.opacity(0.35))
                                .frame(width: idx == instagramPageIndex ? 6 : 5, height: idx == instagramPageIndex ? 6 : 5)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "bookmark")
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
        case .threads:
            HStack(spacing: 18) {
                Image(systemName: "heart")
                Image(systemName: "bubble.right")
                Image(systemName: "arrow.2.squarepath")
                Image(systemName: "paperplane")
                Spacer()
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
        case .xTwitter:
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                    Text("12").font(.caption2)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                    Text("48").font(.caption2)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("356").font(.caption2)
                }
                Spacer()
                Image(systemName: "bookmark")
                Spacer()
                Image(systemName: "square.and.arrow.up")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
        case .redBook:
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("點讚").font(.caption2)
                }
                HStack(spacing: 4) {
                    Image(systemName: "star")
                    Text("收藏").font(.caption2)
                }
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("評論").font(.caption2)
                }
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
    }
}
