import SwiftUI

/// 上方獨立主畫布舞台視圖 (Aspect-Fit 完整全覽、白框標線直調、手勢拖曳縮放)
public struct CanvasStageView: View {
    var image: CGImage
    var canvasRatio: CanvasRatio
    var isLandscape: Bool
    var internalRatio: InternalCropRatio
    var isZeroCrop: Bool
    @Binding var borderSettings: BorderSettings
    var backgroundMode: BackgroundMode
    var footerSettings: FooterSettings
    var splitSettings: SplitSettings
    var exifMetadata: ExifMetadata
    
    // 是否正在檢視四邊距離標線
    @Binding var showDistanceMarkers: Bool
    // 是否收合下方編輯欄位
    @Binding var isBottomPanelCollapsed: Bool
    
    // 手勢平移與縮放
    @State private var offset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var accumulatedScale: CGFloat = 1.0
    // 是否正在調整圖片位置或尺寸（顯示邊界虛線）
    @State private var isAdjustingImage: Bool = false
    
    // MARK: - 視覺樣式規範（細灰黑內部畫框線、半透明淺灰超出範圍線，無陰影模糊）
    public static let innerFrameStrokeStyle = StrokeStyle(lineWidth: 1.0, dash: [4, 3])
    public static func innerFrameColor(isDarkBackground: Bool) -> Color {
        isDarkBackground ? Color(hex: "#AEAEB2").opacity(0.85) : Color(hex: "#2C2C2E").opacity(0.8)
    }
    public static let photoOverflowStrokeStyle = StrokeStyle(lineWidth: 1.0, dash: [5, 4])
    public static let photoOverflowColor = Color(hex: "#8E8E93").opacity(0.65)
    
    // MARK: - 切割指示線樣式常數（不能太粗，剛好 1.0pt 細線；雙層複合結構，在暗調或亮調照片上均清晰可見）
    public static let splitCutLineWidth: CGFloat = 1.0
    public static let splitCutLineBaseWidth: CGFloat = 2.0
    public static let splitCutLineWhiteColor: Color = Color.white.opacity(0.95)
    public static let splitCutLineDarkColor: Color = Color.black.opacity(0.65)
    
    /// 計算無縫切割 (gapPx == 0) 時各切割線在總寬度上的 X 座標
    public static func calculateCutLinePositions(totalWidth: CGFloat, splitSettings: SplitSettings) -> [CGFloat] {
        guard splitSettings.isEnabled, splitSettings.splitCount > 1 else { return [] }
        let count = splitSettings.splitCount
        let sliceWidth = totalWidth / CGFloat(count)
        var positions: [CGFloat] = []
        for i in 1..<count {
            positions.append(CGFloat(i) * sliceWidth)
        }
        return positions
    }
    
    /// 計算切割切片幾何範圍 (支援 gapPx >= 0)
    public static func calculateSplitPreviewSlices(totalWidth: CGFloat, splitSettings: SplitSettings) -> [CGRect] {
        guard splitSettings.isEnabled, splitSettings.splitCount > 1 else {
            return [CGRect(x: 0, y: 0, width: totalWidth, height: 0)]
        }
        let count = CGFloat(splitSettings.splitCount)
        let totalGaps = (count - 1) * splitSettings.gapPx
        let availableWidth = max(0, totalWidth - totalGaps)
        let sliceWidth = availableWidth / count
        
        var slices: [CGRect] = []
        var currentX: CGFloat = 0
        for _ in 0..<splitSettings.splitCount {
            slices.append(CGRect(x: currentX, y: 0, width: sliceWidth, height: 0))
            currentX += sliceWidth + splitSettings.gapPx
        }
        return slices
    }
    
