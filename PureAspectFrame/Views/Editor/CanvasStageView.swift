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
                                .gesture(
                                    SimultaneousGesture(
                                        DragGesture()
                                            .onChanged { val in
                                                offset = CGSize(
                                                    width: accumulatedOffset.width + val.translation.width,
                                                    height: accumulatedOffset.height + val.translation.height
                                                )
                                            }
                                            .onEnded { _ in
                                                accumulatedOffset = offset
                                            },
                                        MagnificationGesture()
                                            .onChanged { val in
                                                scale = max(0.5, min(accumulatedScale * val, 3.5))
                                            }
                                            .onEnded { _ in
                                                accumulatedScale = scale
                                            }
                                    )
                                )
                                .position(x: padLeft + (photoWidth / 2.0), y: padTop + (photoHeight / 2.0))
                            
                            // 底欄內容
                            if footerSettings.isEnabled {
                                HStack {
                                    if footerSettings.activeItems.contains(.logo) {
                                        CameraBrandLogoView(brand: exifMetadata.detectedBrand, height: cH * CGFloat(footerSettings.fontSizeScale) * 0.9)
                                    }
                                    if footerSettings.activeItems.contains(.camera) && !exifMetadata.cameraDisplayString.isEmpty {
                                        Text(exifMetadata.cameraDisplayString)
                                            .font(.system(size: cH * CGFloat(footerSettings.fontSizeScale), weight: .semibold))
                                    }
                                    Spacer()
                                    if footerSettings.activeItems.contains(.parameters) && !exifMetadata.parametersDisplayString.isEmpty {
                                        Text(exifMetadata.parametersDisplayString)
                                            .font(.system(size: cH * CGFloat(footerSettings.fontSizeScale), weight: .medium, design: .monospaced))
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
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDistanceMarkers.toggle()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
        ZStack {
            // 上方標籤
            let isTopSelected = borderSettings.selectedEdges.contains(.top)
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingTop },
                    set: { borderSettings.updatePadding(for: .top, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "上邊距"
            )
            .scaleEffect(isTopSelected ? 1.05 : 0.95)
            .position(x: cW / 2.0, y: max(16, padTop / 2.0))
            
            // 下方標籤
            let isBottomSelected = borderSettings.selectedEdges.contains(.bottom)
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingBottom },
                    set: { borderSettings.updatePadding(for: .bottom, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "下邊距"
            )
            .scaleEffect(isBottomSelected ? 1.05 : 0.95)
            .position(x: cW / 2.0, y: min(cH - 16, cH - (padBottom / 2.0)))
            
            // 左方標籤
            let isLeftSelected = borderSettings.selectedEdges.contains(.left)
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingLeft },
                    set: { borderSettings.updatePadding(for: .left, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "左邊距"
            )
            .scaleEffect(isLeftSelected ? 1.05 : 0.95)
            .position(x: max(24, padLeft / 2.0), y: cH / 2.0)
            
            // 右方標籤
            let isRightSelected = borderSettings.selectedEdges.contains(.right)
            EditableNumberBadge(
                value: Binding(
                    get: { borderSettings.paddingRight },
                    set: { borderSettings.updatePadding(for: .right, value: $0) }
                ),
                unit: borderSettings.unit.rawValue,
                title: "右邊距"
            )
            .scaleEffect(isRightSelected ? 1.05 : 0.95)
            .position(x: min(cW - 24, cW - (padRight / 2.0)), y: cH / 2.0)
        }
    }
}
