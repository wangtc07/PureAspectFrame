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

/// 支援個別圓角設定的矩形 Shape（用於 Threads 捏合合體時內側 0 圓角、外側 12pt 圓角）
private struct UnevenCornersRectangle: Shape {
    var topLeading: CGFloat
    var bottomLeading: CGFloat
    var bottomTrailing: CGFloat
    var topTrailing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.size.width
        let h = rect.size.height
        
        let tr = min(min(topTrailing, h / 2), w / 2)
        let tl = min(min(topLeading, h / 2), w / 2)
        let bl = min(min(bottomLeading, h / 2), w / 2)
        let br = min(min(bottomTrailing, h / 2), w / 2)
        
        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

/// SNS 發佈模擬預覽視圖（純粹呈現貼文圖片區域，100% 還原各平台真實版型、動態比例、邊距、間隙與圓角）
public struct SNSPreviewView: View {
    var renderedImage: CGImage?
    var slices: [CGImage]
    
    @State private var selectedPlatform: SNSTargetPlatform
    @State private var instagramPageIndex: Int = 0
    @State private var isThreadsMerged: Bool
    @State private var threadsPinchScale: CGFloat = 1.0
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 各平台真實貼文圖片區域幾何與比例計算常數
    
    /// Threads 雙圖分開與捏合合體之間隙
    public static func threadsGap(isMerged: Bool) -> CGFloat {
        isMerged ? 0.0 : 6.0
    }
    
    /// Threads 雙圖分開與捏合合體之相鄰內側圓角
    public static func threadsInnerCornerRadius(isMerged: Bool) -> CGFloat {
        isMerged ? 0.0 : 12.0
    }
    
    /// X (Twitter) 水平滾動多圖間隙 (4pt)
    public static let xTwitterCarouselGap: CGFloat = 4.0
    
    /// X (Twitter) 貼文圖片圓角 (12pt)
    public static let xTwitterMediaCornerRadius: CGFloat = 12.0
    
    /// Instagram 滿版寬度下，依據第一張圖片真實比例動態計算容器高度（支援 1.91:1 橫圖至 3:4 直圖）
    public static func instagramMediaHeight(containerWidth: CGFloat, imageAspectRatio: CGFloat) -> CGFloat {
        guard containerWidth > 0, imageAspectRatio > 0 else { return containerWidth }
        let clampedAspect = min(max(imageAspectRatio, 0.75), 1.91)
        return containerWidth / clampedAspect
    }
    
    /// Threads 水平滾動多圖下，固定輪播高度，依據每張切片真實比例計算卡片尺寸
    public static func threadsCarouselItemSize(carouselHeight: CGFloat, imageAspectRatio: CGFloat) -> CGSize {
        guard carouselHeight > 0, imageAspectRatio > 0 else {
            return CGSize(width: carouselHeight, height: carouselHeight)
        }
        let clampedAspect = min(max(imageAspectRatio, 0.5), 1.91)
        return CGSize(width: carouselHeight * clampedAspect, height: carouselHeight)
    }
    
    /// X (Twitter) 水平滾動多圖下，固定輪播高度，依據每張切片真實比例計算卡片尺寸
    public static func xTwitterCarouselItemSize(carouselHeight: CGFloat, imageAspectRatio: CGFloat) -> CGSize {
        guard carouselHeight > 0, imageAspectRatio > 0 else {
            return CGSize(width: carouselHeight, height: carouselHeight)
        }
        let clampedAspect = min(max(imageAspectRatio, 0.5), 2.0)
        return CGSize(width: carouselHeight * clampedAspect, height: carouselHeight)
    }
    
