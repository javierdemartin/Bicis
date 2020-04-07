//
//  LocationService.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 04/12/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServicesDelegate: class {
    func tracingLocation(_ currentLocation: CLLocation)
    func tracingLocationDidFailWithError(_ error: NSError)
}

/// Singleton object to request user's location
class LocationServices: NSObject, CLLocationManagerDelegate {
    static let sharedInstance: LocationServices = {
        let instance = LocationServices()
        return instance
    }()

    var locationManager: CLLocationManager?
    var currentLocation: CLLocation?
    weak var delegate: LocationServicesDelegate?

    override init() {
        super.init()

        if !(UITestingHelper.sharedInstance.isUITesting()) {

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

        if !(UITestingHelper.sharedInstance.isUITesting()) {
            self.locationManager?.startUpdatingLocation()
        }
    }

    func stopUpdatingLocation() {
        print("Stop Location Updates")

        if !(UITestingHelper.sharedInstance.isUITesting()) {

            self.locationManager?.stopUpdatingLocation()

        }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        if !(UITestingHelper.sharedInstance.isUITesting()) {

            guard let location = locations.last else {
                return
            }

            // singleton for get last(current) location
            currentLocation = location

            // use for real time update location
            updateLocation(location)
        }
    }

    /// Mock the user location if UI Tests are being done
    func getLatestLocationCoordinates() -> CLLocationCoordinate2D? {

        switch UITestingHelper.sharedInstance.isUITesting() {
        case true:
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(availableCities["New York"]!.latitude), longitude: CLLocationDegrees(availableCities["New York"]!.longitude))
        case false:

            #if targetEnvironment(simulator)
                return CLLocationCoordinate2D(latitude: CLLocationDegrees(availableCities["New York"]!.latitude), longitude: CLLocationDegrees(availableCities["New York"]!.longitude))
            #endif

            return locationManager?.location?.coordinate
        }
    }

    /// 
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

        // Don't display the error if UI Tests are being run
        if !(UITestingHelper.sharedInstance.isUITesting()) {
            updateLocationDidFailWithError(error as NSError)
        }
    }

    // Private function
    fileprivate func updateLocation(_ currentLocation: CLLocation) {

        if !(UITestingHelper.sharedInstance.isUITesting()) {

            guard let delegate = self.delegate else {
                return
            }

            delegate.tracingLocation(currentLocation)
        }
    }

    fileprivate func updateLocationDidFailWithError(_ error: NSError) {

        if !(UITestingHelper.sharedInstance.isUITesting()) {

            guard let delegate = self.delegate else {
                return
            }

            delegate.tracingLocationDidFailWithError(error)
        }
    }
}
