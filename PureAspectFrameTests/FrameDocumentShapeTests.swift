import Foundation
import Testing
@testable import PureAspectFrame

struct FrameDocumentShapeTests {
    @Test func storedPropertiesAndJSONKeysAreTheFourDocumentFields() throws {
        let document = FrameDocument(
            signatureText: "簽名",
            lensOverride: LensOverride(lensName: "Noctilux", focalLengthMillimeters: 50)
        )
        let labels = Set(Mirror(reflecting: document).children.compactMap(\.label))
        #expect(labels == ["layers", "background", "signatureText", "lensOverride"])
        #expect(FrameDocument.schemaVersion == 3)

        let data = try JSONEncoder().encode(document)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["layers", "background", "signatureText", "lensOverride"])

        let empty = try JSONEncoder().encode(FrameDocument())
        let emptyObject = try #require(JSONSerialization.jsonObject(with: empty) as? [String: Any])
        #expect(Set(emptyObject.keys) == ["layers", "background", "signatureText", "lensOverride"])
        #expect(emptyObject["lensOverride"] is NSNull)
    }

    @Test func layersTogetherWithALegacyBorderKeyThrowsBothBorderModels() throws {
        let legacyKeys = ["padding", "footer", "canvas", "split", "borderSettings"]
        for key in legacyKeys {
            let json = #"{"layers":{},"\#(key)":{}}"#
            #expect(throws: DocumentShapeError.bothBorderModels) {
                try JSONDecoder().decode(FrameDocument.self, from: Data(json.utf8))
            }
        }
    }

    @Test func legacyBorderJSONWithoutLayersIsNotBothBorderModels() {
        let json = #"{"padding":{}}"#
        do {
            _ = try JSONDecoder().decode(FrameDocument.self, from: Data(json.utf8))
            Issue.record("只有舊鍵的 JSON 不該解成新文件")
        } catch DocumentShapeError.bothBorderModels {
            Issue.record("只有舊鍵時不該丟 bothBorderModels")
        } catch {
            #expect(error is DecodingError)
        }
    }

    @Test func photoLayerCodingKeysOmitCropAndCanvas() throws {
        #expect(PhotoLayer.CodingKeys(stringValue: "crop") == nil)
        #expect(PhotoLayer.CodingKeys(stringValue: "canvas") == nil)
        let names = [PhotoLayer.CodingKeys.imageRatio.stringValue, PhotoLayer.CodingKeys.cornerRadius.stringValue]
        #expect(names == ["imageRatio", "cornerRadius"])

        let data = try JSONEncoder().encode(FrameDocument())
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("\"crop\""))
        #expect(!text.contains("\"canvas\""))
    }

    @Test func applyingATemplateKeepsCrops() {
        let photoID = UUID()
        var snapshot = EditSnapshot(
            document: FrameDocument(),
            crops: [photoID: CropTransform(scale: 2, offsetX: 0.2, offsetY: -0.1)]
        )
        let cropsBefore = snapshot.crops
        snapshot.apply(template: FrameDocument(signatureText: "模板"))
        #expect(snapshot.crops == cropsBefore)
        #expect(snapshot.document.signatureText == "模板")
    }

    @Test func infoBarKeepsThreeRegionsAndClampsTheTypeSize() throws {
        let regions = (0..<5).map { index in
            InfoRegion(alignment: .center, bricks: [.fixedText("\(index)"), .signature, .watermark])
        }
        let bar = InfoBar(spacing: Percent(2), regions: regions, fontScale: 4)
        #expect(bar.regions.count == 3)
        #expect(bar.fontScale == 1)
        let decoded = try JSONDecoder().decode(InfoBar.self, from: JSONEncoder().encode(bar))
        #expect(decoded == bar)
        let missingScale = Data(#"{"spacing":1,"regions":[]}"#.utf8)
        let fallback = try JSONDecoder().decode(InfoBar.self, from: missingScale)
        #expect(fallback.fontScale == 0.03)
        #expect(fallback.regions.isEmpty)
    }

    @Test func imageRatioAspects() {
        #expect(ImageRatio.allCases.count == 6)
        #expect(ImageRatio.original.widthOverHeight(photoAspect: 1.5) == 1.5)
        #expect(ImageRatio.original.widthOverHeight(photoAspect: 2.0 / 3.0) == 2.0 / 3.0)
        #expect(ImageRatio.r1x1.widthOverHeight(photoAspect: 1.5) == 1)
        #expect(ImageRatio.r4x5.widthOverHeight(photoAspect: 1.5) == 4.0 / 5.0)
        #expect(ImageRatio.r3x2.widthOverHeight(photoAspect: 1.5) == 3.0 / 2.0)
        #expect(ImageRatio.r16x9.widthOverHeight(photoAspect: 1.5) == 16.0 / 9.0)
        #expect(ImageRatio.r9x16.widthOverHeight(photoAspect: 1.5) == 9.0 / 16.0)
    }

    @Test func legacyCanvasNamesDecodeToOneNineBySixteen() throws {
        let story = try JSONDecoder().decode(CanvasAspect.self, from: Data(#""9:16 (Story)""#.utf8))
        let wide = try JSONDecoder().decode(CanvasAspect.self, from: Data(#""16:9""#.utf8))
        #expect(story == .r9x16)
        #expect(wide == .r9x16)
    }
}
