//
//  LocationServiceable.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 10/06/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import CoreLocation
import ReactiveSwift
import Combine

protocol LocationServiceable: class {
    var signalForDidUpdateLocations: Signal<CLLocation, Never> { get }
    var currentLocation: CLLocation? { get set }
    var locationAuthorizationStatus: PassthroughSubject<PermissionStatus, Never> { get set }
    func getPermissionStatus() -> PermissionStatus
    func requestPermissions()
    func startMonitoring()
}
