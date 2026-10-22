import Foundation

public nonisolated enum DocumentShapeError: Error, Equatable {
    /// `layers` 與 padding、footer、canvas、split、borderSettings 同時出現。禁止合併。
    case bothBorderModels
}

public nonisolated struct RGBColor: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public static let white = RGBColor(red: 1, green: 1, blue: 1)
    public static let black = RGBColor(red: 0, green: 0, blue: 0)
}

public nonisolated struct BackgroundSpec: Codable, Equatable, Sendable {
    public var color: RGBColor
    /// 毛玻璃留在底色。半徑是長邊百分比。nil 表示沒有毛玻璃。
    public var frostRadius: Percent?
    public init(color: RGBColor, frostRadius: Percent? = nil) {
        self.color = color
        self.frostRadius = frostRadius
    }

    public static let white = BackgroundSpec(color: .white)
}

public nonisolated struct LensOverride: Codable, Equatable, Sendable {
    public var lensName: String
    public var focalLengthMillimeters: Double

    public init(lensName: String, focalLengthMillimeters: Double) {
        self.lensName = lensName
        self.focalLengthMillimeters = focalLengthMillimeters
    }
}

public nonisolated struct FrameDocument: Codable, Equatable, Sendable {
    public static let schemaVersion = 3

    public var layers: LayerStack
    public var background: BackgroundSpec
    public var signatureText: String
    public var lensOverride: LensOverride?

    public init(
        layers: LayerStack = LayerStack(),
        background: BackgroundSpec = .white,
        signatureText: String = "",
        lensOverride: LensOverride? = nil
    ) {
        self.layers = layers
        self.background = background
        self.signatureText = signatureText
        self.lensOverride = lensOverride
    }

    private enum CodingKeys: String, CodingKey {
        case layers
        case background
        case signatureText
        case lensOverride
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layers, forKey: .layers)
        try container.encode(background, forKey: .background)
        try container.encode(signatureText, forKey: .signatureText)
        try container.encode(lensOverride, forKey: .lensOverride)
    }

    public init(from decoder: Decoder) throws {
        let probe = try decoder.container(keyedBy: AnyCodingKey.self)
        let present = Set(probe.allKeys.map(\.stringValue))
        let legacy: Set<String> = ["padding", "footer", "canvas", "split", "borderSettings"]
        if present.contains("layers") && !present.isDisjoint(with: legacy) {
            throw DocumentShapeError.bothBorderModels
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        layers = try container.decode(LayerStack.self, forKey: .layers)
        background = try container.decode(BackgroundSpec.self, forKey: .background)
        signatureText = try container.decode(String.self, forKey: .signatureText)
        lensOverride = try container.decodeIfPresent(LensOverride.self, forKey: .lensOverride)
    }
}

private nonisolated struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        return nil
    }
}
