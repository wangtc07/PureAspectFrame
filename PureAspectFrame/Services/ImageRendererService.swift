import Foundation
import CoreGraphics
import CoreImage
#if canImport(UIKit)
import UIKit
#endif

/// 畫布與相片渲染輸出引擎
public final class ImageRendererService: Sendable {
    
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    /// 渲染單張完整畫布 (CGImage)
    public static func render(
        image: CGImage,
        canvasRatio: CanvasRatio,
        internalRatio: InternalCropRatio = .free,
        isZeroCrop: Bool = false,
        borderSettings: BorderSettings,
        backgroundMode: BackgroundMode,
        footerSettings: FooterSettings,
        exif: ExifMetadata,
        baseWidth: CGFloat = 1080,
        imageOffset: CGPoint = .zero,
        imageScale: CGFloat = 1.0
    ) -> CGImage? {
        let canvasSize = canvasRatio.targetPixelSize(baseWidth: baseWidth)
        let canvasWidth = Int(canvasSize.width)
        let canvasHeight = Int(canvasSize.height)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        guard let context = CGContext(
            data: nil,
            width: canvasWidth,
            height: canvasHeight,
            bitsPerComponent: 8,
            bytesPerRow: 4 * canvasWidth,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        let canvasRect = CGRect(x: 0, y: 0, width: CGFloat(canvasWidth), height: CGFloat(canvasHeight))
        
        // 1. 繪製背景
        drawBackground(
            context: context,
            canvasRect: canvasRect,
            mode: backgroundMode,
            sourceImage: image
        )
        
        // 2. 計算底欄高度與保留空間
        let footerHeight: CGFloat = footerSettings.isEnabled ? (canvasRect.height * CGFloat(footerSettings.fontSizeScale) * 2.8) : 0
        
        // 3. 計算照片框四邊留白邊距
        let padTop: CGFloat
        let padBottom: CGFloat
        let padLeft: CGFloat
        let padRight: CGFloat
        
        if borderSettings.unit == .percent {
            padTop = canvasRect.height * (borderSettings.paddingTop / 100.0)
            padBottom = canvasRect.height * (borderSettings.paddingBottom / 100.0)
            padLeft = canvasRect.width * (borderSettings.paddingLeft / 100.0)
            padRight = canvasRect.width * (borderSettings.paddingRight / 100.0)
        } else {
            padTop = borderSettings.paddingTop
            padBottom = borderSettings.paddingBottom
            padLeft = borderSettings.paddingLeft
            padRight = borderSettings.paddingRight
        }
        
        let photoAreaX = padLeft
        let photoAreaY = padBottom + footerHeight
        let photoAreaWidth = max(10, canvasRect.width - padLeft - padRight)
        let photoAreaHeight = max(10, canvasRect.height - padTop - padBottom - footerHeight)
        let photoAreaRect = CGRect(x: photoAreaX, y: photoAreaY, width: photoAreaWidth, height: photoAreaHeight)
        
        // 4. 計算圓角
        let cornerRadius: CGFloat
        if borderSettings.cornerRadiusUnit == .percent {
            cornerRadius = min(photoAreaWidth, photoAreaHeight) * (borderSettings.cornerRadius / 100.0)
        } else {
            cornerRadius = borderSettings.cornerRadius
        }
        
        // 5. 繪製裁切後之相片主體
        context.saveGState()
        if cornerRadius > 0 {
            let path = CGPath(
                roundedRect: photoAreaRect,
                cornerWidth: cornerRadius,
                cornerHeight: cornerRadius,
                transform: nil
            )
            context.addPath(path)
            context.clip()
        } else {
            context.clip(to: photoAreaRect)
        }
        
        drawPhotoContent(
            context: context,
            sourceImage: image,
            targetRect: photoAreaRect,
            internalRatio: internalRatio,
            isZeroCrop: isZeroCrop,
            offset: imageOffset,
            scale: imageScale
        )
        context.restoreGState()
        
        // 6. 繪製相片底欄文字與標誌
        if footerSettings.isEnabled {
            let footerRect = CGRect(x: padLeft, y: padBottom, width: photoAreaWidth, height: footerHeight)
            drawFooter(
                context: context,
                footerRect: footerRect,
                settings: footerSettings,
                backgroundMode: backgroundMode,
                exif: exif,
                canvasWidth: canvasRect.width
            )
        }
        
        return context.makeImage()
    }
    
    /// 繪製背景 (白、黑、自訂 HSB、毛玻璃)
    private static func drawBackground(
        context: CGContext,
        canvasRect: CGRect,
        mode: BackgroundMode,
        sourceImage: CGImage
    ) {
        switch mode {
        case .white:
            context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.fill(canvasRect)
        case .black:
            context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
            context.fill(canvasRect)
        case let .customHSB(h, s, b):
            #if canImport(UIKit)
            let uiColor = UIColor(hue: h, saturation: s, brightness: b, alpha: 1.0)
            context.setFillColor(uiColor.cgColor)
            #else
            context.setFillColor(CGColor(red: CGFloat(b), green: CGFloat(b), blue: CGFloat(b), alpha: 1))
            #endif
            context.fill(canvasRect)
        case let .frostedGlass(blurRadius):
            // 毛玻璃：滿版覆蓋原圖並進行高斯模糊
            let ciImage = CIImage(cgImage: sourceImage)
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(ciImage.clampedToExtent(), forKey: kCIInputImageKey)
            filter?.setValue(blurRadius, forKey: kCIInputRadiusKey)
            
            if let outputCI = filter?.outputImage?.cropped(to: ciImage.extent),
               let blurredCG = ciContext.createCGImage(outputCI, from: ciImage.extent) {
                // 滿版 Fill 繪製至背景
                let imgRatio = CGFloat(sourceImage.width) / CGFloat(sourceImage.height)
                let canvasRatio = canvasRect.width / canvasRect.height
                var drawRect = canvasRect
                if imgRatio > canvasRatio {
                    let w = canvasRect.height * imgRatio
                    drawRect = CGRect(x: (canvasRect.width - w) / 2.0, y: 0, width: w, height: canvasRect.height)
                } else {
                    let h = canvasRect.width / imgRatio
                    drawRect = CGRect(x: 0, y: (canvasRect.height - h) / 2.0, width: canvasRect.width, height: h)
                }
                context.draw(blurredCG, in: drawRect)
            } else {
                context.setFillColor(CGColor(gray: 0.2, alpha: 1))
                context.fill(canvasRect)
            }
        }
    }
    
    /// 繪製相片主體（支援 Aspect Fit、滿版 Fill、零裁切）
    private static func drawPhotoContent(
        context: CGContext,
        sourceImage: CGImage,
        targetRect: CGRect,
        internalRatio: InternalCropRatio,
        isZeroCrop: Bool,
        offset: CGPoint,
        scale: CGFloat
    ) {
        let imgWidth = CGFloat(sourceImage.width)
        let imgHeight = CGFloat(sourceImage.height)
        let imgAspect = imgWidth / imgHeight
        
        let drawWidth: CGFloat
        let drawHeight: CGFloat
        
        if isZeroCrop {
            // 零裁切：以 Aspect-Fit 方式完整呈現全圖
            let rectAspect = targetRect.width / targetRect.height
            if imgAspect > rectAspect {
                drawWidth = targetRect.width * scale
                drawHeight = (targetRect.width / imgAspect) * scale
            } else {
                drawHeight = targetRect.height * scale
                drawWidth = (targetRect.height * imgAspect) * scale
            }
        } else {
            // 預設為滿版裁切 (Aspect-Fill)
            let rectAspect = targetRect.width / targetRect.height
            if imgAspect > rectAspect {
                drawHeight = targetRect.height * scale
                drawWidth = (targetRect.height * imgAspect) * scale
            } else {
                drawWidth = targetRect.width * scale
                drawHeight = (targetRect.width / imgAspect) * scale
            }
        }
        
        let drawX = targetRect.midX - (drawWidth / 2.0) + offset.x
        let drawY = targetRect.midY - (drawHeight / 2.0) + offset.y
        let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)
        
        context.draw(sourceImage, in: drawRect)
    }
    
