//
//  Constants.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit
import MapKit

struct Constants {
    
    static let appGroupsBundleID = "group.com.javierdemartin.bici"
    static let lengthOfTheDay = 144.0
    static let cornerRadius: CGFloat = 9.0
    static let spacing: CGFloat = 16.0
    static let narrowCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    static let wideCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    static let selectedStationsStatistics: String = "selectedStationsStatistics"
}
