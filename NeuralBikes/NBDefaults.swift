//
//  NBDefaults.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 11/10/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

struct NBDefaults {
    static var longAppVersion: String? {
        get {
            guard let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return nil }

            guard let bundleString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else { return nil }
            
            return versionString + " (\(bundleString))"
        }
    }
}
