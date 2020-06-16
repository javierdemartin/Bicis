//
//  LocationServicesCoreLocation.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 10/06/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift

class LocationServiceCoreLocation: NSObject, CLLocationManagerDelegate, LocationServiceable {
    var signalForDidUpdateLocations: Signal<CLLocation, Never> {
        return Signal<CLLocation, Never> { [weak self] (observer, _) in
            self?.didUpdateLocationsHandler = { location in
                observer.send(value: location)
            }
        }
    }
    var didUpdateLocationsHandler: ((CLLocation) -> Void)?
    var currentLocation: CLLocation?
    
    static let sharedInstance: LocationServiceable = {
        let instance = LocationServiceCoreLocation()
        return instance
    }()
    
    var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.pausesLocationUpdatesAutomatically = false
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.distanceFilter = kCLLocationAccuracyHundredMeters
    }
        
    func getPermissionStatus() -> PermissionStatus {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            return .granted
        case .denied, .restricted:
            return .denied
        default:
            return .notDetermined
        }
    }
    
    func requestPermissions() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startMonitoring()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let latestLocation = locations.last else {
            return
        }
        
        currentLocation = latestLocation
        
        didUpdateLocationsHandler?(latestLocation)
    }
    
    func startMonitoring() {
        locationManager?.startUpdatingLocation()
    }
}

