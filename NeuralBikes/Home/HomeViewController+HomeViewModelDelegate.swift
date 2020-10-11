//
//  HomeViewController+HomeViewModelDelegate.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 03/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

// MARK: HomeViewModelDelegate
extension HomeViewController: HomeViewModelDelegate {
    
    func selectClosestAnnotationGraph(stations: [BikeStation], currentLocation: CLLocation) {

        let nearestPin: BikeStation? = stations.reduce((CLLocationDistanceMax, nil)) { (nearest, pin) in
            let coord = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = currentLocation.distance(from: loc)
            return distance < nearest.0 ? (distance, pin) : nearest
        }.1

        guard let nearest = nearestPin else { return }

        guard let nearestStation = self.viewModel.stationsDict.value[nearest.stationName] else { return }
//        guard let nearestStation = self.viewModel.stationsDict.value[nearest.stationName] else { return }

        // Find the index of the current station
//
//        if let index = viewModel.stations.value.firstIndex(where: { $0.stationName == nearestStation.stationName }) {
        if let index = viewModel.stations.firstIndex(where: { $0.stationName == nearestStation.stationName }) {
            self.viewModel.currentSelectedStationIndex = index
        }

        self.centerMap(on: CLLocationCoordinate2D(latitude: CLLocationDegrees(nearestStation.latitude),
                                                  longitude: CLLocationDegrees(nearestStation.longitude)), coordinateSpan: Constants.narrowCoordinateSpan)

        if self.mapView.annotations.contains(where: {$0.title == nearestStation.stationName}) {

            if let foo = self.mapView.annotations.first(where: {$0.title == nearestStation.stationName}) {
                self.mapView.selectAnnotation(foo, animated: true)
            }
        }
    }
    
    func showActiveRentedBike(number: String) {
        activeRentalBike.setTitle(number, for: .normal)
        activeRentalBike.accessibilityIdentifier = number
        activeRentalBike.isHidden = false
        activeRentalScrollView.isHidden = false
    }
    
    func centerMap(on point: CLLocationCoordinate2D, coordinateSpan: MKCoordinateSpan) {

        let region = MKCoordinateRegion(center: point, span: coordinateSpan)

        self.mapView.setRegion(region, animated: false)
    }
    
    func shouldShowRentBikeButton() {
        rentButton.isHidden = false
    }
    
    func shouldHideRentBikeButton() {
        rentButton.isHidden = true
    }

    func presentAlertViewWithError(title: String, body: String) {

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }

    /// Called when a new city is selected, removing the pins from the previous city
    func removePinsFromMap() {
        mapView.removeAnnotations(mapView.annotations)
    }

    func dismissGraphView() {
        self.hideStackView()
    }

    func drawPrediction(data: [Int], prediction: Bool) {
        graphView.drawLine(values: data, isPrediction: prediction)
    }

    func receivedError(with errorString: String) {
        let alert = UIAlertController(title: NSLocalizedString("ALERT_HEADER", comment: ""), message: errorString, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("CONFIRM_ALERT", comment: ""), style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
