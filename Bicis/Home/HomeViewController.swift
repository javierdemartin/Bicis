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

    var annotations: [MKAnnotation]?
    var latestSelectedAnnotation: MKAnnotation?
    var latestSelectedBikeStation: BikeStation?

    weak var graphViewDelegate: HomeViewControllerGraphViewDelegate?

    let compositeDisposable: CompositeDisposable

    var currentCity: City?

    var routeOverlay = MKRoute()

    let viewModel: HomeViewModel

    var mapView: MKMapView = {

        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        map.showsCompass = false
        map.accessibilityIdentifier = "MAP"

        return map
    }()

    lazy var statisticsAndGraphViewStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [graphView, belowGraphHorizontalStackView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.backgroundColor = .blue
        stackView.isHidden = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()

    lazy var belowGraphHorizontalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [startRouteButton])
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()

    var startRouteButton: UIButton = {

        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = Appearance().cornerRadius
        button.accessibilityIdentifier = "START_ROUTE"
        button.backgroundColor = UIColor.systemBlue //UIColor(named: "RedColor")
        button.titleLabel?.font = Constants.buttonFont
        button.setTitle("START_ROUTE".localize(file: "Home"), for: .normal)
        button.setTitleColor(UIColor.systemGray4, for: .disabled)
        button.clipsToBounds = true
        button.isEnabled = false
        button.isHidden = true
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
            belowGraphHorizontalStackView.heightAnchor.constraint(equalToConstant: 50)
        ])

        NSLayoutConstraint.activate([
            startRouteButton.widthAnchor.constraint(equalToConstant: startRouteButton.titleLabel!.text!.width(withConstrainedHeight: startRouteButton.titleLabel!.frame.height, font: UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .bold)) + 20.0)
        ])

        NSLayoutConstraint.activate([
            graphView.leadingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.leadingAnchor),
            graphView.trailingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.trailingAnchor),
            graphView.heightAnchor.constraint(equalToConstant: 110)

        ])

        if UIDevice.current.userInterfaceIdiom == .pad {

            NSLayoutConstraint.activate([
                statisticsAndGraphViewStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 32),
                statisticsAndGraphViewStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -32),
                statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0)

            ])

        } else if UIDevice.current.userInterfaceIdiom == .phone {

            NSLayoutConstraint.activate([
                statisticsAndGraphViewStackView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16.0),
                statisticsAndGraphViewStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16.0),
                statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0)
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

        self.hideStackView()

        viewModel.getCurrentCity(completion: { [weak self] cityResult in

            guard let self = self else { fatalError() }

            switch cityResult {

            case .success(let city):

                let cityCoordinates: CLLocationCoordinate2D = {

                    let latitude = CLLocationDegrees(city.latitude)
                    let longitude = CLLocationDegrees(city.longitude)

                    let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                    return coordinates
                }()

                self.centerMap(on: cityCoordinates, coordinateSpan: Constants.narrowCoordinateSpan)

            case .error:
                break
            }
        })
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
                                                  longitude: CLLocationDegrees(nearestStation.longitude)), coordinateSpan: Constants.narrowCoordinateSpan)

        if self.mapView.annotations.contains(where: {$0.title == nearestStation.stationName}) {

            if let foo = self.mapView.annotations.first(where: {$0.title == nearestStation.stationName}) {
                self.mapView.selectAnnotation(foo, animated: true)
            }
        }
    }

    @objc func appMovedToForeground() {
        print("App moved to ForeGround!")

        if let currentUserLcoation = LocationServices.sharedInstance.currentLocation {
            centerMap(on: CLLocationCoordinate2D(latitude: currentUserLcoation.coordinate.latitude, longitude: currentUserLcoation.coordinate.longitude), coordinateSpan: Constants.narrowCoordinateSpan)
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

        mapView.delegate = self
        graphViewDelegate = graphView

        setupBindings()
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

        compositeDisposable += startRouteButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in
            guard let self = self else { fatalError() }

            guard let latestSelectedStation = self.latestSelectedBikeStation else { return }

            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            self.viewModel.selectedRoute(station: latestSelectedStation)
        })

        viewModel.stations.bind { stations in

            stations.forEach({ pin in

                let pinCoordinate: CLLocationCoordinate2D = {
                    let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude),
                                                            longitude: CLLocationDegrees(pin.longitude))
                    return coordinate
                }()

                let annotation: MKAnnotation = {

                    let annotation = MKPointAnnotation()
                    annotation.coordinate = pinCoordinate
                    annotation.title = pin.stationName

                    return annotation
                }()

                self.annotations?.append(annotation)

                self.mapView.addAnnotation(MapPin(title: pin.stationName,
                                                  coordinate: pinCoordinate,
                                                  stationInformation: pin))
            })

            var currentLocationFromDevice = CLLocation()

            switch UITestingHelper.sharedInstance.isUITesting() {
            case true:

                guard let unwrappedCity = self.viewModel.city else { return }

                currentLocationFromDevice = CLLocation(latitude: CLLocationDegrees(unwrappedCity.latitude), longitude: CLLocationDegrees(unwrappedCity.longitude))
            case false:
                guard let locationFromDevice = LocationServices.sharedInstance.currentLocation else { return }

                currentLocationFromDevice = locationFromDevice
            }

            if !UITestingHelper.sharedInstance.isUITesting() {
                self.selectClosestAnnotationGraph(stations: stations, currentLocation: currentLocationFromDevice)
            } else {
                self.selectClosestAnnotationGraph(stations: stations,
                                                  currentLocation: CLLocation(latitude: CLLocationDegrees(self.viewModel.city!.latitude),
                                                                              longitude: CLLocationDegrees(self.viewModel.city!.longitude)))
            }
        }
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        dismissGraphView()
    }

    func centerMap(on point: CLLocationCoordinate2D, coordinateSpan: MKCoordinateSpan) {

        let region = MKCoordinateRegion(center: point, span: coordinateSpan)

        self.mapView.setRegion(region, animated: true)
    }

    func hideStackView() {

        FeedbackGenerator.sharedInstance.generator.impactOccurred()

        graphView.fadeOut(0.2)
        hideRoutePlannerButton()

        if latestSelectedAnnotation != nil {
            mapView.deselectAnnotation(latestSelectedAnnotation, animated: false)
        }
    }

    /// Hide the `PredictionGraphView` pushing the Start commute ubtton up
    func showStackView() {

        FeedbackGenerator.sharedInstance.generator.impactOccurred()
        graphView.fadeIn(0.2)
    }

    func showRoutePlannerButton() {
        startRouteButton.fadeIn(0.2)
    }

    func hideRoutePlannerButton() {
        startRouteButton.fadeOut(0.2)
    }
}

