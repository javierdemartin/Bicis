//
//  UITestingHelper.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 14/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

class UITestingHelper: NSObject {

    static let sharedInstance: UITestingHelper = {
        let instance = UITestingHelper()
        return instance
    }()

    /// - Returns: A `Bool` indicating if UI Testing suite is being tested
    func isUITesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("is_ui_testing")
    }

}
