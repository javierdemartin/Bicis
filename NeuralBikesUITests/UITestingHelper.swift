//
//  UITestingHelper.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 14/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation

class UITestingHelper: NSObject {

    static let sharedInstance: UITestingHelper = {
        let instance = UITestingHelper()
        return instance
    }()

    /// - Returns: A `Bool` indicating if UI Testing suite is being tested
    func isUITesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("is_ui_testing")
    }
    
    func isForceFeedingCity() -> City? {
        if ProcessInfo.processInfo.arguments.contains("ui_testing_manual_city") {
            
            var selectedCity: City?
            
            switch Locale.current.identifier {
            case "en-US":
                selectedCity = availableCities["New York"]
            case "en-GB":
                selectedCity = availableCities["London"]
            case "es-ES":
                selectedCity = availableCities["Bilbao"]
            case "fr-FR":
                selectedCity = availableCities["Paris"]
            default:
                selectedCity = availableCities["Paris"]
            }
            
            return selectedCity
        }
        
        return nil
    }
    
    func getSimulatedLocationForTestingCity() -> CLLocation?  {
        if let forcedCity = isForceFeedingCity() {
            return CLLocation(latitude: forcedCity.latitude, longitude: forcedCity.longitude)
        }
        
        return nil
    }
}
