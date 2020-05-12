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
import Combine
import MapKit
//#if canImport(SwiftUI) && DEBUG
//import SwiftUI
//struct HomeViewControllerRepresentable: UIViewRepresentable {
//    func makeUIView(context: Context) -> UIView {
//        return UIStoryboard(name: "Main", bundle: Bundle.main).instantiateInitialViewController()!.view
//    }
//    
//    func updateUIView(_ view: UIView, context: Context) {
//        
//    }
//}
//
//@available(iOS 13.0, *)
//struct HomeViewControllerPreview: PreviewProvider {
//    static var previews: some View {
//        HomeViewControllerRepresentable()
//    }
//}
//#endif

protocol HomeViewControllerGraphViewDelegate: class {
    func setStationTitleFor(name: String)
    func hideGraphView()
}

class HomeViewController: UIViewController {

    private weak var graphViewDelegate: HomeViewControllerGraphViewDelegate?

    private let compositeDisposable: CompositeDisposable

    private let viewModel: HomeViewModel

    private var mapView: MKMapView = {

        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        map.showsCompass = false
        map.accessibilityIdentifier = "MAP"

        return map
    }()

    private lazy var statisticsAndGraphViewStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [graphView, belowGraphHorizontalStackView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.backgroundColor = .blue
        stackView.isHidden = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()

    private lazy var belowGraphHorizontalStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [startRouteButton])
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }()

    private var graphView: PredictionGraphView = {
        let view = PredictionGraphView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        // handling code
        viewModel.coordinatorDelegate?.showSettingsViewController()
    }

    private var label: UILabel = {

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.text = ""
        return label
    }()

    // MARK: Renting

    private var startRouteButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "START_ROUTE"
        button.setTitle("START_ROUTE".localize(file: "Home"), for: .normal)
        button.isHidden = true

        return button
    }()
    
    private var rentButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "RENT_BIKE"
        button.isHidden = true
        button.setImage(UIImage(systemName: "lock.fill"), for: .normal)
        return button
    }()

    private var settingsButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "RENT_BIKE"
        button.setImage(UIImage(systemName: "gear"), for: .normal)
        button.imageView?.tintColor = .white
        
        return button
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
        view.addSubview(settingsButton)
        view.addSubview(rentButton)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        graphView.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            belowGraphHorizontalStackView.heightAnchor.constraint(equalToConstant: 50)
        ])

        // MARK: Settings Button constraints

        // Align to the bottom right
        NSLayoutConstraint.activate([
            settingsButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -2 * Constants.spacing),
            settingsButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -2 * Constants.spacing)
        ])

        // MARK: Rent button
        NSLayoutConstraint.activate([
            rentButton.bottomAnchor.constraint(equalTo: settingsButton.topAnchor, constant: -2 * Constants.spacing),
            rentButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -2 * Constants.spacing)
        ])
        
        NSLayoutConstraint.activate([
            startRouteButton.widthAnchor.constraint(equalToConstant: startRouteButton.titleLabel!.text!.width(withConstrainedHeight: startRouteButton.titleLabel!.frame.height, font: UIFont.systemFont(ofSize: UIFont.buttonFontSize, weight: .bold)) + 20.0)
        ])

        // Pin the borders of the graph to the container UIStackView
        NSLayoutConstraint.activate([
            graphView.leadingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.leadingAnchor),
            graphView.trailingAnchor.constraint(equalTo: statisticsAndGraphViewStackView.trailingAnchor),
            graphView.heightAnchor.constraint(equalToConstant: 110)
        ])

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
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

        // Find the index of the current station

        if let index = viewModel.stations.value.firstIndex(where: { $0.stationName == nearestStation.stationName }) {
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

    @objc func appMovedToForeground() {
        print("App moved to ForeGround!")

        if let currentUserLcoation = LocationServices.sharedInstance.currentLocation {
            centerMap(on: CLLocationCoordinate2D(latitude: currentUserLcoation.coordinate.latitude, longitude: currentUserLcoation.coordinate.longitude), coordinateSpan: Constants.narrowCoordinateSpan)
        }

        viewModel.getCurrentCity(completion: { currentCityResult in
            switch currentCityResult {

            case .success(let currentCity):
                self.viewModel.currentCity = currentCity

                guard let unwrappedCity = self.viewModel.currentCity else { return }

                self.viewModel.getMapPinsFrom(city: unwrappedCity)

            case .error(let err):
                self.presentAlertViewWithError(title: "Error", body: err.localizedDescription)
                print(err.localizedDescription)
            }
        })
    }

    @objc func appMovedToBackground() {
        print("App moved to Background!")

        guard let didSelectAnnotation = viewModel.latestSelectedAnnotation else { return }

        mapView.deselectAnnotation(didSelectAnnotation, animated: false)
    }

    @objc func selectNextStation() {



        self.viewModel.currentSelectedStationIndex += 1

        if let annotationIndex = self.mapView.annotations.firstIndex(where: { $0.title ==  self.viewModel.stations.value[self.viewModel.currentSelectedStationIndex].stationName }) {

            self.mapView.deselectAnnotation(self.mapView.annotations[annotationIndex], animated: true)

            self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)

            // If for any reason the current city is not saved cancel the operation
            guard viewModel.currentCity != nil else { return }

            let annotationFromPin = viewModel.stations.value[self.viewModel.currentSelectedStationIndex]

            //            guard let annotationFromPin = view.annotation as? MapPin else { return }

            centerMap(on: annotationFromPin.location.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)

            //            viewModel.latestSelectedAnnotation
            viewModel.latestSelectedBikeStation = annotationFromPin

            var apiQueryStationValue: String?

            apiQueryStationValue = annotationFromPin.id

//            if viewModel.currentCity?.apiName != "bilbao" {
//                apiQueryStationValue = annotationFromPin.id
//            } else {
//                apiQueryStationValue = annotationFromPin.stationName
//            }

            // Set the selected station name as the graph's title
            graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationName)

            guard apiQueryStationValue != nil else { return }

            viewModel.getAllDataFromApi(city: viewModel.currentCity!.apiName, station: apiQueryStationValue!, completion: { res in

                // As soon as new data is retrieved from the API show the graph
                self.showStackView()

                switch res {

                case .success(let payload):

                    self.viewModel.stationsDict.value[annotationFromPin.stationName]!.availabilityArray = payload["today"]
                    self.viewModel.stationsDict.value[annotationFromPin.stationName]!.predictionArray = payload["prediction"]

                    self.startRouteButton.isEnabled = true
                    self.showRoutePlannerButton()

                case .error:
                    break
                }
            })
        }
    }

    @objc func selectPreviousStation() {

        if self.viewModel.currentSelectedStationIndex == 0 { return }

        self.viewModel.currentSelectedStationIndex -= 1

        if let annotationIndex = self.mapView.annotations.firstIndex(where: { $0.title ==  self.viewModel.stations.value[self.viewModel.currentSelectedStationIndex].stationName }) {

            self.mapView.deselectAnnotation(self.mapView.annotations[annotationIndex], animated: true)
            self.mapView.selectAnnotation(self.mapView.annotations[annotationIndex], animated: true)

            // If for any reason the current city is not saved cancel the operation
            guard viewModel.currentCity != nil else { return }

            let annotationFromPin = viewModel.stations.value[self.viewModel.currentSelectedStationIndex]

            //            guard let annotationFromPin = view.annotation as? MapPin else { return }

            centerMap(on: annotationFromPin.location.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)

            //            viewModel.latestSelectedAnnotation
            viewModel.latestSelectedBikeStation = annotationFromPin

            var apiQueryStationValue: String?

            apiQueryStationValue = annotationFromPin.id

//            if viewModel.currentCity?.apiName != "bilbao" {
//                apiQueryStationValue = annotationFromPin.id
//            } else {
//                apiQueryStationValue = annotationFromPin.stationName
//            }

            // Set the selected station name as the graph's title
            graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationName)

            guard apiQueryStationValue != nil else { return }

            viewModel.getAllDataFromApi(city: viewModel.currentCity!.apiName, station: apiQueryStationValue!, completion: { res in

                // As soon as new data is retrieved from the API show the graph
                self.showStackView()

                switch res {

                case .success(let payload):

                    self.viewModel.stationsDict.value[annotationFromPin.stationName]!.availabilityArray = payload["today"]
                    self.viewModel.stationsDict.value[annotationFromPin.stationName]!.predictionArray = payload["prediction"]

                    self.startRouteButton.isEnabled = true
                    self.showRoutePlannerButton()

                case .error:
                    break
                }
            })
        }

    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(showSettingsViewController), discoverabilityTitle: "OPEN_SETTINGS_KEYBOARD".localize(file: "Home")),
            UIKeyCommand(input: "d", modifierFlags: .command, action: #selector(showInsightsViewController), discoverabilityTitle: "OPEN_INSIGHTS_KEYBOARD".localize(file: "Home")),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: .command, action: #selector(selectNextStation), discoverabilityTitle: "NEXT_STATION_KEYBOARD".localize(file: "Home")),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: .command, action: #selector(selectPreviousStation), discoverabilityTitle: "PREVIOUS_STATION_KEYBOARD".localize(file: "Home"))

        ]
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
        
        if UIDevice.current.userInterfaceIdiom == .phone || UIApplication.shared.isSplitOrSlideOver {

            NSLayoutConstraint.deactivate([
                // Center horizontally
                statisticsAndGraphViewStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                statisticsAndGraphViewStackView.widthAnchor.constraint(equalToConstant: 450),
                statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.spacing)

            ])
            
            NSLayoutConstraint.activate([
                statisticsAndGraphViewStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
                statisticsAndGraphViewStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
                statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
            ])
        }
        
        // If iPad reduce the width of the graph so it doesn't spans all the width of the screen
        else if UIDevice.current.userInterfaceIdiom == .pad && !UIApplication.shared.isSplitOrSlideOver {

            NSLayoutConstraint.deactivate([
                statisticsAndGraphViewStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16.0),
                statisticsAndGraphViewStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
                statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0)
            ])
            
            NSLayoutConstraint.activate([
                // Center horizontally
                statisticsAndGraphViewStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                statisticsAndGraphViewStackView.widthAnchor.constraint(equalToConstant: 450),
                statisticsAndGraphViewStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.spacing)

            ])

        }
        
        mapView.frame = self.view.bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        compositeDisposable.dispose()
    }

    @objc func showSettingsViewController() {
        viewModel.coordinatorDelegate?.showSettingsViewController()
    }

    @objc func showInsightsViewController() {
        guard let latestSelectedStation = self.viewModel.latestSelectedBikeStation else { return }

//        FeedbackGenerator.sharedInstance.generator.impactOccurred()
        
        self.viewModel.selectedRoute(station: latestSelectedStation)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    fileprivate func setupBindings() {

        compositeDisposable += startRouteButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in
            guard let self = self else { fatalError() }

            LogHelper.logTAppedDataInsightsButton()
            FeedbackGenerator.sharedInstance.generator.impactOccurred()

            self.showInsightsViewController()
        })
        
        compositeDisposable += rentButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] _ in
            
            self?.viewModel.startRentProcess()
        })

        compositeDisposable += settingsButton.reactive.controlEvents(.touchUpInside).observe({ [weak self] (_) in
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            LogHelper.logTAppedSettingsButton()
            self?.showSettingsViewController()
        })

        viewModel.stations.bind { stations in

            stations.forEach({ pin in

                let pinCoordinate: CLLocationCoordinate2D = {
                    let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude),
                                                            longitude: CLLocationDegrees(pin.longitude))
                    return coordinate
                }()

                self.mapView.addAnnotation(MapPin(title: pin.stationName,
                                                  coordinate: pinCoordinate,
                                                  stationInformation: pin))
            })

            var currentLocationFromDevice = CLLocation()

            switch UITestingHelper.sharedInstance.isUITesting() {
            case true:

                guard let unwrappedCity = self.viewModel.currentCity else { return }

                currentLocationFromDevice = CLLocation(latitude: CLLocationDegrees(unwrappedCity.latitude), longitude: CLLocationDegrees(unwrappedCity.longitude))
            case false:
                guard let locationFromDevice = LocationServices.sharedInstance.currentLocation else { return }

                currentLocationFromDevice = locationFromDevice
            }

            if !UITestingHelper.sharedInstance.isUITesting() {
                self.selectClosestAnnotationGraph(stations: stations, currentLocation: currentLocationFromDevice)
            } else {
                self.selectClosestAnnotationGraph(stations: stations,
                                                  currentLocation: CLLocation(latitude: CLLocationDegrees(self.viewModel.currentCity!.latitude),
                                                                              longitude: CLLocationDegrees(self.viewModel.currentCity!.longitude)))
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

        graphViewDelegate?.hideGraphView()

        graphView.fadeOut(0.2)
        hideRoutePlannerButton()

        if viewModel.latestSelectedAnnotation != nil {
            mapView.deselectAnnotation(viewModel.latestSelectedAnnotation, animated: false)
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

    func shouldShowRentBikeButton() {
        rentButton.isHidden = false
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

    func changedUserLocation(location: CLLocation) {

        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func drawPrediction(data: [Int], prediction: Bool) {
        graphView.drawLine(values: data, isPrediction: prediction)
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
        guard viewModel.currentCity != nil else { return }

        guard let annotationFromPin = view.annotation as? MapPin else { return }

        centerMap(on: annotationFromPin.coordinate, coordinateSpan: Constants.narrowCoordinateSpan)

        viewModel.latestSelectedAnnotation = annotationFromPin
        viewModel.latestSelectedBikeStation = annotationFromPin.stationInformation

        var apiQueryStationValue: String?

        apiQueryStationValue = annotationFromPin.stationInformation.id

//        if viewModel.currentCity?.apiName != "bilbao" {
//            apiQueryStationValue = annotationFromPin.stationInformation.id
//        } else {
//            apiQueryStationValue = annotationFromPin.stationInformation.stationName
//        }

        // Set the selected station name as the graph's title
        graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)

        guard apiQueryStationValue != nil else { return }

        viewModel.getAllDataFromApi(city: viewModel.currentCity!.apiName, station: apiQueryStationValue!, completion: { res in

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