    /// 繪製底欄資訊
    private static func drawFooter(
        context: CGContext,
        footerRect: CGRect,
        settings: FooterSettings,
        backgroundMode: BackgroundMode,
        exif: ExifMetadata,
        canvasWidth: CGFloat
    ) {
        let sections = settings.layoutSections
        
        func textForItems(_ items: [FooterItemType]) -> String {
            var parts: [String] = []
            for item in items {
                switch item {
                case .logo:
                    let brandStr = exif.detectedBrand != .unknown ? exif.detectedBrand.rawValue : (exif.make ?? "")
                    if !brandStr.isEmpty { parts.append(brandStr) }
                case .camera:
                    if !exif.cameraDisplayString.isEmpty { parts.append(exif.cameraDisplayString) }
                case .lens:
                    if !exif.lensDisplayString.isEmpty { parts.append(exif.lensDisplayString) }
                case .parameters:
                    if !exif.parametersDisplayString.isEmpty { parts.append(exif.parametersDisplayString) }
                case .date:
                    if let date = exif.dateTimeOriginal {
                        let df = DateFormatter()
                        df.dateFormat = "yyyy.MM.dd"
                        parts.append(df.string(from: date))
                    }
                case .customText:
                    if !settings.customText.isEmpty { parts.append(settings.customText) }
                case .spacer:
                    break
                }
            }
            return parts.filter { !$0.isEmpty }.joined(separator: "  |  ")
        }
        
        #if canImport(UIKit)
        var currentFontSize = max(10.0, canvasWidth * CGFloat(settings.fontSizeScale))
        var font = UIFont.systemFont(ofSize: currentFontSize, weight: .medium)
        let textColor: UIColor
        if let rgb = ColorSpaceService.hexToRgb(settings.textColorHex) {
            textColor = UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1.0)
        } else {
            switch backgroundMode {
            case .black:
                textColor = .white
            case .white:
                textColor = UIColor(white: 0.55, alpha: 1.0)
            case let .customHSB(_, _, b):
                textColor = b > 0.5 ? UIColor(white: 0.35, alpha: 1.0) : .white
            case .frostedGlass:
                textColor = .white
            }
        }
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        if sections.count <= 1 {
            // 0 Spacers: 全部置中
            let centerText = sections.first.map(textForItems) ?? ""
            guard !centerText.isEmpty else { return }
            
            var centerSize = (centerText as NSString).size(withAttributes: attributes)
            while centerSize.width > footerRect.width && currentFontSize > 7 {
                currentFontSize -= 1
                font = UIFont.systemFont(ofSize: currentFontSize, weight: .medium)
                attributes[.font] = font
                centerSize = (centerText as NSString).size(withAttributes: attributes)
            }
            
            context.saveGState()
            context.translateBy(x: 0, y: footerRect.maxY)
            context.scaleBy(x: 1.0, y: -1.0)
            UIGraphicsPushContext(context)
            let point = CGPoint(
                x: footerRect.minX + max(0, (footerRect.width - centerSize.width) / 2.0),
                y: (footerRect.height - centerSize.height) / 2.0
            )
            (centerText as NSString).draw(at: point, withAttributes: attributes)
            UIGraphicsPopContext()
            context.restoreGState()
            
        } else if sections.count == 2 {
            // 1 Spacer: 左右對齊
            let leftText = textForItems(sections[0])
            let rightText = textForItems(sections[1])
            
            var leftSize = (leftText as NSString).size(withAttributes: attributes)
            var rightSize = (rightText as NSString).size(withAttributes: attributes)
            
            while (leftSize.width + rightSize.width + 16 > footerRect.width) && currentFontSize > 7 {
                currentFontSize -= 1
                font = UIFont.systemFont(ofSize: currentFontSize, weight: .medium)
                attributes[.font] = font
                leftSize = (leftText as NSString).size(withAttributes: attributes)
                rightSize = (rightText as NSString).size(withAttributes: attributes)
            }
            
            context.saveGState()
            context.translateBy(x: 0, y: footerRect.maxY)
            context.scaleBy(x: 1.0, y: -1.0)
            UIGraphicsPushContext(context)
            if !leftText.isEmpty {
                let leftPoint = CGPoint(x: footerRect.minX, y: (footerRect.height - leftSize.height) / 2.0)
                (leftText as NSString).draw(at: leftPoint, withAttributes: attributes)
            }
            if !rightText.isEmpty {
                let rightPoint = CGPoint(x: footerRect.maxX - rightSize.width, y: (footerRect.height - rightSize.height) / 2.0)
                (rightText as NSString).draw(at: rightPoint, withAttributes: attributes)
            }
            UIGraphicsPopContext()
            context.restoreGState()
            
        } else {
            // 2 Spacers 或以上: 3 段式 (左、中、右)
            let leftText = textForItems(sections[0])
            let centerText = textForItems(sections[1])
            let rightText = textForItems(sections[2])
            
            var leftSize = (leftText as NSString).size(withAttributes: attributes)
            var centerSize = (centerText as NSString).size(withAttributes: attributes)
            var rightSize = (rightText as NSString).size(withAttributes: attributes)
            
            var totalContentW = [leftSize.width, centerSize.width, rightSize.width].filter { $0 > 0 }.reduce(0, +)
            while (totalContentW + 24 > footerRect.width) && currentFontSize > 7 {
                currentFontSize -= 1
                font = UIFont.systemFont(ofSize: currentFontSize, weight: .medium)
                attributes[.font] = font
                leftSize = (leftText as NSString).size(withAttributes: attributes)
                centerSize = (centerText as NSString).size(withAttributes: attributes)
                rightSize = (rightText as NSString).size(withAttributes: attributes)
                totalContentW = [leftSize.width, centerSize.width, rightSize.width].filter { $0 > 0 }.reduce(0, +)
            }
            
            context.saveGState()
            context.translateBy(x: 0, y: footerRect.maxY)
            context.scaleBy(x: 1.0, y: -1.0)
            UIGraphicsPushContext(context)
            if !leftText.isEmpty {
                let leftPoint = CGPoint(x: footerRect.minX, y: (footerRect.height - leftSize.height) / 2.0)
                (leftText as NSString).draw(at: leftPoint, withAttributes: attributes)
            }
            if !centerText.isEmpty {
                let centerPoint = CGPoint(
                    x: footerRect.minX + max(0, (footerRect.width - centerSize.width) / 2.0),
                    y: (footerRect.height - centerSize.height) / 2.0
                )
                (centerText as NSString).draw(at: centerPoint, withAttributes: attributes)
            }
            if !rightText.isEmpty {
                let rightPoint = CGPoint(x: footerRect.maxX - rightSize.width, y: (footerRect.height - rightSize.height) / 2.0)
                (rightText as NSString).draw(at: rightPoint, withAttributes: attributes)
            }
            UIGraphicsPopContext()
            context.restoreGState()
        }
        #endif
    }
    
    /// 切割為多張圖片切片 (Slices)
    public static func renderSlices(
        image: CGImage,
        canvasRatio: CanvasRatio,
        internalRatio: InternalCropRatio = .free,
        isZeroCrop: Bool = false,
        borderSettings: BorderSettings,
        backgroundMode: BackgroundMode,
        footerSettings: FooterSettings,
        splitSettings: SplitSettings,
        exif: ExifMetadata,
        baseWidth: CGFloat = 1080
    ) -> [CGImage] {
        guard let fullCanvas = render(
            image: image,
            canvasRatio: canvasRatio,
            internalRatio: internalRatio,
            isZeroCrop: isZeroCrop,
            borderSettings: borderSettings,
            backgroundMode: backgroundMode,
            footerSettings: footerSettings,
            exif: exif,
            baseWidth: baseWidth
        ) else {
            return []
        }
        
        if !splitSettings.isEnabled || splitSettings.splitCount <= 1 {
            return [fullCanvas]
        }
        
        let totalW = CGFloat(fullCanvas.width)
        let totalH = CGFloat(fullCanvas.height)
        let sliceRects = splitSettings.calculateSlices(totalWidth: totalW, totalHeight: totalH)
        
        var slices: [CGImage] = []
        for rect in sliceRects {
            if let slice = fullCanvas.cropping(to: rect) {
                slices.append(slice)
            }
        }
        
        return slices
    }
}
