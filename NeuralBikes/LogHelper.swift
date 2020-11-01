//
//  LogHelper.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 23/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

struct LogHelper {

    static let defaults = UserDefaults(suiteName: Constants.appGroupsBundleID)!

    static let numberOfTimesTappedDataInsightsButtonKey = "numberOfTimesTappedDataInsightsButton"

    static func logTAppedDataInsightsButton() {

        let numberOfTimesTappedDataInsightsButton: Int = defaults.integer(forKey: LogHelper.numberOfTimesTappedDataInsightsButtonKey) + 1

        print("> Data Insights button has been tapped \(numberOfTimesTappedDataInsightsButton) times")

        UserDefaults.standard.set(numberOfTimesTappedDataInsightsButton, forKey: LogHelper.numberOfTimesTappedDataInsightsButtonKey)
    }
}
