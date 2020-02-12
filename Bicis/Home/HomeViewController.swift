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
import GoogleMobileAds

protocol HomeViewControllerGraphViewDelegate: class {
    func setStationTitleFor(name: String)
}

class HomeViewController: UIViewController {

    var annotations: [MKAnnotation]?
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

    var adBannerView: DFPBannerView = {
        let bannerView = DFPBannerView(adSize: kGADAdSizeBanner)
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        return bannerView
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

        print(self.view.bounds.size)

        if !graphView.isHidden {
            graphView.hideView()
        }
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

        if !isUITesting() {
            view.addSubview(adBannerView)
            view.bringSubviewToFront(adBannerView)

            view.addConstraints(
            [NSLayoutConstraint(item: adBannerView,
                                attribute: .bottom,
                                relatedBy: .equal,
                                toItem: bottomLayoutGuide,
                                attribute: .top,
                                multiplier: 1,
                                constant: 0),
             NSLayoutConstraint(item: adBannerView,
                                attribute: .centerX,
                                relatedBy: .equal,
                                toItem: view,
                                attribute: .centerX,
                                multiplier: 1,
                                constant: 0)
            ])
        }




        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        graphView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            graphView.heightAnchor.constraint(equalToConstant: 110)
        ])

        if UIDevice.current.userInterfaceIdiom == .pad {

            NSLayoutConstraint.activate([
//                graphView.widthAnchor.constraint(equalToConstant: 450),
//                graphView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor)
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

        viewModel.getCurrentCity(completion: { currentCityResult in
            switch currentCityResult {

            case .success(let currentCity):
                self.currentCity = currentCity

                let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(currentCity.latitude), longitude: CLLocationDegrees(currentCity.longitude))

                self.centerMap(on: centerCoordinates)

            case .error(let err):
                // TODO: Mostrar error
                print(err.localizedDescription)
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        graphView.hideView()
        graphView.isHidden = true
    }

    func selectClosestAnnotationGraph(stations: [BikeStation], currentLocation: CLLocation, completion: @escaping(Result<Void>) -> Void) {

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

        self.graphView.showView()
        self.graphViewDelegate?.setStationTitleFor(name: nearestStation.stationName)

        guard let currentCity = self.viewModel.city else { return }

        self.viewModel.getApiData(city: currentCity.apiName,
                                  type: "prediction",
                                  station: nearestStation.stationName,
                                  prediction: true)
        self.viewModel.getApiData(city: currentCity.apiName,
                                  type: "today",
                                  station: nearestStation.stationName,
                                  prediction: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        mapView.delegate = self
        graphViewDelegate = graphView
        
        if !isUITesting() {
            
            adBannerView.rootViewController = self
//            adBannerView.adUnitID = "/6499/example/banner"
            adBannerView.adUnitID = "ca-app-pub-6446389863983986/8701019584" 
            adBannerView.load(DFPRequest())
        }

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

            guard let currentLocation = currentLocationFromDevice else { return }

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

            self.graphView.showView()
            self.graphViewDelegate?.setStationTitleFor(name: nearestStation.stationName)

            guard let currentCity = self.viewModel.city else { return }

            self.viewModel.getApiData(city: currentCity.apiName,
                                      type: "prediction",
                                      station: nearestStation.stationName,
                                      prediction: true)
            self.viewModel.getApiData(city: currentCity.apiName,
                                      type: "today",
                                      station: nearestStation.stationName,
                                      prediction: false)
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {

        dismissGraphView()

        if UIApplication.shared.statusBarOrientation.isLandscape {
            // activate landscape changes
        } else {
            // activate portrait changes
        }
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
//            annotationView.number = UInt32(stationsDictFromViewModel.freeBikes)
        }

        return annotationView


//
//        if annotation is MapPin {
//
//            let bikeStationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: "pinAnnotation")
//
//            guard let annotationTitle = annotation.title else { return nil }
//
//            guard let unwrappedAnnotationTitle = annotationTitle else { return nil }
//
//            guard let stationsDictFromViewModel = self.viewModel.stationsDict.value[unwrappedAnnotationTitle] else { return nil }
//
//            bikeStationView.number = UInt32(stationsDictFromViewModel.freeBikes)
//            bikeStationView.canShowCallout = false

//
//            return bikeStationView
//
//        }
    }

//    private func registerAnnotationViewClasses() {
//        mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
//    }

    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
        return MKClusterAnnotation(memberAnnotations: memberAnnotations)
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        graphView.hideView()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        guard let annotationFromPin = view.annotation as? MapPin else { return }

        var apiQueryStationValue: String?

        if viewModel.city?.apiName != "bilbao" {
            apiQueryStationValue = annotationFromPin.stationInformation.id
        } else {
            apiQueryStationValue = annotationFromPin.stationInformation.stationName
        }

        // Set the station's title in the PredictionGraphView

//        graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)
//        graphViewDelegate?.setStationTitleFor(name: view.annotation?.title)

        if view.tag != 0 {

            guard let stationTitle = annotationFromPin.title
                else { return }

            view.canShowCallout = false

            graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)

//            guard let auxxx = view as? CustomAnnotationView else { return }
//
//            auxxx.setTitle(forStation: stationTitle)

            self.centerMap(on: annotationFromPin.coordinate)

            graphView.showView()

            viewModel.getApiData(city: viewModel.city!.apiName, type: "prediction", station: apiQueryStationValue!, prediction: true)
            viewModel.getApiData(city: viewModel.city!.apiName, type: "today", station: apiQueryStationValue!, prediction: false)
        }
    }
}
