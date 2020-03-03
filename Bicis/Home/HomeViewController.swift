//
//  HomeViewController.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import MapKit

protocol HomeViewControllerGraphViewDelegate: class {
    func setStationTitleFor(name: String)
}

class HomeViewController: UIViewController {

    let generator = UIImpactFeedbackGenerator(style: .light)

    var annotations: [MKAnnotation]?
    var latestSelectedAnnotation: MKAnnotation?
    weak var graphViewDelegate: HomeViewControllerGraphViewDelegate?

    let compositeDisposable: CompositeDisposable

    var currentCity: City?

    let viewModel: HomeViewModel

    var mapView: MKMapView = {

        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true

        return map
    }()

    var graphView: PredictionGraphView = {
        let view = PredictionGraphView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        // handling code
        viewModel.coordinatorDelegate?.showSettingsViewController()
    }

    var label: UILabel = {

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.text = ""
        return label
    }()

    init(viewModel: HomeViewModel, compositeDisposable: CompositeDisposable) {

        self.viewModel = viewModel
        self.compositeDisposable = compositeDisposable

        super.init(nibName: nil, bundle: nil)

        if let cityFromModel = viewModel.city {

            let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(cityFromModel.latitude), longitude: CLLocationDegrees(cityFromModel.longitude))

            self.centerMap(on: centerCoordinates)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }

    override func loadView() {
        view = UIView()

        let safeArea = view.safeAreaLayoutGuide

        view.addSubview(mapView)

        view.addSubview(graphView)
        view.bringSubviewToFront(graphView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        graphView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            graphView.heightAnchor.constraint(equalToConstant: 110)
        ])

        if UIDevice.current.userInterfaceIdiom == .pad {

            NSLayoutConstraint.activate([
                graphView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 32),
                graphView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -32)

            ])

        } else if UIDevice.current.userInterfaceIdiom == .phone {

            NSLayoutConstraint.activate([
                graphView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16.0),
                graphView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16.0)
            ])
        }

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        graphView.hideView()
        graphView.isHidden = true
    }

    func selectClosestAnnotationGraph(stations: [BikeStation], currentLocation: CLLocation) {

        let nearestPin: BikeStation? = stations.reduce((CLLocationDistanceMax, nil)) { (nearest, pin) in
            let coord = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude), longitude: CLLocationDegrees(pin.longitude))
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let distance = currentLocation.distance(from: loc)
            return distance < nearest.0 ? (distance, pin) : nearest
        }.1

        guard let nearest = nearestPin else { return }

        guard let nearestStation = self.viewModel.stationsDict.value[nearest.stationName] else { return }

        self.centerMap(on: CLLocationCoordinate2D(latitude: CLLocationDegrees(nearestStation.latitude),
                                                  longitude: CLLocationDegrees(nearestStation.longitude)))

        if self.mapView.annotations.contains(where: {$0.title == nearestStation.stationName}) {

            if let foo = self.mapView.annotations.first(where: {$0.title == nearestStation.stationName}) {
                self.mapView.selectAnnotation(foo, animated: true)
            }
        }
    }

    @objc func appMovedToForeground() {
        print("App moved to ForeGround!")

        if let currentUserLcoation = LocationServices.sharedInstance.currentLocation {
            centerMap(on: CLLocationCoordinate2D(latitude: currentUserLcoation.coordinate.latitude, longitude: currentUserLcoation.coordinate.longitude))
        }

        viewModel.getCurrentCity(completion: { currentCityResult in
            switch currentCityResult {

            case .success(let currentCity):
                self.currentCity = currentCity

                guard let unwrappedCity = self.currentCity else { return }

                self.viewModel.getMapPinsFrom(city: unwrappedCity)

            case .error(let err):
                // TODO: Mostrar error
                print(err.localizedDescription)
            }
        })
    }

    @objc func appMovedToBackground() {
        print("App moved to Background!")

        guard let didSelectAnnotation = latestSelectedAnnotation else { return }

        mapView.deselectAnnotation(didSelectAnnotation, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        mapView.delegate = self
        graphViewDelegate = graphView

        setupBindings()
    }

    func isUITesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("is_ui_testing")
    }

    override func viewDidLayoutSubviews() {

        super.viewDidLayoutSubviews()

        mapView.frame = self.view.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        compositeDisposable.dispose()
    }

    fileprivate func setupBindings() {

        viewModel.stations.bind { stations in

            stations.forEach({ pin in

                let annotation = MKPointAnnotation()

                let latitude = CLLocationDegrees(pin.latitude)
                let longitude = CLLocationDegrees(pin.longitude)

                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.title = pin.stationName

                self.annotations?.append(annotation)

                self.mapView.addAnnotation(MapPin(title: pin.stationName,
                                                  coordinate: CLLocationCoordinate2D(latitude: latitude,
                                                                                     longitude: longitude),
                                                  stationInformation: pin))
            })

            var currentLocationFromDevice: CLLocation?

            guard let unwrappedCity = self.viewModel.city else { return }

            if self.isUITesting() {
                currentLocationFromDevice = CLLocation(latitude: CLLocationDegrees(unwrappedCity.latitude), longitude: CLLocationDegrees(unwrappedCity.longitude))
            } else {
                currentLocationFromDevice = LocationServices.sharedInstance.currentLocation
            }

            guard let unwrappedLocation = currentLocationFromDevice else { return }

            self.selectClosestAnnotationGraph(stations: stations, currentLocation: unwrappedLocation)
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        dismissGraphView()
    }

    func centerMap(on point: CLLocationCoordinate2D) {

        let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

        let region = MKCoordinateRegion(center: point, span: coordinateSpan)

        self.mapView.setRegion(region, animated: true)
    }
}