    /// 計算單張 CGImage 的寬高比 (width / height)
    private func aspectRatio(of image: CGImage) -> CGFloat {
        guard image.height > 0 else { return 1.0 }
        return CGFloat(image.width) / CGFloat(image.height)
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
            GeometryReader { geo in
                let screenWidth = geo.size.width
                VStack(spacing: 16) {
                    // 1. 平台切換分段選擇器
                    Picker("發佈平台", selection: $selectedPlatform) {
                        ForEach(SNSTargetPlatform.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // 2. Threads 捏合互動提示與控制按鈕
                    if selectedPlatform == .threads && displayImages.count > 1 {
                        VStack(spacing: 6) {
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
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
                            
                            Text("支援雙指在圖片上捏合 (Pinch) 或點擊上方按鈕，模擬 Threads 拼圖合體")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 0)
                    
                    // 3. 純貼文圖片區域 (不顯示帳號或貼文文字，100% 依各平台實際圖片比例、邊距與圓角渲染)
                    Group {
                        switch selectedPlatform {
                        case .instagram:
                            instagramMediaView(screenWidth: screenWidth)
                        case .threads:
                            threadsMediaView(screenWidth: screenWidth)
                        case .xTwitter:
                            xTwitterMediaView(screenWidth: screenWidth)
                        case .redBook:
                            redBookMediaView(screenWidth: screenWidth)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("SNS 發佈預覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - 1. Instagram 貼文圖片區 (100% 滿版寬度、0 圓角、依實際圖片比例動態決定高度、下方獨立置中圓點指示器)
    @ViewBuilder
    private func instagramMediaView(screenWidth: CGFloat) -> some View {
        let firstAspect = displayImages.first.map { aspectRatio(of: $0) } ?? 1.0
        let mediaHeight = Self.instagramMediaHeight(containerWidth: screenWidth, imageAspectRatio: firstAspect)
        
        VStack(spacing: 12) {
            if displayImages.count > 1 {
                TabView(selection: $instagramPageIndex) {
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        Image(decorative: displayImages[idx], scale: 1.0)
                            .resizable()
                            .scaledToFill()
                            .frame(width: screenWidth, height: mediaHeight)
                            .clipped()
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: screenWidth, height: mediaHeight)
                .clipShape(Rectangle()) // Instagram 貼文為 0 圓角、滿版無邊距
                
                // 圖片正下方獨立置中輪播圓點指示器
                HStack(spacing: 5) {
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        let isActive = idx == instagramPageIndex
                        let isEdge = (idx == displayImages.count - 1 || idx == 0) && displayImages.count >= 5 && !isActive
                        Circle()
                            .fill(isActive ? Color(red: 74/255, green: 93/255, blue: 249/255) : Color.secondary.opacity(0.38))
                            .frame(
                                width: isActive ? 6.0 : (isEdge ? 4.0 : 5.0),
                                height: isActive ? 6.0 : (isEdge ? 4.0 : 5.0)
                            )
                    }
                }
            } else if let img = displayImages.first {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: mediaHeight)
                    .clipShape(Rectangle())
            }
        }
    }
    
    // MARK: - 2. Threads 貼文圖片區 (多圖左留白 12pt 右出血水平滾動、依真實切片比例計算寬度、12pt 圓角、雙指捏合無縫合體)
    @ViewBuilder
    private func threadsMediaView(screenWidth: CGFloat) -> some View {
        // 實機比例：carouselHeight = 397 / 472 * screenWidth (約 0.841 * screenWidth)
        let baseCarouselHeight = round(screenWidth * (397.0 / 472.0))
        
        if displayImages.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.threadsGap(isMerged: isThreadsMerged)) {
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        let img = displayImages[idx]
                        let ratio = aspectRatio(of: img)
                        let itemSize = Self.threadsCarouselItemSize(
                            carouselHeight: baseCarouselHeight,
                            imageAspectRatio: ratio
                        )
                        let isFirst = idx == 0
                        let isLast = idx == displayImages.count - 1
                        let innerR = Self.threadsInnerCornerRadius(isMerged: isThreadsMerged)
                        let shape = UnevenCornersRectangle(
                            topLeading: isFirst ? 12 : innerR,
                            bottomLeading: isFirst ? 12 : innerR,
                            bottomTrailing: isLast ? 12 : innerR,
                            topTrailing: isLast ? 12 : innerR
                        )
                        
                        Image(decorative: img, scale: 1.0)
                            .resizable()
                            .scaledToFill()
                            .frame(width: itemSize.width, height: itemSize.height)
                            .clipShape(shape)
                            .overlay(
                                shape.stroke(
                                    Color.primary.opacity(isThreadsMerged ? 0.0 : 0.12),
                                    lineWidth: 0.5
                                )
                            )
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 12)
                .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isThreadsMerged)
            }
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        threadsPinchScale = scale
                        if scale < 0.92 && !isThreadsMerged {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                isThreadsMerged = true
                            }
                        } else if scale > 1.12 && isThreadsMerged {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                isThreadsMerged = false
                            }
                        }
                    }
                    .onEnded { _ in
                        threadsPinchScale = 1.0
                    }
            )
        } else if let img = displayImages.first {
            let availableW = screenWidth - 24
            let ratio = min(max(aspectRatio(of: img), 0.75), 1.91)
            let singleH = availableW / ratio
            Image(decorative: img, scale: 1.0)
                .resizable()
                .scaledToFill()
                .frame(width: availableW, height: singleH)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                )
                .padding(.horizontal, 12)
        }
    }
    
    // MARK: - 3. X (Twitter) 貼文圖片區 (多圖左留白 10pt 右出血水平滾動、4pt 間隙、12pt 圓角、依真實切片比例計算寬度)
    @ViewBuilder
    private func xTwitterMediaView(screenWidth: CGFloat) -> some View {
        // 實機比例：carouselHeight = 399 / 472 * screenWidth (約 0.845 * screenWidth)
        let baseCarouselHeight = round(screenWidth * (399.0 / 472.0))
        
        if displayImages.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Self.xTwitterCarouselGap) {
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        let img = displayImages[idx]
                        let ratio = aspectRatio(of: img)
                        let itemSize = Self.xTwitterCarouselItemSize(
                            carouselHeight: baseCarouselHeight,
                            imageAspectRatio: ratio
                        )
                        Image(decorative: img, scale: 1.0)
                            .resizable()
                            .scaledToFill()
                            .frame(width: itemSize.width, height: itemSize.height)
                            .clipShape(RoundedRectangle(cornerRadius: Self.xTwitterMediaCornerRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Self.xTwitterMediaCornerRadius, style: .continuous)
                                    .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                            )
                    }
                }
                .padding(.leading, 10)
                .padding(.trailing, 10)
            }
        } else if let img = displayImages.first {
            let availableW = screenWidth - 20
            let ratio = min(max(aspectRatio(of: img), 0.75), 2.0)
            let singleH = availableW / ratio
            Image(decorative: img, scale: 1.0)
                .resizable()
                .scaledToFill()
                .frame(width: availableW, height: singleH)
                .clipShape(RoundedRectangle(cornerRadius: Self.xTwitterMediaCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Self.xTwitterMediaCornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                )
                .padding(.horizontal, 10)
        }
    }
    
    // MARK: - 4. 小紅書 貼文圖片區 (依實際比例動態高度、輪播翻頁、8pt 圓角與圓點指示器)
    @ViewBuilder
    private func redBookMediaView(screenWidth: CGFloat) -> some View {
        let availableW = screenWidth - 24
        let firstAspect = displayImages.first.map { aspectRatio(of: $0) } ?? 0.75
        let clampedAspect = min(max(firstAspect, 0.75), 1.33)
        let mediaHeight = availableW / clampedAspect
        
        VStack(spacing: 12) {
            if displayImages.count > 1 {
                TabView(selection: $instagramPageIndex) {
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        Image(decorative: displayImages[idx], scale: 1.0)
                            .resizable()
                            .scaledToFill()
                            .frame(width: availableW, height: mediaHeight)
                            .clipped()
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: availableW, height: mediaHeight)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.horizontal, 12)
                .overlay(alignment: .topTrailing) {
                    Text("\(instagramPageIndex + 1)/\(displayImages.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6), in: Capsule())
                        .padding(.trailing, 22)
                        .padding(.top, 10)
                }
                
                HStack(spacing: 5) {
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == instagramPageIndex ? Color(hex: "#FF2442") : Color.secondary.opacity(0.35))
                            .frame(width: 5.5, height: 5.5)
                    }
                }
            } else if let img = displayImages.first {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .frame(width: availableW, height: mediaHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, 12)
            }
        }
    }
}
