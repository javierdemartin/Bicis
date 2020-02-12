//
//  SettingsErrors.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

enum SettingsError: Error {

    case incorrectCredentials
    case successfulLogIn
}

extension SettingsError: LocalizedError {
    public var errorDescription: String? {
        switch self {

        case .incorrectCredentials:
            return "INCORRECT_CREDENTIALS".localize(file: "Settings")
        case .successfulLogIn:
            return "SUCCESSFUL_LOG_IN".localize(file: "Settings")
        }
    }
}
