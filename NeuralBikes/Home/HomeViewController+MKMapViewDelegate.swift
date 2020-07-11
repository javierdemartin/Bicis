//
//  HomeViewController+MKMapViewDelegate.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 03/07/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import MapKit

// MARK: MKMapViewDelegate
extension HomeViewController: MKMapViewDelegate {

    // MARK: - MKMapViewDelegate
    private func customAnnotationView(in mapView: MKMapView, for annotation: MKAnnotation) -> CustomAnnotationView {

        let identifier = "CustomAnnotationViewID"

        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationView {
            annotationView.annotation = annotation
            return annotationView

        } else {
            let customAnnotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            customAnnotationView.canShowCallout = true
            return customAnnotationView
        }
    }

    /// Handle the user location, disabling the callout when it's tapped
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let userLocationView = mapView.view(for: userLocation)
        userLocationView?.canShowCallout = false
    }

    /// Prepare the `AnnotationView` & set up the clustering for the stations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Don't show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else { return nil }

        if let cluster = annotation as? MKClusterAnnotation {

            let markerAnnotationView = MKMarkerAnnotationView()
            markerAnnotationView.glyphText = String(cluster.memberAnnotations.count)
            markerAnnotationView.canShowCallout = false

            return markerAnnotationView
        }

        var annotationView: MKAnnotationView?

        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier) as? CustomAnnotationView {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }

        if let annotationView = annotationView {

            // Disable the callout showing the title, the title will be shown in the GraphView
            annotationView.canShowCallout = false

            guard let annotationTitle = annotation.title! else { return nil }
            guard let stationsDictFromViewModel = self.viewModel.stationsDict.value[annotationTitle] else { return nil }
            
            let markerAnnotationView: MKMarkerAnnotationView = {
                let marker = MKMarkerAnnotationView()
                marker.glyphText = "\(stationsDictFromViewModel.freeBikes)"
                return marker
            }()
            
            switch whatsShown {
            case .freeBikes:
                markerAnnotationView.glyphText = "\(stationsDictFromViewModel.freeBikes)"
            case .freeDocks:
                markerAnnotationView.glyphText = "\(stationsDictFromViewModel.freeRacks)"
            }

            self.viewModel.hasUnlockedFeatures(completion: { hasPaid in

                if hasPaid {
                    // Stablish the color coding of the availability
                    // TODO: NoSpotIndex
                    switch stationsDictFromViewModel.freeBikes {
                    case 10...:
                        markerAnnotationView.markerTintColor = UIColor.systemGreen
                    case 5...10:
                        markerAnnotationView.markerTintColor = UIColor.systemOrange
                    case ..<5:
                        markerAnnotationView.markerTintColor = UIColor.systemRed
                    default:
                        break
                    }
                }
            })

            return markerAnnotationView
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        return MKClusterAnnotation(memberAnnotations: memberAnnotations)
    }

    /// As the annotation is deselected hde the `GraphView` and disable the route planner button
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        hideStackView()
        insightsButton.isEnabled = false
    }

    /// Annotation was selected
    /// 1. Query the API for the prediction and availability data
    /// 2. Center the MapView
    /// 3. Set the `GraphView`'s title using the selected station name
    /// 4. Show the route planner view controller
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        // If for any reason the current city is not saved cancel the operation
        guard viewModel.currentCity != nil else { return }

        guard let annotationFromPin = view.annotation as? MapPin else { return }

        centerMap(on: annotationFromPin.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)

        viewModel.latestSelectedAnnotation = annotationFromPin
        viewModel.latestSelectedBikeStation = annotationFromPin.stationInformation

        var apiQueryStationValue: String?

        apiQueryStationValue = annotationFromPin.stationInformation.id
        
        graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)

        guard apiQueryStationValue != nil else { return }

        viewModel.getAllDataFromApi(city: viewModel.currentCity!.apiName, station: apiQueryStationValue!, completion: { res in

            // As soon as new data is retrieved from the API show the graph
            self.showStackView()

            switch res {

            case .success(let payload):

                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.availabilityArray = payload["today"]
                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.predictionArray = payload["prediction"]

                self.insightsButton.isEnabled = true
                self.showRoutePlannerButton()
                self.graphView.accessibilityLabel = NSLocalizedString("SELECTED_STATION_GRAPH_ACCESIBILITY_LABEL", comment: "").replacingOccurrences(of: "%name", with: annotationFromPin.stationInformation.stationName)

            case .error:
                break
            }
        })
    }
}
