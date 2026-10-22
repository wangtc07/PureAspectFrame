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

/// 官方 SNS 向量圖示列舉（直接採用 Instagram、Threads、X 官方 24x24 SVG 向量座標與路徑）
public enum SNSOfficialIcon: String, CaseIterable, Identifiable, Sendable {
    case igHeart
    case igComment
    case igRepost
    case igShare
    case igBookmark
    case xReply
    case xRetweet
    case xHeart
    case xBookmark
    case xShare
    case xVerified
    case xLogo
    
    public var id: String { rawValue }
    
    /// 是否為描邊型 (Stroke) 圖示；false 則為填滿型 (Fill) SVG 路徑
    public var isStroked: Bool {
        switch self {
        case .igHeart, .igComment, .igShare, .igBookmark, .xHeart:
            return true
        case .igRepost, .xReply, .xRetweet, .xBookmark, .xShare, .xVerified, .xLogo:
            return false
        }
    }
    
    /// 在指定矩形中生成對應之 24x24 正規化官方向量 Path
    public func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24.0
        let sy = rect.height / 24.0
        let scale = min(sx, sy)
        
        switch self {
        case .igHeart:
            // Instagram / Threads 官方愛心輪廓 (24x24 viewBox)
            var p = Path()
            p.move(to: CGPoint(x: 12.0 * sx, y: 20.85 * sy))
            p.addCurve(
                to: CGPoint(x: 2.0 * sx, y: 8.8 * sy),
                control1: CGPoint(x: 8.2 * sx, y: 17.6 * sy),
                control2: CGPoint(x: 2.0 * sx, y: 13.3 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 7.2 * sx, y: 3.1 * sy),
                control1: CGPoint(x: 2.0 * sx, y: 5.4 * sy),
                control2: CGPoint(x: 4.3 * sx, y: 3.1 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 12.0 * sx, y: 6.0 * sy),
                control1: CGPoint(x: 9.3 * sx, y: 3.1 * sy),
                control2: CGPoint(x: 11.0 * sx, y: 4.3 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 16.8 * sx, y: 3.1 * sy),
                control1: CGPoint(x: 13.0 * sx, y: 4.3 * sy),
                control2: CGPoint(x: 14.7 * sx, y: 3.1 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 22.0 * sx, y: 8.8 * sy),
                control1: CGPoint(x: 19.7 * sx, y: 3.1 * sy),
                control2: CGPoint(x: 22.0 * sx, y: 5.4 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 12.0 * sx, y: 20.85 * sy),
                control1: CGPoint(x: 22.0 * sx, y: 13.3 * sy),
                control2: CGPoint(x: 15.8 * sx, y: 17.6 * sy)
            )
            p.closeSubpath()
            return p
            
        case .igComment:
            // Instagram / Threads 官方留言對話框 (M20.656 17.008a9.993 9.993 0 1 0-3.59 3.615L22 22Z，尾巴在右下角)
            var p = Path()
            let cx = 12.0 * sx
            let cy = 12.0 * sy
            let r = 9.4 * scale
            let startDeg = 60.0
            let endDeg = 390.0
            let steps = 48
            for i in 0...steps {
                let deg = startDeg + (endDeg - startDeg) * Double(i) / Double(steps)
                let rad = deg * .pi / 180.0
                let pt = CGPoint(x: cx + r * CGFloat(cos(rad)), y: cy + r * CGFloat(sin(rad)))
                if i == 0 {
                    p.move(to: pt)
                } else {
                    p.addLine(to: pt)
                }
            }
            p.addLine(to: CGPoint(x: 21.6 * sx, y: 21.6 * sy))
            p.closeSubpath()
            return p
            
        case .igRepost:
            // Instagram / Threads 官方轉發圖示 SVG Path
            let svg = "M19.998 9.497c-.552 0-1 .448-1 1v4.228c0 1.808-1.462 3.27-3.27 3.27h-5.313l1.791-1.787c.39-.39.39-1.024 0-1.416-.39-.39-1.022-.39-1.412 0L7.29 18.287c-.188.188-.294.442-.294.707v.066c0 .242.101.473.281.643l3.502 3.504c.39.39 1.024.39 1.414 0 .39-.39.39-1.024 0-1.414l-1.797-1.798h5.318c2.91 0 5.27-2.36 5.27-5.27V10.497c0-.552-.448-1-1-1zm-16 5.006c.552 0 1-.448 1-1V9.275c0-1.808 1.462-3.27 3.27-3.27h5.313l-1.791 1.787c-.39.39-.39 1.024 0 1.416.39.39 1.022.39 1.412 0L16.71 5.713c.188-.188.294-.442.294-.707v-.066c0-.242-.101-.473-.281-.643L13.221.793c-.39-.39-1.024-.39-1.414 0-.39.39-.39 1.024 0 1.414l1.797 1.798H8.283c-2.91 0-5.27 2.36-5.27 5.27v4.233c0 .552.448 1 1 1z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
            
        case .igShare:
            // Instagram / Threads 官方紙飛機分享圖示 (<polygon points="11.698 20.334 22 3.001 2 3.001 9.218 10.084 11.698 20.334"/> + <line x1="22" y1="3" x2="9.218" y2="10.083"/>)
            var p = Path()
            p.move(to: CGPoint(x: 11.698 * sx, y: 20.334 * sy))
            p.addLine(to: CGPoint(x: 22.0 * sx, y: 3.001 * sy))
            p.addLine(to: CGPoint(x: 2.0 * sx, y: 3.001 * sy))
            p.addLine(to: CGPoint(x: 9.218 * sx, y: 10.084 * sy))
            p.closeSubpath()
            p.move(to: CGPoint(x: 22.0 * sx, y: 3.001 * sy))
            p.addLine(to: CGPoint(x: 9.218 * sx, y: 10.083 * sy))
            return p
            
        case .igBookmark:
            // Instagram 官方收藏書籤圖示 (<polygon points="20 21 12 13.44 4 21 4 3 20 3 20 21"/>)
            var p = Path()
            p.move(to: CGPoint(x: 20.0 * sx, y: 21.0 * sy))
            p.addLine(to: CGPoint(x: 12.0 * sx, y: 13.44 * sy))
            p.addLine(to: CGPoint(x: 4.0 * sx, y: 21.0 * sy))
            p.addLine(to: CGPoint(x: 4.0 * sx, y: 3.0 * sy))
            p.addLine(to: CGPoint(x: 20.0 * sx, y: 3.0 * sy))
            p.closeSubpath()
            return p
            
        case .xReply:
            let svg = "M1.751 10c0-4.42 3.584-8 8.005-8h4.366c4.49 0 8.129 3.64 8.129 8.13 0 2.96-1.607 5.68-4.196 7.11l-8.054 4.46v-3.69h-.067c-4.49.1-8.183-3.51-8.183-8.01zm8.005-6c-3.317 0-6.005 2.69-6.005 6 0 3.37 2.77 6.08 6.138 6.01l.351-.01h1.761v2.3l5.087-2.81c1.951-1.08 3.163-3.13 3.163-5.36 0-3.39-2.738-6.13-6.125-6.13H9.756z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
            
        case .xRetweet:
            let svg = "M4.5 3.88l4.432 4.14-1.364 1.46L5.5 7.55V16c0 1.1.896 2 2 2H13v2H7.5c-2.209 0-4-1.79-4-4V7.55L1.432 9.48.068 8.02 4.5 3.88zM16.5 6H11V4h5.5c2.209 0 4 1.79 4 4v8.45l2.068-1.93 1.364 1.46-4.432 4.14-4.432-4.14 1.364-1.46 2.068 1.93V8c0-1.1-.896-2-2-2z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
            
        case .xHeart:
            // X (Twitter) 官方愛心輪廓 (24x24 viewBox)
            var p = Path()
            p.move(to: CGPoint(x: 12.0 * sx, y: 20.1 * sy))
            p.addCurve(
                to: CGPoint(x: 3.0 * sx, y: 9.2 * sy),
                control1: CGPoint(x: 8.1 * sx, y: 17.5 * sy),
                control2: CGPoint(x: 3.0 * sx, y: 13.4 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 7.5 * sx, y: 4.5 * sy),
                control1: CGPoint(x: 3.0 * sx, y: 6.3 * sy),
                control2: CGPoint(x: 5.0 * sx, y: 4.5 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 12.0 * sx, y: 7.4 * sy),
                control1: CGPoint(x: 9.3 * sx, y: 4.5 * sy),
                control2: CGPoint(x: 11.0 * sx, y: 5.6 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 16.5 * sx, y: 4.5 * sy),
                control1: CGPoint(x: 13.0 * sx, y: 5.6 * sy),
                control2: CGPoint(x: 14.7 * sx, y: 4.5 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 21.0 * sx, y: 9.2 * sy),
                control1: CGPoint(x: 19.0 * sx, y: 4.5 * sy),
                control2: CGPoint(x: 21.0 * sx, y: 6.3 * sy)
            )
            p.addCurve(
                to: CGPoint(x: 12.0 * sx, y: 20.1 * sy),
                control1: CGPoint(x: 21.0 * sx, y: 13.4 * sy),
                control2: CGPoint(x: 15.9 * sx, y: 17.5 * sy)
            )
            p.closeSubpath()
            return p
            
        case .xBookmark:
            let svg = "M4 4.5C4 3.12 5.119 2 6.5 2h11C18.881 2 20 3.12 20 4.5v18.44l-8-5.71-8 5.71V4.5zM6.5 4c-.276 0-.5.22-.5.5v14.56l6-4.29 6 4.29V4.5c0-.28-.224-.5-.5-.5h-11z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
            
        case .xShare:
            let svg = "M12 2.59l5.7 5.7-1.41 1.42L13 6.41V16h-2V6.41l-3.3 3.3-1.41-1.42L12 2.59zM21 15l-.02 3.51c0 1.38-1.12 2.49-2.5 2.49H5.5C4.11 21 3 19.88 3 18.5V15h2v3.5c0 .28.22.5.5.5h12.98c.28 0 .5-.22.5-.5L19 15h2z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
            
        case .xVerified:
            let svg = "M22.25 12c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.66-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.33 2.19c-1.4-.46-2.91-.2-3.92.81s-1.26 2.52-.8 3.91c-1.31.67-2.2 1.91-2.2 3.34s.89 2.67 2.2 3.34c-.46 1.39-.21 2.9.8 3.91s2.52 1.26 3.91.81c.67 1.31 1.91 2.19 3.34 2.19s2.68-.88 3.34-2.19c1.39.45 2.9.2 3.91-.81s1.27-2.52.81-3.91c1.31-.67 2.19-1.91 2.19-3.34zm-11.71 4.2L6.8 12.46l1.41-1.42 2.26 2.26 4.8-5.23 1.47 1.36-6.2 6.77z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
            
        case .xLogo:
            let svg = "M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
            return OfficialSVGPathParser.parse(svg, sx: sx, sy: sy)
        }
    }
}

