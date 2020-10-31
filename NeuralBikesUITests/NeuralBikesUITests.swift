//
//  BicisUITests.swift
//  BicisUITests
//
//  Created by Javier de Martín Gil on 08/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import XCTest
import Foundation

class NeuralBikesUITests: XCTestCase {

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
        /// Mocking the city that's being shown depending on the user's locale
        app.launchArguments.append("ui_testing_manual_city")
        
        setupSnapshot(app)
        app.launch()
        
        let exists = NSPredicate(format: "exists == 1")
        let label = app.buttons["START_ROUTE"]
        
        expectation(for: exists, evaluatedWith: label, handler: {
            
            print("FINISHED")
            return true
        })
        
        waitForExpectations(timeout: 30, handler: { comp in
            
            print("loaded pins")
        })
        
        
        snapshot("00-Home")

        label.tap()

//        let textPredicate = NSPredicate(format: "label != %@", "...")
//        expectation(for: textPredicate, evaluatedWith: app.staticTexts["DESTINATION_BIKES"], handler: nil)
//        waitForExpectations(timeout: 2, handler: nil)

        snapshot("01-RoutePlanner")
        
        app.terminate()
    }
}
