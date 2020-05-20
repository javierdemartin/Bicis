//
//  LocalDataManagerError.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

enum LocalDataManagerError: Error {
    // submitCode errors
    case noLogInSaved
    case noCitySaved
    case errorDecodingDefaults
    case errorReadingFromDefaults
    case errorSavingToDefaults
    case hasntPaid
}

extension LocalDataManagerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noLogInSaved:
            return "NO_LOGIN_SAVED".localize(file: "DataManager")
        case .noCitySaved:
            return "NO_LOGIN_SAVED".localize(file: "DataManager")
        case .errorDecodingDefaults:
            return "ERROR_DECODING_DEFAULTS".localize(file: "DataManager")
        case .errorReadingFromDefaults:
            return "ERROR_READING_DEFAULTS".localize(file: "DataManager")
        case .errorSavingToDefaults:
            return "ERROR_SAVING_TO_DEFAULTS".localize(file: "DataManager")
        case .hasntPaid:
            return "HASNT_PAID".localize(file: "DataManager")
        }
    }
}
