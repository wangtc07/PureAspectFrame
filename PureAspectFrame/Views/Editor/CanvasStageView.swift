import SwiftUI

/// 上方獨立主畫布舞台視圖 (Aspect-Fit 完整全覽、白框標線直調、手勢拖曳縮放)
public struct CanvasStageView: View {
    var image: CGImage
    var canvasRatio: CanvasRatio
    var internalRatio: InternalCropRatio
    var isZeroCrop: Bool
    @Binding var borderSettings: BorderSettings
    var backgroundMode: BackgroundMode
    var footerSettings: FooterSettings
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
    
    public init(
        image: CGImage,
        canvasRatio: CanvasRatio,
        internalRatio: InternalCropRatio,
        isZeroCrop: Bool,
        borderSettings: Binding<BorderSettings>,
        backgroundMode: BackgroundMode,
        footerSettings: FooterSettings,
        exifMetadata: ExifMetadata,
        showDistanceMarkers: Binding<Bool>,
        isBottomPanelCollapsed: Binding<Bool>
    ) {
        self.image = image
        self.canvasRatio = canvasRatio
        self.internalRatio = internalRatio
        self.isZeroCrop = isZeroCrop
        self._borderSettings = borderSettings
        self.backgroundMode = backgroundMode
        self.footerSettings = footerSettings
        self.exifMetadata = exifMetadata
        self._showDistanceMarkers = showDistanceMarkers
        self._isBottomPanelCollapsed = isBottomPanelCollapsed
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width - 24
            let availableHeight = proxy.size.height - 24
            let canvasAspect = canvasRatio.aspectRatio
            
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
                        
                        let footerHeight: CGFloat = footerSettings.isEnabled ? (cH * CGFloat(footerSettings.fontSizeScale) * 2.8) : 0
                        
                        let photoWidth = max(20, cW - padLeft - padRight)
                        let photoHeight = max(20, cH - padTop - padBottom - footerHeight)
                        let cornerRadius = borderSettings.cornerRadiusUnit == .percent ? (min(photoWidth, photoHeight) * borderSettings.cornerRadius / 100.0) : borderSettings.cornerRadius
                        
                        ZStack(alignment: .topLeading) {
                            // 照片主體
                            Image(decorative: image, scale: 1.0)
                                .resizable()
                                .aspectRatio(contentMode: isZeroCrop ? .fit : .fill)
                                .frame(width: photoWidth, height: photoHeight)
                                .scaleEffect(scale)
                                .offset(offset)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                                .overlay {
                                    if isAdjustingImage {
                                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                            .strokeBorder(Color.white, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                                            .overlay {
                                                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1.2, dash: [6, 4], dashPhase: 3))
                                            }
                                            .shadow(color: Color.black.opacity(0.4), radius: 2)
                                            .scaleEffect(scale)
                                            .offset(offset)
                                            .transition(.opacity)
                                    }
                                }
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
                            
                            // 底欄內容
                            if footerSettings.isEnabled {
                                let sections = footerSettings.layoutSections
                                let fontScaledSize = cH * CGFloat(footerSettings.fontSizeScale)
                                
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
        let footerHeight: CGFloat = footerSettings.isEnabled ? (cH * CGFloat(footerSettings.fontSizeScale) * 2.8) : 0
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