/// 輕量級官方 SVG Path (`d` 屬性) 向量解析器（支援 M/m, L/l, H/h, V/v, C/c, S/s, Z/z）
private enum OfficialSVGPathParser {
    private enum Token {
        case command(Character)
        case number(CGFloat)
    }
    
    static func parse(_ d: String, sx: CGFloat, sy: CGFloat) -> Path {
        let tokens = tokenize(d)
        var path = Path()
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero
        var lastControl: CGPoint? = nil
        var lastCmd: Character = " "
        var idx = 0
        var activeCmd: Character = "M"
        
        func nextNumber() -> CGFloat? {
            guard idx < tokens.count else { return nil }
            if case .number(let v) = tokens[idx] {
                idx += 1
                return v
            }
            return nil
        }
        
        while idx < tokens.count {
            if case .command(let c) = tokens[idx] {
                activeCmd = c
                idx += 1
            }
            
            switch activeCmd {
            case "M":
                guard let x = nextNumber(), let y = nextNumber() else { break }
                current = CGPoint(x: x, y: y)
                subpathStart = current
                path.move(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
                activeCmd = "L"
            case "m":
                guard let dx = nextNumber(), let dy = nextNumber() else { break }
                current = CGPoint(x: current.x + dx, y: current.y + dy)
                subpathStart = current
                path.move(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
                activeCmd = "l"
            case "L":
                guard let x = nextNumber(), let y = nextNumber() else { break }
                current = CGPoint(x: x, y: y)
                path.addLine(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
            case "l":
                guard let dx = nextNumber(), let dy = nextNumber() else { break }
                current = CGPoint(x: current.x + dx, y: current.y + dy)
                path.addLine(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
            case "H":
                guard let x = nextNumber() else { break }
                current.x = x
                path.addLine(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
            case "h":
                guard let dx = nextNumber() else { break }
                current.x += dx
                path.addLine(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
            case "V":
                guard let y = nextNumber() else { break }
                current.y = y
                path.addLine(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
            case "v":
                guard let dy = nextNumber() else { break }
                current.y += dy
                path.addLine(to: CGPoint(x: current.x * sx, y: current.y * sy))
                lastControl = nil
                lastCmd = activeCmd
            case "C":
                guard let x1 = nextNumber(), let y1 = nextNumber(),
                      let x2 = nextNumber(), let y2 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() else { break }
                let c1 = CGPoint(x: x1, y: y1)
                let c2 = CGPoint(x: x2, y: y2)
                current = CGPoint(x: x, y: y)
                path.addCurve(
                    to: CGPoint(x: current.x * sx, y: current.y * sy),
                    control1: CGPoint(x: c1.x * sx, y: c1.y * sy),
                    control2: CGPoint(x: c2.x * sx, y: c2.y * sy)
                )
                lastControl = c2
                lastCmd = activeCmd
            case "c":
                guard let dx1 = nextNumber(), let dy1 = nextNumber(),
                      let dx2 = nextNumber(), let dy2 = nextNumber(),
                      let dx = nextNumber(), let dy = nextNumber() else { break }
                let c1 = CGPoint(x: current.x + dx1, y: current.y + dy1)
                let c2 = CGPoint(x: current.x + dx2, y: current.y + dy2)
                current = CGPoint(x: current.x + dx, y: current.y + dy)
                path.addCurve(
                    to: CGPoint(x: current.x * sx, y: current.y * sy),
                    control1: CGPoint(x: c1.x * sx, y: c1.y * sy),
                    control2: CGPoint(x: c2.x * sx, y: c2.y * sy)
                )
                lastControl = c2
                lastCmd = activeCmd
            case "S":
                guard let x2 = nextNumber(), let y2 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() else { break }
                let c1: CGPoint
                if ("CcSs".contains(lastCmd)), let lc = lastControl {
                    c1 = CGPoint(x: 2 * current.x - lc.x, y: 2 * current.y - lc.y)
                } else {
                    c1 = current
                }
                let c2 = CGPoint(x: x2, y: y2)
                current = CGPoint(x: x, y: y)
                path.addCurve(
                    to: CGPoint(x: current.x * sx, y: current.y * sy),
                    control1: CGPoint(x: c1.x * sx, y: c1.y * sy),
                    control2: CGPoint(x: c2.x * sx, y: c2.y * sy)
                )
                lastControl = c2
                lastCmd = activeCmd
            case "s":
                guard let dx2 = nextNumber(), let dy2 = nextNumber(),
                      let dx = nextNumber(), let dy = nextNumber() else { break }
                let c1: CGPoint
                if ("CcSs".contains(lastCmd)), let lc = lastControl {
                    c1 = CGPoint(x: 2 * current.x - lc.x, y: 2 * current.y - lc.y)
                } else {
                    c1 = current
                }
                let c2 = CGPoint(x: current.x + dx2, y: current.y + dy2)
                current = CGPoint(x: current.x + dx, y: current.y + dy)
                path.addCurve(
                    to: CGPoint(x: current.x * sx, y: current.y * sy),
                    control1: CGPoint(x: c1.x * sx, y: c1.y * sy),
                    control2: CGPoint(x: c2.x * sx, y: c2.y * sy)
                )
                lastControl = c2
                lastCmd = activeCmd
            case "Z", "z":
                path.closeSubpath()
                current = subpathStart
                lastControl = nil
                lastCmd = activeCmd
            default:
                idx += 1
            }
        }
        return path
    }
    
    private static func tokenize(_ d: String) -> [Token] {
        var result: [Token] = []
        let chars = Array(d)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace || c == "," {
                i += 1
                continue
            }
            if c.isLetter {
                result.append(.command(c))
                i += 1
                continue
            }
            if c == "-" || c == "+" || c == "." || c.isNumber {
                var numStr = String(c)
                var hasDot = (c == ".")
                i += 1
                while i < chars.count {
                    let nc = chars[i]
                    if nc.isNumber {
                        numStr.append(nc)
                        i += 1
                    } else if nc == "." && !hasDot {
                        hasDot = true
                        numStr.append(nc)
                        i += 1
                    } else {
                        break
                    }
                }
                if let val = Double(numStr) {
                    result.append(.number(CGFloat(val)))
                }
                continue
            }
            i += 1
        }
        return result
    }
}

/// 官方 SNS 圖示渲染視圖
private struct SNSOfficialIconView: View {
    let icon: SNSOfficialIcon
    var size: CGFloat = 22
    var strokeWidth: CGFloat = 1.9
    
    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let path = icon.path(in: rect)
            if icon.isStroked {
                context.stroke(
                    path,
                    with: .foreground,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                )
            } else {
                context.fill(path, with: .foreground)
            }
        }
        .frame(width: size, height: size)
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

/// SNS 發佈模擬預覽視圖（呈現完整單則貼文區域：中性假帳號、日期符號內文、100% 真實比例圖片區與互動分享圖示列）
public struct SNSPreviewView: View {
    var renderedImage: CGImage?
    var slices: [CGImage]
    
    @State private var selectedPlatform: SNSTargetPlatform
    @State private var instagramPageIndex: Int = 0
    @State private var isThreadsMerged: Bool
    @State private var threadsPinchScale: CGFloat = 1.0
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 中性假資料常數與互動圖示規格
    public static let placeholderUsername: String = "username"
    public static let placeholderHandle: String = "@user_id"
    public static let placeholderCaption: String = "2026.10.20  📷 ✨"
    
    /// 各平台實際官方 SVG 向量圖示列
    public static func officialActionIcons(for platform: SNSTargetPlatform) -> [SNSOfficialIcon] {
        switch platform {
        case .instagram:
            return [.igHeart, .igComment, .igRepost, .igShare, .igBookmark]
        case .threads:
            return [.igHeart, .igComment, .igRepost, .igShare]
        case .xTwitter:
            return [.xReply, .xRetweet, .xHeart, .xBookmark, .xShare]
        case .redBook:
            return [.igHeart, .igComment, .igShare, .igBookmark]
        }
    }
    
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
                VStack(spacing: 12) {
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
                        VStack(spacing: 4) {
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
                                .padding(.vertical, 6)
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
                    
                    // 3. 完整貼文預覽區 (含中性假帳號、日期符號內文、動態比例圖片區、按讚轉發分享收藏圖示列)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            switch selectedPlatform {
                            case .instagram:
                                instagramPostView(screenWidth: screenWidth)
                            case .threads:
                                threadsPostView(screenWidth: screenWidth)
                            case .xTwitter:
                                xTwitterPostView(screenWidth: screenWidth)
                            case .redBook:
                                redBookPostView(screenWidth: screenWidth)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("SNS 發佈預覽")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseToolbarButton { dismiss() }
                }
            }
        }
    }
    
    // MARK: - 共用中性假頭像
    private func placeholderAvatar(size: CGFloat) -> some View {
        Circle()
            .fill(Color.secondary.opacity(0.22))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundStyle(.secondary)
            }
    }
    
    // =========================================================================
    // MARK: - 1. Instagram 完整貼文預覽區
    // =========================================================================
    @ViewBuilder
    private func instagramPostView(screenWidth: CGFloat) -> some View {
        let firstAspect = displayImages.first.map { aspectRatio(of: $0) } ?? 1.0
        let mediaHeight = Self.instagramMediaHeight(containerWidth: screenWidth, imageAspectRatio: firstAspect)
        
        VStack(alignment: .leading, spacing: 0) {
            // 1. 帳號列 (頭像 + username + 右側官方左對齊雙橫線選單)
            HStack(spacing: 10) {
                placeholderAvatar(size: 32)
                
                Text(Self.placeholderUsername)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4.5) {
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: 18, height: 1.9)
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: 11, height: 1.9)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            
            // 2. 滿版 100% 寬度圖片區 (0 圓角、依實際圖片比例動態決定高度)
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
                .clipShape(Rectangle())
                
                // 3. 圖片正下方獨立置中輪播圓點指示器
                HStack(spacing: 5) {
                    Spacer()
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
                    Spacer()
                }
                .padding(.top, 11)
                .padding(.bottom, 2)
            } else if let img = displayImages.first {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenWidth, height: mediaHeight)
                    .clipShape(Rectangle())
            }
            
            // 4. 官方 Instagram SVG 互動與分享圖示列 (Heart 5, Comment, Repost, Direct Share ... Bookmark)
            HStack(spacing: 18) {
                HStack(spacing: 5) {
                    SNSOfficialIconView(icon: .igHeart, size: 23, strokeWidth: 1.95)
                    Text("5")
                        .font(.system(size: 14, weight: .semibold))
                }
                SNSOfficialIconView(icon: .igComment, size: 22.5, strokeWidth: 1.95)
                SNSOfficialIconView(icon: .igRepost, size: 23.5)
                SNSOfficialIconView(icon: .igShare, size: 22.5, strokeWidth: 1.95)
                
                Spacer()
                
                SNSOfficialIconView(icon: .igBookmark, size: 22.5, strokeWidth: 1.95)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            // 5. 按讚頭像疊加列 + 中性內文與日期
            HStack(spacing: 8) {
                HStack(spacing: -6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.secondary.opacity(0.3 + Double(i) * 0.12))
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(Color(uiColor: .systemBackground), lineWidth: 1.5)
                            )
                    }
                }
                HStack(spacing: 4) {
                    Text("Liked by")
                        .foregroundStyle(.primary)
                    Text("user_a")
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("and others")
                        .foregroundStyle(.primary)
                }
                .font(.system(size: 13))
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 5)
            
