import XCTest

/// Walks through every screen and saves screenshots for design review.
/// CI sets TEST_RUNNER_SCREENSHOT_DIR so the PNGs land on the host.
final class ScreenshotTests: XCTestCase {
    private let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]

    override func setUp() {
        continueAfterFailure = true
    }

    func testDaytimeFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests"]
        app.launch()
        pause(1.5)
        snap("01-today")

        tap(app.buttons["tab.inbox"])
        snap("02-inbox")

        tap(app.buttons["new-block"])
        pause(1)
        snap("03-new-block")
        tap(app.buttons["取消"])

        tap(app.buttons["tab.focus"])
        snap("04-focus-empty")

        tap(app.buttons["focus.start"])
        pause(2)
        snap("05-focus-running")

        tap(app.buttons["tab.today"].exists ? app.buttons["tab.today"] : app.buttons["返回今天"])
        if !app.buttons["tab.today"].exists { tap(app.buttons["返回今天"]) }
        pause(1)
        snap("06-today-focusing")

        XCUIDevice.shared.press(.home)
        pause(2)
        snap("07-island-compact")

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).press(forDuration: 1.2)
        pause(1.5)
        snap("08-island-expanded")

        let lock = NSSelectorFromString("pressLockButton")
        if XCUIDevice.shared.responds(to: lock) {
            XCUIDevice.shared.perform(lock)
            pause(1.5)
            XCUIDevice.shared.perform(lock)
            pause(2)
            snap("09-lock-screen")
        }
    }

    func testEveningReview() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "-EveningDemo"]
        app.launch()
        pause(1)
        tap(app.buttons["tab.review"])
        pause(1)
        snap("10-review")
        app.swipeUp()
        pause(1)
        snap("11-review-bottom")
    }

    private func tap(_ element: XCUIElement) {
        if element.waitForExistence(timeout: 5) { element.tap() } else {
            XCTFail("Missing element: \(element)")
        }
    }

    private func pause(_ seconds: TimeInterval) {
        RunLoop.current.run(until: Date().addingTimeInterval(seconds))
    }

    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let directory {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: directory).appendingPathComponent("\(name).png"))
        }
    }
}
