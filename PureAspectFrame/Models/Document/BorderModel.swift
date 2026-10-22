import Foundation

public nonisolated struct Percent: Codable, Equatable, Sendable {
    public let value: Double

    public init(_ raw: Double) {
        value = min(50, max(0, raw))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(Double.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

public nonisolated struct EdgeValues<Value: Codable & Equatable & Sendable>: Codable, Equatable, Sendable {
    public var top: Value
    public var bottom: Value
    public var left: Value
    public var right: Value

    public init(top: Value, bottom: Value, left: Value, right: Value) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}

public nonisolated enum CanvasAspect: Equatable, Hashable, Sendable {
    case r1x1
    case r4x5
    case r3x2
    case r9x16
    case r3x4
    case polaroidMini
    case polaroidSquare
    case polaroidWide
}

extension CanvasAspect: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "1:1":
            self = .r1x1
        case "4:5", "4:5 (IG)":
            self = .r4x5
        case "3:2":
            self = .r3x2
        case "9:16", "16:9", "9:16 (Story)":
            self = .r9x16
        case "3:4":
            self = .r3x4
        case "Mini (54×86)", "polaroid-mini":
            self = .polaroidMini
        case "Square (72×86)", "polaroid-square":
            self = .polaroidSquare
        case "Wide (108×86)", "polaroid-wide":
            self = .polaroidWide
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "未知的畫布比例 \(raw)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .r1x1: try container.encode("1:1")
        case .r4x5: try container.encode("4:5")
        case .r3x2: try container.encode("3:2")
        case .r9x16: try container.encode("9:16")
        case .r3x4: try container.encode("3:4")
        case .polaroidMini: try container.encode("polaroid-mini")
        case .polaroidSquare: try container.encode("polaroid-square")
        case .polaroidWide: try container.encode("polaroid-wide")
        }
    }
}

public nonisolated enum RatioRole: Codable, Equatable, Sendable {
    case drives
    case live(BorderRing.ID)
    case detached
}

public nonisolated struct RatioSizing: Codable, Equatable, Sendable {
    public var aspect: CanvasAspect
    public var minimum: EdgeValues<Percent>
    public var role: RatioRole

    public init(aspect: CanvasAspect, minimum: EdgeValues<Percent>, role: RatioRole) {
        self.aspect = aspect
        self.minimum = minimum
        self.role = role
    }
}

public nonisolated enum BorderSizing: Codable, Equatable, Sendable {
    case equal(Percent)
    case perSide(EdgeValues<Percent>)
    case ratio(RatioSizing)

    /// 等距取上邊。逐邊 (上 7、下 9、左 3、右 4) 因此得到 7。
    public func convertedToEqual() -> Percent {
        convertedToPerSide().top
    }

    public func convertedToPerSide() -> EdgeValues<Percent> {
        switch self {
        case .equal(let percent):
            return EdgeValues(top: percent, bottom: percent, left: percent, right: percent)
        case .perSide(let edges):
            return edges
        case .ratio(let sizing):
            return sizing.minimum
        }
    }

    public var ratioSizing: RatioSizing? {
        if case .ratio(let sizing) = self { return sizing }
        return nil
    }

    public var isDriving: Bool {
        ratioSizing?.role == .drives
    }

    func reach() -> Double {
        let edges = convertedToPerSide()
        return max(edges.top.value, edges.bottom.value, edges.left.value, edges.right.value)
    }
}

public nonisolated struct BorderRing: Codable, Equatable, Sendable, Identifiable {
    public nonisolated struct ID: Hashable, Codable, Sendable {
        public var rawValue: UUID

        public init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }

    public var id: ID
    public var color: RGBColor
    public var opacity: Double
    public var sizing: BorderSizing

    public init(id: ID = ID(), color: RGBColor, opacity: Double = 1, sizing: BorderSizing) {
        self.id = id
        self.color = color
        self.opacity = min(1, max(0, opacity))
        self.sizing = sizing
    }
}
