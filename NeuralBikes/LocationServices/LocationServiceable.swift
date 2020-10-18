//
//  LocationServiceable.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 10/06/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}


protocol LocationServiceable: class {
    var locationPublisher: PassthroughSubject<CLLocation, Never> { get set }
    var currentLocation: CLLocation? { get set }
    var locationAuthorizationStatus: PassthroughSubject<PermissionStatus, Never> { get set }
    func getPermissionStatus() -> PermissionStatus
    func requestPermissions()
    func startMonitoring()
}