    public init(
        image: CGImage,
        canvasRatio: CanvasRatio,
        isLandscape: Bool = false,
        internalRatio: InternalCropRatio = .square1x1,
        isZeroCrop: Bool,
        borderSettings: Binding<BorderSettings>,
        backgroundMode: BackgroundMode,
        footerSettings: FooterSettings,
        splitSettings: SplitSettings = SplitSettings(),
        exifMetadata: ExifMetadata,
        showDistanceMarkers: Binding<Bool>,
        isBottomPanelCollapsed: Binding<Bool>,
        initialOffset: CGSize = .zero,
        initialScale: CGFloat = 1.0,
        initialIsAdjustingImage: Bool = false
    ) {
        self.image = image
        self.canvasRatio = canvasRatio
        self.isLandscape = isLandscape
        self.internalRatio = internalRatio
        self.isZeroCrop = isZeroCrop
        self._borderSettings = borderSettings
        self.backgroundMode = backgroundMode
        self.footerSettings = footerSettings
        self.splitSettings = splitSettings
        self.exifMetadata = exifMetadata
        self._showDistanceMarkers = showDistanceMarkers
        self._isBottomPanelCollapsed = isBottomPanelCollapsed
        self._offset = State(initialValue: initialOffset)
        self._accumulatedOffset = State(initialValue: initialOffset)
        self._scale = State(initialValue: initialScale)
        self._accumulatedScale = State(initialValue: initialScale)
        self._isAdjustingImage = State(initialValue: initialIsAdjustingImage)
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - 24
            let availableHeight = proxy.size.height - 24
            let photoAspect = CGFloat(image.width) / max(1, CGFloat(image.height))
            let canvasAspect = canvasRatio.aspectRatio(isLandscape: isLandscape, photoAspectRatio: photoAspect)
            
            // 計算在可用空間內 Aspect-Fit 的畫布物理尺寸
            let fitSize: CGSize = {
                if availableWidth / availableHeight > canvasAspect {
                    let h = availableHeight
                    let w = h * canvasAspect
                    return CGSize(width: w, height: h)
                } else {
                    let w = availableWidth
                    let h = w / canvasAspect
                    return CGSize(width: w, height: h)
                }
            }()
            
            ZStack {
                // 背景點選：點選圖外空白處可收合/展開下方編輯欄位
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isBottomPanelCollapsed.toggle()
                            showDistanceMarkers = false
                        }
                    }
                