// MARK: HomeViewModelDelegate
extension HomeViewController: HomeViewModelDelegate {

    func presentAlertViewWithError(title: String, body: String) {

        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)

        self.present(alertController, animated: true, completion: nil)
    }

    /// Called when a new city is selected, removing the pins from the previous city
    func removePinsFromMap() {
        self.annotations?.removeAll()
        mapView.removeAnnotations(mapView.annotations)
    }

    func dismissGraphView() {
        self.hideStackView()
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

            // Disable the callout showing the title, the title will be shown in the GraphView
            annotationView.canShowCallout = false

            guard let annotationTitle = annotation.title! else { return nil }
            guard let stationsDictFromViewModel = self.viewModel.stationsDict.value[annotationTitle] else { return nil }

            let markerAnnotationView: MKMarkerAnnotationView = {
                let marker = MKMarkerAnnotationView()
                marker.glyphText = "\(stationsDictFromViewModel.freeBikes)"

                return marker
            }()

            self.viewModel.hasUnlockedFeatures(completion: { hasPaid in

                if hasPaid {
                    // Stablish the color coding of the availability
                    switch stationsDictFromViewModel.percentageOfFreeBikes {
                    case 66.0..<100.0:
                        markerAnnotationView.markerTintColor = UIColor.systemGreen
                    case 33.0...66.0:
                        markerAnnotationView.markerTintColor = UIColor.systemOrange
                    case ..<33.0:
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
        startRouteButton.isEnabled = false
    }

    /// Annotation was selected
    /// 1. Query the API for the prediction and availability data
    /// 2. Center the MapView
    /// 3. Set the `GraphView`'s title using the selected station name
    /// 4. Show the route planner view controller
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        // If for any reason the current city is not saved cancel the operation
        guard viewModel.city != nil else { return }

        guard let annotationFromPin = view.annotation as? MapPin else { return }

        centerMap(on: annotationFromPin.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)

        latestSelectedAnnotation = annotationFromPin
        latestSelectedBikeStation = annotationFromPin.stationInformation

        var apiQueryStationValue: String?

        if viewModel.city?.apiName != "bilbao" {
            apiQueryStationValue = annotationFromPin.stationInformation.id
        } else {
            apiQueryStationValue = annotationFromPin.stationInformation.stationName
        }

        // Set the selected station name as the graph's title
        graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)

        guard apiQueryStationValue != nil else { return }

        viewModel.getAllDataFromApi(city: viewModel.city!.apiName, station: apiQueryStationValue!, completion: { res in

            // As soon as new data is retrieved from the API show the graph
            self.showStackView()

            switch res {

            case .success(let payload):

                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.availabilityArray = payload["today"]
                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.predictionArray = payload["prediction"]

                self.startRouteButton.isEnabled = true
                self.showRoutePlannerButton()

            case .error:
                break
            }
        })
    }
}
