//
//  BicisUITests.swift
//  BicisUITests
//
//  Created by Javier de Martín Gil on 08/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import XCTest

class BicisUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments.append("is_ui_testing")

//        app.launchArguments.append("-AppleInterfaceStyle Dark")
        // UI tests must launch the application that they test.

        setupSnapshot(app)
        app.launch()

        // Wait for the map to load
        sleep(3)

        snapshot("00-Home")

        // Wait for the API information to be delivered
        let label = app.buttons["START_ROUTE"]
        let exists = NSPredicate(format: "exists == 1")

        expectation(for: exists, evaluatedWith: label, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        label.tap()

//        sleep(5)

        let textPredicate = NSPredicate(format: "label != %@", "...")
        expectation(for: textPredicate, evaluatedWith: app.staticTexts["DESTINATION_BIKES"], handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        snapshot("01-RoutePlanner")

        // MARK: RoutePlanner
//        print("START_ROUTE".localize(file: "Home"))
//
//        let routePlannerButton = app.buttons["START_ROUTE"]
//        routePlannerButton.tap()
//
//        sleep(9)
//
//        snapshot("01-RoutePlanner")

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        app.swipeDown()

        sleep(1)

        print("Presenting ")

        snapshot("02-Overall")
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
