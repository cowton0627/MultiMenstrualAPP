import XCTest

final class MultiMenstrualAPPUITests: XCTestCase {
    func testLaunchShowsProfilesScreen() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["經期管理"].waitForExistence(timeout: 5),
            "The profiles screen should be visible after launch"
        )
    }
}
