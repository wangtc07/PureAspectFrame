import Foundation
import CoreGraphics

/// 相機品牌列舉（對應官方公開向量圖與品牌偵測）
public enum CameraBrand: String, CaseIterable, Identifiable, Codable, Sendable {
    case sony = "Sony"
    case canon = "Canon"
    case nikon = "Nikon"
    case fujifilm = "Fujifilm"
    case leica = "Leica"
    case apple = "Apple"
    case ricoh = "Ricoh"
    case hasselblad = "Hasselblad"
    case lumix = "Lumix"
    case olympus = "Olympus"
    case zeiss = "Zeiss"
    case unknown = "Other"
    
    public var id: String { rawValue }
    
    /// 依據 EXIF 的 Make 字串模糊比對品牌
    public static func detect(from makeString: String?) -> CameraBrand {
        guard let make = makeString?.lowercased() else { return .unknown }
        if make.contains("sony") { return .sony }
        if make.contains("canon") { return .canon }
        if make.contains("nikon") { return .nikon }
        if make.contains("fuji") { return .fujifilm }
        if make.contains("leica") { return .leica }
        if make.contains("apple") { return .apple }
        if make.contains("ricoh") || make.contains("pentax") { return .ricoh }
        if make.contains("hasselblad") { return .hasselblad }
        if make.contains("panasonic") || make.contains("lumix") { return .lumix }
        if make.contains("olympus") || make.contains("om digital") { return .olympus }
        if make.contains("zeiss") { return .zeiss }
        return .unknown
    }
}

/// 解析並儲存照片之 EXIF / TIFF / MakerNote 拍攝資訊
public struct ExifMetadata: Codable, Equatable, Sendable {
    public var make: String?
    public var model: String?
    public var lensModel: String?
    public var focalLength: Double?
    public var focalLengthIn35mm: Double?
    public var fNumber: Double?
    public var shutterSpeed: String?
    public var iso: Int?
    public var dateTimeOriginal: Date?
    
    public init(
        make: String? = nil,
        model: String? = nil,
        lensModel: String? = nil,
        focalLength: Double? = nil,
        focalLengthIn35mm: Double? = nil,
        fNumber: Double? = nil,
        shutterSpeed: String? = nil,
        iso: Int? = nil,
        dateTimeOriginal: Date? = nil
    ) {
        self.make = make
        self.model = model
        self.lensModel = lensModel
        self.focalLength = focalLength
        self.focalLengthIn35mm = focalLengthIn35mm
        self.fNumber = fNumber
        self.shutterSpeed = shutterSpeed
        self.iso = iso
        self.dateTimeOriginal = dateTimeOriginal
    }
    
    /// 偵測相機品牌
    public var detectedBrand: CameraBrand {
        CameraBrand.detect(from: make)
    }
    
    /// 機身顯示字串 (例如 "SONY ILCE-7RM5" 或 "LEICA M11")
    public var cameraDisplayString: String {
        let cleanMake = make?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleanModel = model?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if cleanModel.isEmpty { return cleanMake }
        if cleanMake.isEmpty { return cleanModel }
        
        let brandName = detectedBrand.rawValue.lowercased()
        if brandName != "unknown" && cleanModel.lowercased().contains(brandName) {
            return cleanModel
        }
        
        if cleanModel.lowercased().hasPrefix(cleanMake.lowercased()) {
            return cleanModel
        }
        
        return "\(cleanMake) \(cleanModel)"
    }
    
    /// 鏡頭顯示字串
    public var lensDisplayString: String {
        lensModel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    /// 格式化快門速度（若輸入為秒數例如 0.002 -> "1/500s"；0.5 -> "0.5s"；2.0 -> "2s"）
    public static func formatShutterSpeed(_ seconds: Double) -> String {
        if seconds <= 0 { return "" }
        if seconds < 1.0 {
            let denominator = Int((1.0 / seconds).rounded())
            return "1/\(denominator)s"
        } else if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(seconds))s"
        } else {
            return String(format: "%.1fs", seconds)
        }
    }
    
    /// 拍攝參數整合字串 (例如 "50mm  f/1.2  1/500s  ISO 100")
    public var parametersDisplayString: String {
        var parts: [String] = []
        
        if let fl = focalLength {
            let flInt = Int(fl.rounded())
            parts.append("\(flInt)mm")
        }
        
        if let fn = fNumber {
            if fn.truncatingRemainder(dividingBy: 1) == 0 {
                parts.append("f/\(Int(fn))")
            } else {
                parts.append(String(format: "f/%.1f", fn))
            }
        }
        
        if let ss = shutterSpeed, !ss.isEmpty {
            if ss.hasSuffix("s") {
                parts.append(ss)
            } else {
                parts.append("\(ss)s")
            }
        }
        
        if let isoVal = iso {
            parts.append("ISO \(isoVal)")
        }
        
        return parts.joined(separator: "  ")
    }
}