            HStack(spacing: 6) {
                Text(Self.placeholderUsername)
                    .font(.system(size: 13.5, weight: .semibold))
                Text(Self.placeholderCaption)
                    .font(.system(size: 13.5))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            
            Text("2026年10月20日")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 4)
        }
    }
    
    // =========================================================================
    // MARK: - 2. Threads 完整貼文預覽區
    // =========================================================================
    @ViewBuilder
    private func threadsPostView(screenWidth: CGFloat) -> some View {
        // 實機比例：carouselHeight = 397 / 472 * screenWidth (約 0.841 * screenWidth)
        let baseCarouselHeight = round(screenWidth * (397.0 / 472.0))
        
        VStack(alignment: .leading, spacing: 0) {
            // 1. 帳號列 (頭像 + username + 日期 + •••)
            HStack(spacing: 10) {
                placeholderAvatar(size: 36)
                
                HStack(spacing: 6) {
                    Text(Self.placeholderUsername)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("26/10/20")
                        .font(.system(size: 13.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
            
            // 2. 貼文內文列 (位於圖片上方，使用日期與符號假資料)
            Text(Self.placeholderCaption)
                .font(.system(size: 14.5))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            
            // 3. 貼文圖片區 (左留白 12pt、右側出血水平滾動、依真實切片比例計算寬度、雙指捏合無縫合體)
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
            
            // 4. 官方 Threads SVG 互動與分享圖示列 (Heart 2, Comment, Repost, Share)
            HStack(spacing: 22) {
                HStack(spacing: 5) {
                    SNSOfficialIconView(icon: .igHeart, size: 20, strokeWidth: 1.85)
                    Text("2")
                        .font(.system(size: 13.5))
                }
                SNSOfficialIconView(icon: .igComment, size: 19.5, strokeWidth: 1.85)
                SNSOfficialIconView(icon: .igRepost, size: 20.5)
                SNSOfficialIconView(icon: .igShare, size: 19.5, strokeWidth: 1.85)
                Spacer()
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.top, 13)
            
            // 5. Threads 貼文下方查看動態列與分隔線
            HStack {
                Spacer()
                HStack(spacing: 3) {
                    Text("View activity")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 10)
            
            Divider()
        }
    }
    
    // =========================================================================
    // MARK: - 3. X (Twitter) 完整貼文預覽區
    // =========================================================================
    @ViewBuilder
    private func xTwitterPostView(screenWidth: CGFloat) -> some View {
        // 實機比例：carouselHeight = 399 / 472 * screenWidth (約 0.845 * screenWidth)
        let baseCarouselHeight = round(screenWidth * (399.0 / 472.0))
        
        VStack(alignment: .leading, spacing: 0) {
            // 1. 帳號列 (頭像 + username + 官方 X 藍勾勾 + @user_id + 右側官方 X.com 標誌)
            HStack(alignment: .center, spacing: 10) {
                placeholderAvatar(size: 40)
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 3.5) {
                        Text(Self.placeholderUsername)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                        SNSOfficialIconView(icon: .xVerified, size: 16.5)
                            .foregroundStyle(Color(red: 29/255, green: 155/255, blue: 240/255))
                    }
                    Text(Self.placeholderHandle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 0.5) {
                    SNSOfficialIconView(icon: .xLogo, size: 17)
                    Text(".com")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            
            // 2. 貼文內文列 (日期與符號假資料)
            Text(Self.placeholderCaption)
                .font(.system(size: 14.5))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            
            // 3. 貼文圖片區 (左留白 10pt、右側出血水平滾動、4pt 間隙、12pt 圓角、依真實切片比例計算寬度)
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
            
            // 4. 時間與觀看數列
            HStack(spacing: 4) {
                Text("17:51 · 2026/10/20 ·")
                    .foregroundStyle(.secondary)
                Text("3,824")
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("Views")
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 13.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Divider()
                .padding(.horizontal, 12)
            
            // 5. 官方 X (Twitter) SVG 互動與分享圖示列 (Reply 2 | Retweet 30 | Like 197 | Bookmark 4 | Share)
            HStack {
                HStack(spacing: 5) {
                    SNSOfficialIconView(icon: .xReply, size: 19)
                    Text("2")
                }
                Spacer()
                HStack(spacing: 5) {
                    SNSOfficialIconView(icon: .xRetweet, size: 19)
                    Text("30")
                }
                Spacer()
                HStack(spacing: 5) {
                    SNSOfficialIconView(icon: .xHeart, size: 19)
                    Text("197")
                }
                Spacer()
                HStack(spacing: 5) {
                    SNSOfficialIconView(icon: .xBookmark, size: 19)
                    Text("4")
                }
                Spacer()
                SNSOfficialIconView(icon: .xShare, size: 19)
            }
            .font(.system(size: 13.5))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            Divider()
                .padding(.horizontal, 12)
        }
    }
    
    // =========================================================================
    // MARK: - 4. 小紅書 完整貼文預覽區
    // =========================================================================
    @ViewBuilder
    private func redBookPostView(screenWidth: CGFloat) -> some View {
        let availableW = screenWidth - 24
        let firstAspect = displayImages.first.map { aspectRatio(of: $0) } ?? 0.75
        let clampedAspect = min(max(firstAspect, 0.75), 1.33)
        let mediaHeight = availableW / clampedAspect
        
        VStack(alignment: .leading, spacing: 10) {
            // 1. 帳號列
            HStack(spacing: 10) {
                placeholderAvatar(size: 32)
                Text(Self.placeholderUsername)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            
            // 2. 圖片區
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
                    Spacer()
                    ForEach(0..<displayImages.count, id: \.self) { idx in
                        Circle()
                            .fill(idx == instagramPageIndex ? Color(hex: "#FF2442") : Color.secondary.opacity(0.35))
                            .frame(width: 5.5, height: 5.5)
                    }
                    Spacer()
                }
            } else if let img = displayImages.first {
                Image(decorative: img, scale: 1.0)
                    .resizable()
                    .scaledToFill()
                    .frame(width: availableW, height: mediaHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(.horizontal, 12)
            }
            
            // 3. 內文與互動分享列
            Text(Self.placeholderCaption)
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
            
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("32")
                }
                HStack(spacing: 4) {
                    Image(systemName: "star")
                    Text("16")
                }
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("4")
                }
                Spacer()
                Image(systemName: "square.and.arrow.up")
            }
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.top, 2)
        }
    }
}
