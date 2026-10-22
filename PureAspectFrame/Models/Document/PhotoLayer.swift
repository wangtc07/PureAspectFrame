import Foundation

public nonisolated enum ImageRatio: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case original
    case r1x1
    case r4x5
    case r3x2
    case r16x9
    case r9x16

    public func widthOverHeight(photoAspect: Double) -> Double {
        switch self {
        case .original:
            return photoAspect
        case .r1x1:
            return 1
        case .r4x5:
            return 4.0 / 5.0
        case .r3x2:
            return 3.0 / 2.0
        case .r16x9:
            return 16.0 / 9.0
        case .r9x16:
            return 9.0 / 16.0
        }
    }
}

public nonisolated struct PhotoLayer: Codable, Equatable, Sendable {
    public var imageRatio: ImageRatio
    public var cornerRadius: Percent

    public init(imageRatio: ImageRatio = .original, cornerRadius: Percent = Percent(0)) {
        self.imageRatio = imageRatio
        self.cornerRadius = cornerRadius
    }

    enum CodingKeys: String, CodingKey {
        case imageRatio
        case cornerRadius
    }
}

public nonisolated struct CropTransform: Codable, Equatable, Sendable {
    public var scale: Double
    public var offsetX: Double
    public var offsetY: Double

    public init(scale: Double = 1, offsetX: Double = 0, offsetY: Double = 0) {
        self.scale = min(5, max(1, scale))
        self.offsetX = offsetX
        self.offsetY = offsetY
    }

    public static let identity = CropTransform()
}

public nonisolated struct EditSnapshot: Equatable, Sendable {
    public var document: FrameDocument
    public var crops: [UUID: CropTransform]

    public init(document: FrameDocument = FrameDocument(), crops: [UUID: CropTransform] = [:]) {
        self.document = document
        self.crops = crops
    }

    public mutating func apply(template: FrameDocument) {
        document = template
    }
}
