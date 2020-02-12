//
//  MapPin.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import MapKit

class MapPin: NSObject, MKAnnotation {

    var title: String?
    var coordinate: CLLocationCoordinate2D
    let stationInformation: BikeStation

    init(title: String, coordinate: CLLocationCoordinate2D, stationInformation: BikeStation) {

        self.title = title
        self.coordinate = coordinate
        self.stationInformation = stationInformation
    }
}