                // 實體畫布容器
                ZStack {
                    // 1. 畫布背景 (黑 / 白 / 自訂 / 毛玻璃)
                    canvasBackgroundView
                    
                    // 2. 內部相片框與照片
                    GeometryReader { canvasProxy in
                        let cW = canvasProxy.size.width
                        let cH = canvasProxy.size.height
                        
                        let padTop = borderSettings.unit == .percent ? (cH * borderSettings.paddingTop / 100.0) : borderSettings.paddingTop
                        let padBottom = borderSettings.unit == .percent ? (cH * borderSettings.paddingBottom / 100.0) : borderSettings.paddingBottom
                        let padLeft = borderSettings.unit == .percent ? (cW * borderSettings.paddingLeft / 100.0) : borderSettings.paddingLeft
                        let padRight = borderSettings.unit == .percent ? (cW * borderSettings.paddingRight / 100.0) : borderSettings.paddingRight
                        
                        let footerHeight: CGFloat = footerSettings.resolvedFooterHeight(canvasWidth: cW, canvasHeight: cH)
                        
                        let photoWidth = max(20, cW - padLeft - padRight)
                        let photoHeight = max(20, cH - padTop - padBottom - footerHeight)
                        let cornerRadius = borderSettings.cornerRadiusUnit == .percent ? (min(photoWidth, photoHeight) * borderSettings.cornerRadius / 100.0) : borderSettings.cornerRadius
                        
                        ZStack(alignment: .topLeading) {
                            // 1. 照片手勢調整時：背景顯示實際照片（超出的部分呈現半透明淺灰色外觀，高級感）
                            if isAdjustingImage {
                                ZStack {
                                    Image(decorative: image, scale: 1.0)
                                        .resizable()
                                        .aspectRatio(contentMode: isZeroCrop ? .fit : .fill)
                                        .frame(width: photoWidth, height: photoHeight)
                                        .opacity(0.35)
                                    
                                    // 實際照片尺寸邊界：半透明淺灰色虛線（無陰影）
                                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                        .strokeBorder(
                                            Self.photoOverflowColor,
                                            style: Self.photoOverflowStrokeStyle
                                        )
                                        .frame(width: photoWidth, height: photoHeight)
                                }
                                .scaleEffect(scale)
                                .offset(offset)
                                .position(x: padLeft + (photoWidth / 2.0), y: padTop + (photoHeight / 2.0))
                                .allowsHitTesting(false)
                                .transition(.opacity)
                            }
                            
                            // 2. 照片主體（被內部畫框裁切之主要視野）
                            Image(decorative: image, scale: 1.0)
                                .resizable()
                                .aspectRatio(contentMode: isZeroCrop ? .fit : .fill)
                                .frame(width: photoWidth, height: photoHeight)
                                .scaleEffect(scale)
                                .offset(offset)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                                .animation(.easeInOut(duration: 0.2), value: isAdjustingImage)
                                .gesture(
                                    SimultaneousGesture(
                                        DragGesture()
                                            .onChanged { val in
                                                isAdjustingImage = true
                                                offset = CGSize(
                                                    width: accumulatedOffset.width + val.translation.width,
                                                    height: accumulatedOffset.height + val.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                accumulatedOffset = offset
                                                withAnimation(.easeOut(duration: 0.25)) {
                                                    isAdjustingImage = false
                                                }
                                            },
                                        MagnificationGesture()
                                            .onChanged { val in
                                                isAdjustingImage = true
                                                scale = max(0.5, min(accumulatedScale * val, 3.5))
                                            }
                                            .onEnded { _ in
                                                accumulatedScale = scale
                                                withAnimation(.easeOut(duration: 0.25)) {
                                                    isAdjustingImage = false
                                                }
                                            }
                                    )
                                )
                                .onTapGesture(count: 2) {
                                    resetImageTransform()
                                }
                                .position(x: padLeft + (photoWidth / 2.0), y: padTop + (photoHeight / 2.0))
                            
                            // 3. 內部畫框範圍指示線（細灰黑虛線，無陰影模糊）
                            if isAdjustingImage {
                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                    .strokeBorder(
                                        Self.innerFrameColor(isDarkBackground: backgroundMode.isDarkOrNearDarkGray),
                                        style: Self.innerFrameStrokeStyle
                                    )
                                    .frame(width: photoWidth, height: photoHeight)
                                    .position(x: padLeft + (photoWidth / 2.0), y: padTop + (photoHeight / 2.0))
                                    .allowsHitTesting(false)
                                    .transition(.opacity)
                            }
                            
                            // 底欄內容
                            if footerSettings.isEnabled && footerHeight > 0 {
                                let sections = footerSettings.layoutSections
                                let fontScaledSize = footerSettings.resolvedFontPointSize(canvasWidth: cW, canvasHeight: cH)
                                
                                HStack(spacing: 8) {
                                    if sections.count <= 1 {
                                        // 0 Spacers: 置中
                                        Spacer()
                                        footerSectionView(items: sections.first ?? [], fontSize: fontScaledSize)
                                        Spacer()
                                    } else if sections.count == 2 {
                                        // 1 Spacer: 左右對齊
                                        footerSectionView(items: sections[0], fontSize: fontScaledSize)
                                        Spacer()
                                        footerSectionView(items: sections[1], fontSize: fontScaledSize)
                                    } else {
                                        // 2 Spacers 或以上: 3 段式 (左、中、右)
                                        footerSectionView(items: sections[0], fontSize: fontScaledSize)
                                        Spacer()
                                        footerSectionView(items: sections[1], fontSize: fontScaledSize)
                                        Spacer()
                                        footerSectionView(items: sections[2], fontSize: fontScaledSize)
                                    }
                                }
                                .foregroundStyle(Color(hex: footerSettings.textColorHex))
                                .lineLimit(1)
                                .minimumScaleFactor(0.35)
                                .padding(.horizontal, 4)
                                .frame(width: photoWidth, height: footerHeight)
                                .position(x: padLeft + (photoWidth / 2.0), y: cH - padBottom - (footerHeight / 2.0))
                            }
                            
                            // 3. 點選白框邊框區域直接顯示標線與數值直調
                            if showDistanceMarkers {
                                distanceMarkersOverlay(
                                    cW: cW,
                                    cH: cH,
                                    padTop: padTop,
                                    padBottom: padBottom,
                                    padLeft: padLeft,
                                    padRight: padRight,
                                    photoWidth: photoWidth,
                                    photoHeight: photoHeight
                                )
                            }
                        }
                    }
                }
                .frame(width: fitSize.width, height: fitSize.height)
                .overlay {
                    if splitSettings.isEnabled && splitSettings.splitCount > 1 {
                        splitPreviewOverlay(cW: fitSize.width, cH: fitSize.height)
                            .allowsHitTesting(false)
                    }
                }
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                .onTapGesture(count: 2) {
                    resetImageTransform()
                }
                .onTapGesture(count: 1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDistanceMarkers.toggle()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - 切割即時預覽遮罩與切割線 (支援無縫 0px 高對比細線與間隙物理分隔)
    @ViewBuilder
    private func splitPreviewOverlay(cW: CGFloat, cH: CGFloat) -> some View {
        let count = splitSettings.splitCount
        if splitSettings.gapPx <= 0 {
            // 無間隙無縫切割 (IG 輪播模式)
            let cutPositions = Self.calculateCutLinePositions(totalWidth: cW, splitSettings: splitSettings)
            let sliceW = cW / CGFloat(count)
            
            ZStack {
                // 1. 各切片序號膠囊標籤 (懸浮於切片頂部)
                ForEach(0..<count, id: \.self) { index in
                    let centerX = (CGFloat(index) + 0.5) * sliceW
                    sliceBadge(index: index, total: count)
                        .position(x: centerX, y: 18)
                }
                
                // 2. 切割指示線 (不能太粗，剛好 1.0pt 細線；雙層複合結構，暗調亮調均清晰呈現)
                ForEach(cutPositions, id: \.self) { xPos in
                    ZStack {
                        // 暗調底基 (2.0pt，確保在純白或亮色照片上維持暗邊輪廓)
                        Rectangle()
                            .fill(Self.splitCutLineDarkColor)
                            .frame(width: Self.splitCutLineBaseWidth, height: cH)
                        
                        // 亮白主線 (1.0pt，確保在純黑或暗色照片上維持高亮鋒利)
                        Rectangle()
                            .fill(Self.splitCutLineWhiteColor)
                            .frame(width: Self.splitCutLineWidth, height: cH)
                    }
                    .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0)
                    .position(x: xPos, y: cH / 2.0)
                }
            }
        } else {
            // 有間隙切割 (Threads / X 等模式)
            let slices = Self.calculateSplitPreviewSlices(totalWidth: cW, splitSettings: splitSettings)
            
            ZStack {
                // 1. 各切片序號膠囊標籤
                ForEach(0..<slices.count, id: \.self) { index in
                    let centerX = slices[index].midX
                    sliceBadge(index: index, total: count)
                        .position(x: centerX, y: 18)
                }
                
                // 2. 間隙挖空遮罩 (顯示舞台背景色，呈現物理切割切開感) 與邊界切割線
                ForEach(0..<(slices.count - 1), id: \.self) { i in
                    let gapLeft = slices[i].maxX
                    let gapRight = slices[i + 1].minX
                    let gapWidth = max(0, gapRight - gapLeft)
                    let gapCenterX = gapLeft + (gapWidth / 2.0)
                    
                    // 間隙挖空區域 (填入舞台背景色)
                    Rectangle()
                        .fill(backgroundMode.stageBackgroundColor)
                        .frame(width: gapWidth, height: cH)
                        .position(x: gapCenterX, y: cH / 2.0)
                    
                    // 左側切片裁切線
                    ZStack {
                        Rectangle()
                            .fill(Self.splitCutLineDarkColor)
                            .frame(width: Self.splitCutLineBaseWidth, height: cH)
                        Rectangle()
                            .fill(Self.splitCutLineWhiteColor)
                            .frame(width: Self.splitCutLineWidth, height: cH)
                    }
                    .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0)
                    .position(x: gapLeft, y: cH / 2.0)
                    
                    // 右側切片裁切線
                    ZStack {
                        Rectangle()
                            .fill(Self.splitCutLineDarkColor)
                            .frame(width: Self.splitCutLineBaseWidth, height: cH)
                        Rectangle()
                            .fill(Self.splitCutLineWhiteColor)
                            .frame(width: Self.splitCutLineWidth, height: cH)
                    }
                    .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0)
                    .position(x: gapRight, y: cH / 2.0)
                }
            }
        }
    }
    
    private func sliceBadge(index: Int, total: Int) -> some View {
        HStack(spacing: 2) {
            Text("\(index + 1)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Text("/")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .opacity(0.6)
            Text("\(total)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.35), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }
    
    // MARK: - 重設圖片位置與縮放為預設值
    private func resetImageTransform() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            offset = .zero
            accumulatedOffset = .zero
            scale = 1.0
            accumulatedScale = 1.0
        }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }
    
    // MARK: - 畫布背景視圖
    @ViewBuilder
    private var canvasBackgroundView: some View {
        switch backgroundMode {
        case .white:
            Color.white
        case .black:
            Color.black
        case let .customHSB(h, s, b):
            Color(hue: h, saturation: s, brightness: b)
        case let .frostedGlass(blurRadius):
            Image(decorative: image, scale: 1.0)
                .resizable()
                .scaledToFill()
                .blur(radius: blurRadius * 0.4)
                .clipped()
        }
    }
    
    // MARK: - 底欄 Section 渲染輔助
    @ViewBuilder
    private func footerSectionView(items: [FooterItemType], fontSize: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                switch item {
                case .logo:
                    CameraBrandLogoView(brand: exifMetadata.detectedBrand, height: fontSize * 0.9)
                case .camera:
                    if !exifMetadata.cameraDisplayString.isEmpty {
                        Text(exifMetadata.cameraDisplayString)
                            .font(.system(size: fontSize, weight: .semibold))
                            .lineLimit(1)
                    }
                case .lens:
                    if !exifMetadata.lensDisplayString.isEmpty {
                        Text(exifMetadata.lensDisplayString)
                            .font(.system(size: fontSize, weight: .regular))
                            .lineLimit(1)
                    }
                case .parameters:
                    if !exifMetadata.parametersDisplayString.isEmpty {
                        Text(exifMetadata.parametersDisplayString)
                            .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                            .lineLimit(1)
                    }
                case .date:
                    if let date = exifMetadata.dateTimeOriginal {
                        Text(formatDate(date))
                            .font(.system(size: fontSize, weight: .regular, design: .monospaced))
                            .lineLimit(1)
                    }
                case .customText:
                    if !footerSettings.customText.isEmpty {
                        Text(footerSettings.customText)
                            .font(.system(size: fontSize, weight: .medium))
                            .lineLimit(1)
                    }
                case .spacer:
                    EmptyView()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy.MM.dd"
        return df.string(from: date)
    }
    
    // MARK: - 白框四邊距離標線與可編輯數字標籤
    @ViewBuilder
    private func distanceMarkersOverlay(
        cW: CGFloat,
        cH: CGFloat,
        padTop: CGFloat,
        padBottom: CGFloat,
        padLeft: CGFloat,
        padRight: CGFloat,
        photoWidth: CGFloat,
        photoHeight: CGFloat
    ) -> some View {
        let footerHeight: CGFloat = footerSettings.resolvedFooterHeight(canvasWidth: cW, canvasHeight: cH)
        ZStack {
            let maxRange: CGFloat = borderSettings.unit == .percent ? 40 : 300
            
            // 上方尺標標線與標籤
            let isTopSelected = borderSettings.selectedEdges.contains(.top)
            if padTop > 8 {
                Path { p in
                    p.move(to: CGPoint(x: cW / 2 - 12, y: 1))
                    p.addLine(to: CGPoint(x: cW / 2 + 12, y: 1))
                    p.move(to: CGPoint(x: cW / 2, y: 1))
                    p.addLine(to: CGPoint(x: cW / 2, y: padTop - 1))
                    p.move(to: CGPoint(x: cW / 2 - 12, y: padTop - 1))
                    p.addLine(to: CGPoint(x: cW / 2 + 12, y: padTop - 1))
                }
                .stroke(isTopSelected ? Color.accentColor : Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingTop },
                    set: { borderSettings.updatePadding(for: .top, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "上",
                range: 0...maxRange,
                requireDoubleTapToEdit: true,
                enableScrubber: true,
                onSelect: {
                    borderSettings.selectEdgeForAdjustment(.top)
                }
            )
            .scaleEffect(isTopSelected ? 1.05 : 0.95)
            .position(x: cW / 2.0, y: max(18, padTop / 2.0))
            
            // 下方尺標標線與標籤
            let isBottomSelected = borderSettings.selectedEdges.contains(.bottom)
            if padBottom > 8 {
                let bottomStart = cH - padBottom - footerHeight
                Path { p in
                    p.move(to: CGPoint(x: cW / 2 - 12, y: bottomStart + 1))
                    p.addLine(to: CGPoint(x: cW / 2 + 12, y: bottomStart + 1))
                    p.move(to: CGPoint(x: cW / 2, y: bottomStart + 1))
                    p.addLine(to: CGPoint(x: cW / 2, y: cH - 1))
                    p.move(to: CGPoint(x: cW / 2 - 12, y: cH - 1))
                    p.addLine(to: CGPoint(x: cW / 2 + 12, y: cH - 1))
                }
                .stroke(isBottomSelected ? Color.accentColor : Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingBottom },
                    set: { borderSettings.updatePadding(for: .bottom, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "下",
                range: 0...maxRange,
                requireDoubleTapToEdit: true,
                enableScrubber: true,
                onSelect: {
                    borderSettings.selectEdgeForAdjustment(.bottom)
                }
            )
            .scaleEffect(isBottomSelected ? 1.05 : 0.95)
            .position(x: cW / 2.0, y: min(cH - 18, cH - (padBottom / 2.0)))
            
            // 左方尺標標線與標籤
            let isLeftSelected = borderSettings.selectedEdges.contains(.left)
            if padLeft > 8 {
                Path { p in
                    p.move(to: CGPoint(x: 1, y: cH / 2 - 12))
                    p.addLine(to: CGPoint(x: 1, y: cH / 2 + 12))
                    p.move(to: CGPoint(x: 1, y: cH / 2))
                    p.addLine(to: CGPoint(x: padLeft - 1, y: cH / 2))
                    p.move(to: CGPoint(x: padLeft - 1, y: cH / 2 - 12))
                    p.addLine(to: CGPoint(x: padLeft - 1, y: cH / 2 + 12))
                }
                .stroke(isLeftSelected ? Color.accentColor : Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingLeft },
                    set: { borderSettings.updatePadding(for: .left, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "左",
                range: 0...maxRange,
                requireDoubleTapToEdit: true,
                enableScrubber: true,
                onSelect: {
                    borderSettings.selectEdgeForAdjustment(.left)
                }
            )
            .scaleEffect(isLeftSelected ? 1.05 : 0.95)
            .position(x: max(26, padLeft / 2.0), y: cH / 2.0)
            
            // 右方尺標標線與標籤
            let isRightSelected = borderSettings.selectedEdges.contains(.right)
            if padRight > 8 {
                Path { p in
                    p.move(to: CGPoint(x: cW - padRight + 1, y: cH / 2 - 12))
                    p.addLine(to: CGPoint(x: cW - padRight + 1, y: cH / 2 + 12))
                    p.move(to: CGPoint(x: cW - padRight + 1, y: cH / 2))
                    p.addLine(to: CGPoint(x: cW - 1, y: cH / 2))
                    p.move(to: CGPoint(x: cW - 1, y: cH / 2 - 12))
                    p.addLine(to: CGPoint(x: cW - 1, y: cH / 2 + 12))
                }
                .stroke(isRightSelected ? Color.accentColor : Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingRight },
                    set: { borderSettings.updatePadding(for: .right, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "右",
                range: 0...maxRange,
                requireDoubleTapToEdit: true,
                enableScrubber: true,
                onSelect: {
                    borderSettings.selectEdgeForAdjustment(.right)
                }
            )
            .scaleEffect(isRightSelected ? 1.05 : 0.95)
            .position(x: min(cW - 26, cW - (padRight / 2.0)), y: cH / 2.0)
        }
    }
}
