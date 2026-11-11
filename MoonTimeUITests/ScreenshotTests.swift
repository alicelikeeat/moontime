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

        // The focus screen hides the tab bar; leave through its back button.
        tap(app.buttons["返回今天"])
        pause(1)
        snap("06-today-focusing")

        // Lock screen: iOS asks once whether to allow Live Activities; allow it.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let lock = NSSelectorFromString("pressLockButton")
        if XCUIDevice.shared.responds(to: lock) {
            XCUIDevice.shared.perform(lock)
            pause(1.5)
            XCUIDevice.shared.perform(lock)
            pause(2)
            let allow = springboard.buttons["Allow"]
            if allow.waitForExistence(timeout: 3) {
                snap("07-lock-permission")
                allow.tap()
                pause(1.5)
            }
            snap("08-lock-screen")
            // Unlock (the simulator has no passcode).
            XCUIDevice.shared.press(.home)
            pause(1)
            XCUIDevice.shared.press(.home)
            pause(2)
        } else {
            XCUIDevice.shared.press(.home)
            pause(2)
        }

        // Home screen: compact Dynamic Island.
        if springboard.state != .runningForeground { XCUIDevice.shared.press(.home); pause(2) }
        snap("09-island-compact")

        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03)).press(forDuration: 1.2)
        pause(1.5)
        snap("10-island-expanded")
    }

    func testEveningReview() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITests", "-EveningDemo"]
        app.launch()
        pause(1)
        tap(app.buttons["tab.review"])
        pause(1)
        snap("11-review")
        app.swipeUp()
        pause(1)
        snap("12-review-bottom")
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
