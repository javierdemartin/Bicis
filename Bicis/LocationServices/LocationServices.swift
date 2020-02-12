//
//  LocationService.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 04/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

//
//  LocationService.swift
//
//
//  Created by Anak Mirasing on 5/18/2558 BE.
//
//

import Foundation
import CoreLocation

protocol LocationServicesDelegate {
    func tracingLocation(_ currentLocation: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
}

class LocationServices: NSObject, CLLocationManagerDelegate {
    static let sharedInstance: LocationServices = {
        let instance = LocationServices()
        return instance
    }()

    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    var delegate: LocationServicesDelegate?

    func isUITesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("is_ui_testing")
    }

    override init() {
        super.init()

        if !isUITesting() {

            self.locationManager = CLLocationManager()
            guard let locationManager = self.locationManager else {
                return
            }

            if CLLocationManager.authorizationStatus() == .notDetermined {
                // you have 2 choice
                // 1. requestAlwaysAuthorization
                // 2. requestWhenInUseAuthorization
                locationManager.requestWhenInUseAuthorization()
            }

            locationManager.desiredAccuracy = kCLLocationAccuracyBest // The accuracy of the location data
            locationManager.distanceFilter = 200 // The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
            locationManager.delegate = self

        }
    }

    func startUpdatingLocation() {
        print("Starting Location Updates")

        if !isUITesting() {
            self.locationManager?.startUpdatingLocation()
        }
    }

    func stopUpdatingLocation() {
        print("Stop Location Updates")

        if !isUITesting() {

            self.locationManager?.stopUpdatingLocation()

        }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if !isUITesting() {

            guard let location = locations.last else {
                return
            }

            // singleton for get last(current) location
            currentLocation = location

            // use for real time update location
            updateLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

        if !isUITesting() {

            // do on error
            updateLocationDidFailWithError(error as NSError)

        }
    }

    // Private function
    fileprivate func updateLocation(_ currentLocation: CLLocation) {

        if !isUITesting() {

            guard let delegate = self.delegate else {
                return
            }

            delegate.tracingLocation(currentLocation)
        }
    }

    fileprivate func updateLocationDidFailWithError(_ error: NSError) {

        if !isUITesting() {

            guard let delegate = self.delegate else {
                return
            }

            delegate.tracingLocationDidFailWithError(error)
        }
    }
}
