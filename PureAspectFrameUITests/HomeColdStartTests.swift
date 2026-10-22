import XCTest

final class HomeColdStartTests: XCTestCase {
    func testHomeSettingsButtonExists() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home_settings_button"].waitForExistence(timeout: 10))
    }
}
