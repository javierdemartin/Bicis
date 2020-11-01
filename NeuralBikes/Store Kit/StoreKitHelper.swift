//
//  StoreKitHelper.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 09/02/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import StoreKit

struct StoreKitHelper {

    static let numberOfTimesLaunchedKey = "numberOfTimesLaunched"

    static func displayStoreKit() {

        /// Don't prompt StoreKit review if doing UITests
        if ProcessInfo.processInfo.arguments.contains("is_ui_testing") { return }

        guard let currentVersion = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String else {
            return
        }

        let lastVersionPromptedForReview = UserDefaults.standard.string(forKey: "lastVersion")

        let numberOfTimesLaunched: Int = UserDefaults.standard.integer(forKey: StoreKitHelper.numberOfTimesLaunchedKey)

        if numberOfTimesLaunched > 15 && currentVersion != lastVersionPromptedForReview {
            SKStoreReviewController.requestReview()
            UserDefaults.standard.set(currentVersion, forKey: "lastVersion")
        }
    }
    
    static func getNumberOfTimesLaunched() -> Int? {
        
        let timesLaunched = UserDefaults.standard.integer(forKey: StoreKitHelper.numberOfTimesLaunchedKey)
        
        return timesLaunched
    }

    static func incrementNumberOfTimesLaunched() {

        let numberOfTimesLaunched: Int = UserDefaults.standard.integer(forKey: StoreKitHelper.numberOfTimesLaunchedKey) + 1

        print("App has been launched \(numberOfTimesLaunched) times")

        UserDefaults.standard.set(numberOfTimesLaunched, forKey: StoreKitHelper.numberOfTimesLaunchedKey)

        displayStoreKit()
    }
}
