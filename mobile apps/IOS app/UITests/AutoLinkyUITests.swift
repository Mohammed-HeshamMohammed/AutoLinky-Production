import XCTest
final class AutoLinkyUITests: XCTestCase {
    @MainActor func testNativeSimulatorLaunchBaseline() {
        let app = XCUIApplication()
        app.launchArguments = ["-development.api", "https://api.example.com", "-language", "en"]
        let options = XCTMeasureOptions(); options.iterationCount = 3
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) { app.launch() }
    }
    @MainActor func testNativeSetupRejectsInsecureOriginAndSupportsArabic() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-development.api", "", "-language", "en"]
        app.launch()
        let field = app.textFields["apiAddress"]
        XCTAssertTrue(field.waitForExistence(timeout: 20))
        field.tap(); field.typeText("http://evil.example.com")
        app.buttons["setupContinue"].tap()
        XCTAssertTrue(app.staticTexts["Use a valid HTTPS API address."].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Native setup"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.terminate()
        app.launchArguments = ["-development.api", "", "-language", "ar"]
        app.launch()
        XCTAssertTrue(app.staticTexts["مرحباً بك في أوتولينكي"].waitForExistence(timeout: 10))
        let arabic = XCTAttachment(screenshot: app.screenshot()); arabic.name = "Native Arabic setup"; arabic.lifetime = .keepAlways; add(arabic)
    }
    @MainActor func testNativeProviderSetupShowsWelcomeWithoutFlutter() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-development.api", "https://api.example.com", "-language", "en"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Your next opportunity starts here."].waitForExistence(timeout: 20))
        XCTAssertTrue(app.links["Terms"].exists || app.buttons["Terms"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Native welcome"; screenshot.lifetime = .keepAlways; add(screenshot)
    }
    @MainActor func testAuthenticatedNativeNavigationWithIsolatedFixtureTransport() throws {
        let app = XCUIApplication()
        app.launchEnvironment["AUTOLINKY_UI_TEST"] = "1"
        app.launchArguments = ["-development.api", "https://native-fixture.invalid", "-language", "en"]
        app.launch()
        XCTAssertTrue(app.staticTexts["UI test opportunity"].waitForExistence(timeout: 20))
        let home = XCTAttachment(screenshot: app.screenshot()); home.name = "Native matches fixture"; home.lifetime = .keepAlways; add(home)
        app.staticTexts["UI test opportunity"].tap()
        XCTAssertTrue(app.staticTexts["About this opportunity"].waitForExistence(timeout: 10))
        let detail = XCTAttachment(screenshot: app.screenshot()); detail.name = "Native job detail fixture"; detail.lifetime = .keepAlways; add(detail)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.staticTexts["Your CV"].waitForExistence(timeout: 10))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Preferences"].waitForExistence(timeout: 10))
    }
}
