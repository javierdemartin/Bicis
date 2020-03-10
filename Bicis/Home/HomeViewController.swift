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

    var routeOverlay = MKRoute()

    let viewModel: HomeViewModel

    var mapView: MKMapView = {

        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true

        return map
    }()

    lazy var statisticsAndGraphViewStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [graphView, belowGraphHorizontalStackView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = 10.0
        stackView.backgroundColor = .blue
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()

    lazy var belowGraphHorizontalStackView: UIStackView = {

//        let stackView = UIStackView(arrangedSubviews: [startRouteButton, nextTimeEmptyHorizontalStackView])
        let stackView = UIStackView(arrangedSubviews: [startRouteButton])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()

    var startRouteButton: UIButton = {

        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = Appearance().cornerRadius
        button.backgroundColor = UIColor(named: "RedColor")
        button.setTitle("START_ROUTE", for: .normal)
        button.clipsToBounds = true
        return button
    }()

    lazy var nextTimeEmptyHorizontalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [emptyStationTimeImageView, nextRefilTimeLabel])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.backgroundColor = .blue
        stackView.translatesAutoresizingMaskIntoConstraints = false
        // UIStackView is a non-drawing view, add a background adding a view
        stackView.addSubview(nextTimeEmptyStationView)

        return stackView
    }()

    var nextTimeEmptyStationView: UIView = {

        let view = UIView()
        view.layer.cornerRadius = Appearance().cornerRadius
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    var emptyStationTimeImageView: UIImageView = {

        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "0.circle")

        return imageView
    }()

    var nextRefilTimeLabel: UILabel =  {

        let label = UILabel()
        label.text = "16:00"

        return label
    }()

    var graphView: PredictionGraphView = {
        let view = PredictionGraphView()
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true

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

        view.addSubview(statisticsAndGraphViewStackView)
        view.bringSubviewToFront(statisticsAndGraphViewStackView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        graphView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([

            statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0)
        ])

        NSLayoutConstraint.activate([

            belowGraphHorizontalStackView.leadingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.leadingAnchor),
            belowGraphHorizontalStackView.trailingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.trailingAnchor),
            belowGraphHorizontalStackView.heightAnchor.constraint(equalToConstant: 50)
        ])

//        NSLayoutConstraint.activate([
//
//            nextTimeEmptyHorizontalStackView.leadingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.leadingAnchor),
//            nextTimeEmptyHorizontalStackView.trailingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.centerXAnchor),
//        ])

        NSLayoutConstraint.activate([
            graphView.leadingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.leadingAnchor),
            graphView.trailingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.trailingAnchor),
            graphView.heightAnchor.constraint(equalToConstant: 110)
        ])

        if UIDevice.current.userInterfaceIdiom == .pad {

            NSLayoutConstraint.activate([
                statisticsAndGraphViewStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 32),
                statisticsAndGraphViewStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -32)

            ])

        } else if UIDevice.current.userInterfaceIdiom == .phone {

            NSLayoutConstraint.activate([
                statisticsAndGraphViewStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16.0),
                statisticsAndGraphViewStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16.0)
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

//        graphView.hideView()
//        graphView.isHidden = true

        self.hideStackView()

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
                self.presentAlertViewWithError(title: "Error", body: err.localizedDescription)
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

//        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

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

        viewModel.destinationStation.bind({ st in

            guard st != nil else { return }

            // TODO: Remove force unwrap
            self.showRouteOnMap(pickupCoordinate: (LocationServices.sharedInstance.locationManager?.location!.coordinate)!, destinationCoordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(st!.latitude), longitude: CLLocationDegrees(st!.longitude)))
        })

        compositeDisposable += startRouteButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in
            guard let self = self else { fatalError() }

            self.viewModel.modallyPresentRoutePlanner()
        })

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

            // TODO: Undo this
//            self.selectClosestAnnotationGraph(stations: stations, currentLocation: unwrappedLocation)
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

    func hideStackView() {

        self.graphView.hideView()

        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {

            self.statisticsAndGraphViewStackView.transform = CGAffineTransform(translationX: 0, y: -1 * (0 + 110.0))
            self.statisticsAndGraphViewStackView.layoutIfNeeded()
        }, completion: { _ in

            self.statisticsAndGraphViewStackView.isHidden = true
        })
    }

    func showStackView() {

        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {

//            self.statisticsAndGraphViewStackView.transform = CGAffineTransform(translationX: 0, y: 0 + 55.0)
            self.statisticsAndGraphViewStackView.transform = CGAffineTransform(translationX: 0, y: 0 + 5.0)

            self.statisticsAndGraphViewStackView.isHidden = false
//            self.statisticsAndGraphViewStackView.isHidden = false
            self.statisticsAndGraphViewStackView.layoutIfNeeded()
        }, completion: {_ in

        })

    }
}

// MARK: HomeViewModelDelegate

extension HomeViewController: HomeViewModelDelegate {
    func updatePredictionStatus(imageString: String, nextHour: String) {
        nextRefilTimeLabel.text = "~\(nextHour)"
    }

    func presentAlertViewWithError(title: String, body: String) {

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }

    func removePinsFromMap() {

        self.annotations?.removeAll()
        mapView.removeAnnotations(mapView.annotations)
    }

    func dismissGraphView() {

        self.hideStackView()
//        self.graphView.hideView()
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

    // MARK: - showRouteOnMap

    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {

        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)

        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

        let sourceAnnotation = MKPointAnnotation()

        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }

        let destinationAnnotation = MKPointAnnotation()

        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }

        self.mapView.showAnnotations([sourceAnnotation, destinationAnnotation], animated: true)

        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile

        // Calculate the direction
        let directions = MKDirections(request: directionRequest)

        directions.calculate { (response, error) -> Void in

            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }

                return
            }

            self.routeOverlay = response.routes[0]

            self.mapView.addOverlay((self.routeOverlay.polyline), level: MKOverlayLevel.aboveRoads)

            let rect = self.routeOverlay.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKPolylineRenderer(overlay: overlay)

        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)

        renderer.lineWidth = 5.0

        return renderer
    }

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
        hideStackView()
//        graphView.hideView()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        guard let annotationFromPin = view.annotation as? MapPin else { return }

        mapView.removeOverlay(self.routeOverlay.polyline)

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
            self.showStackView()

            switch result {

            case .success(let predictionArray):

                guard self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName] != nil else { return }

                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.predictionArray = predictionArray

                self.viewModel.getApiData(city: self.viewModel.city!.apiName, type: "today", station: apiQueryStationValue!, prediction: false, completion: { todayResult in

                    switch todayResult {

                    case .success(let todayArray):

                        self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.availabilityArray = todayArray

                        print("RMSE (%) \(self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.rmse!)")

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
