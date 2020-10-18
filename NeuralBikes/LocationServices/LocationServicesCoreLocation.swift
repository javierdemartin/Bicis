//
//  LocationServicesCoreLocation.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 10/06/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

class LocationServiceCoreLocation: NSObject, CLLocationManagerDelegate, LocationServiceable {
    
    var locationPublisher = PassthroughSubject<CLLocation, Never>()

    var didUpdateLocationsHandler: ((CLLocation) -> Void)?
    var currentLocation: CLLocation?
    var locationAuthorizationStatus: PassthroughSubject<PermissionStatus, Never>
    
    static let sharedInstance: LocationServiceable = {
        let instance = LocationServiceCoreLocation()
        return instance
    }()
    
    var locationManager: CLLocationManager?
    
    override init() {
        
        locationAuthorizationStatus = PassthroughSubject<PermissionStatus, Never>()
        
        super.init()
        
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.pausesLocationUpdatesAutomatically = false
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager?.distanceFilter = kCLLocationAccuracyHundredMeters
        
        if UITestingHelper().isUITesting() {
            currentLocation = CLLocation(latitude: availableCities["Madrid"]!.latitude, longitude: availableCities["Madrid"]!.longitude)
        }
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
    
    /**
     Request CoreLocation permissions. If doing UI Tests don't even request permissions.
     */
    func requestPermissions() {
    
        if UITestingHelper().isUITesting() { return }
        
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationAuthorizationStatus.send(.granted)
            startMonitoring()
        default:
            locationAuthorizationStatus.send(.notDetermined)
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let uiTestCity = UITestingHelper.sharedInstance.isForceFeedingCity() {
            
            let uiTestLocation = CLLocation(latitude: CLLocationDegrees(uiTestCity.latitude), longitude: CLLocationDegrees(uiTestCity.longitude))
            
            currentLocation = uiTestLocation
            
            locationPublisher.send(self.currentLocation!)
            
            didUpdateLocationsHandler?(self.currentLocation!)
            
        } else {

            guard let latestLocation = locations.last else {
                return
            }
            
            currentLocation = latestLocation
            
            locationPublisher.send(self.currentLocation!)
            
            didUpdateLocationsHandler?(self.currentLocation!)
        }
    }
    
    func startMonitoring() {
        locationManager?.startUpdatingLocation()
    }
}
