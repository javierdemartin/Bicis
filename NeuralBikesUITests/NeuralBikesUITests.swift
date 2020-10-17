//
//  BicisUITests.swift
//  BicisUITests
//
//  Created by Javier de Martín Gil on 08/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import XCTest
import Foundation

class BicisUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments.append("is_ui_testing")
        app.launchArguments.append("ui_testing_manual_city")
        

        setupSnapshot(app)
        app.launch()
        

        sleep(10) // Wait for the map to load

        snapshot("00-Home")

        // Wait for the API information to be delivered
        let label = app.buttons["START_ROUTE"]
        let exists = NSPredicate(format: "exists == 1")

        expectation(for: exists, evaluatedWith: label, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        label.tap()

        let textPredicate = NSPredicate(format: "label != %@", "...")
        expectation(for: textPredicate, evaluatedWith: app.staticTexts["DESTINATION_BIKES"], handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        snapshot("01-RoutePlanner")

//        let pullDownTab = app.otherElements["PULL_DOWN_TAB"]
//
//        let start = pullDownTab.coordinate(withNormalizedOffset: CGVector(dx: 10, dy: 20))
//        let finish = pullDownTab.coordinate(withNormalizedOffset: CGVector(dx: 10, dy: 200))
//        start.press(forDuration: 0.01, thenDragTo: finish)

//        pullDownTab.swipeDown()

        // MARK: RoutePlanner
    }

//    func testLaunchPerformance() {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
//                XCUIApplication().launch()
//            }
//        }
//    }
}