// MARK: HomeViewModelDelegate

extension HomeViewController: HomeViewModelDelegate {

    func removePinsFromMap() {

        self.annotations?.removeAll()
        mapView.removeAnnotations(mapView.annotations)
    }

    func dismissGraphView() {
        self.graphView.hideView()
    }

    func changedUserLocation(location: CLLocation) {

        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func drawPrediction(data: [Int], prediction: Bool) {
        graphView.drawLine(values: data, isPrediction: prediction)
    }

    func segueToSettingsViewController() {
        viewModel.coordinatorDelegate?.showSettingsViewController()
    }

    func receivedError(with errorString: String) {
        let alert = UIAlertController(title: "ALERT_HEADER", message: errorString, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "CONFIRM_ALERT", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: MKMapViewDelegate

extension HomeViewController: MKMapViewDelegate {

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

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let userLocationView = mapView.view(for: userLocation)
        userLocationView?.canShowCallout = false
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        // Don't want to show a custom image if the annotation is the user's location.
        guard !(annotation is MKUserLocation) else {
            return nil
        }

        if let cluster = annotation as? MKClusterAnnotation {

            let markerAnnotationView = MKMarkerAnnotationView()
            markerAnnotationView.glyphText = String(cluster.memberAnnotations.count)
            markerAnnotationView.canShowCallout = false

            return markerAnnotationView
        }

        // Better to make this class property
        let annotationIdentifier = MKMapViewDefaultAnnotationViewReuseIdentifier

        var annotationView: MKAnnotationView?
        if let dequeuedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? CustomAnnotationView {
            annotationView = dequeuedAnnotationView
            annotationView?.annotation = annotation
        } else {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }

        if let annotationView = annotationView {
            // Configure your annotation view here
            annotationView.canShowCallout = false

            guard let annotationTitle = annotation.title else { return nil }
            guard let unwrappedAnnotationTitle = annotationTitle else { return nil }
            guard let stationsDictFromViewModel = self.viewModel.stationsDict.value[unwrappedAnnotationTitle] else { return nil }

            let markerAnnotationView = MKMarkerAnnotationView()
            markerAnnotationView.tag = 199
            markerAnnotationView.glyphTintColor = UIColor(named: "TextAndGraphColor")
            markerAnnotationView.markerTintColor = UIColor(named: "RedColor")
            markerAnnotationView.glyphText = "\(stationsDictFromViewModel.freeBikes)"
            markerAnnotationView.canShowCallout = false

            return markerAnnotationView
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        return MKClusterAnnotation(memberAnnotations: memberAnnotations)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        generator.impactOccurred()
        graphView.hideView()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        guard let annotationFromPin = view.annotation as? MapPin else { return }

        latestSelectedAnnotation = annotationFromPin

        var apiQueryStationValue: String?

        if viewModel.city?.apiName != "bilbao" {
            apiQueryStationValue = annotationFromPin.stationInformation.id
        } else {
            apiQueryStationValue = annotationFromPin.stationInformation.stationName
        }

        graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)

        centerMap(on: annotationFromPin.coordinate)

        viewModel.getApiData(city: viewModel.city!.apiName, type: "prediction", station: apiQueryStationValue!, prediction: true, completion: { result in

            self.generator.impactOccurred()
            self.graphView.showView()

            switch result {

            case .success(let predictionArray):

                guard self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName] != nil else { return }

                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.predictionArray = predictionArray

                self.viewModel.getApiData(city: self.viewModel.city!.apiName, type: "today", station: apiQueryStationValue!, prediction: false, completion: { todayResult in

                    switch todayResult {

                    case .success(let todayArray):

                        self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.availabilityArray = todayArray

                        print("RMSE MIO : \(self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.rmse)")

                        self.viewModel.calculateRmseFrom(prediction: predictionArray, actual: todayArray)
                    case .error:
                        break
                    }
                })

            case .error:
                break

            }

        })
    }
}
