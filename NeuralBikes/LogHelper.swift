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
    static let numberOfTimesTappedSettingsButtonKey = "numberOfTimesTappedSettingsButton"

    static func logTAppedDataInsightsButton() {

        let numberOfTimesTappedDataInsightsButton: Int = defaults.integer(forKey: LogHelper.numberOfTimesTappedDataInsightsButtonKey) + 1

        print("> Data Insights button has been tapped \(numberOfTimesTappedDataInsightsButton) times")

        UserDefaults.standard.set(numberOfTimesTappedDataInsightsButton, forKey: LogHelper.numberOfTimesTappedDataInsightsButtonKey)
    }

    static func logTAppedSettingsButton() {

        let numberOfTimesTappedSettingsButton: Int = defaults.integer(forKey: LogHelper.numberOfTimesTappedSettingsButtonKey) + 1

        print("> Settings button has been tapped \(numberOfTimesTappedSettingsButtonKey) times")

        UserDefaults.standard.set(numberOfTimesTappedSettingsButton, forKey: LogHelper.numberOfTimesTappedSettingsButtonKey)
    }
}
