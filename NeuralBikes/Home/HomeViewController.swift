//
//  HomeViewController.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import UIKit
import SwiftUI
import Combine
import MapKit

protocol HomeViewControllerGraphViewDelegate: class {
    func hideGraphView()
    func setStationTitleFor(name: String)
}

class HomeViewController: UIViewController {

    weak var graphViewDelegate: HomeViewControllerGraphViewDelegate?
    
    @ObservedObject var viewModel: HomeViewModel
    
    var otherCancellable: AnyCancellable?
    var cancellableBag = Set<AnyCancellable>()
    
    lazy var mapView: MKMapView = {

        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.showsUserLocation = true
        map.showsCompass = false
        map.accessibilityIdentifier = "MAP"

        return map
    }()

    private lazy var statisticsAndGraphViewStackView: UIStackView = {

        let stackView = UIStackView(arrangedSubviews: [graphView])
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalCentering
        stackView.spacing = 10.0
        stackView.isHidden = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView

    }()
    
    var graphView: PredictionGraphView = {
        let view = PredictionGraphView(frame: .zero, true)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true

        return view
    }()

    private var label: UILabel = {

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = true
        label.text = ""
        return label
    }()
    
    private lazy var bottomButtonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [insightsButton, settingsButton])
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = NSLayoutConstraint.Axis.vertical
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = Constants.spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    var insightsButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityLabel = NSLocalizedString("DATA_INSIGHTS_ACCESIBILITY_LABEL", comment: "")
        button.accessibilityIdentifier = "START_ROUTE"
        button.accessibilityLabel = NSLocalizedString("DATA_INSIGHTS_ACCESIBILITY_BUTTON", comment: "")
        button.setImage(UIImage(systemName: "lightbulb"), for: .normal)
        button.setImage(UIImage(systemName: "lightbulb.fill"), for: .selected)
        button.layer.borderWidth = 2.0
        button.layer.borderColor = UIColor(white: 0.25, alpha: 0.4).cgColor
        button.layer.masksToBounds = true
        button.isHidden = true

        return button
    }()
    
    private var settingsButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "SETTINGS"
        button.accessibilityLabel = NSLocalizedString("SETTINGS_ACCESIBILITY_BUTTON", comment: "")
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .selected)
        button.layer.borderWidth = 2.0
        button.layer.borderColor = UIColor(white: 0.25, alpha: 0.4).cgColor
        button.layer.masksToBounds = true
        button.imageView?.tintColor = .white
        
        return button
    }()
    
    init(viewModel: HomeViewModel) {

        self.viewModel = viewModel

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
        view.addSubview(bottomButtonsStackView)
        
        // Align to the bottom right
        NSLayoutConstraint.activate([
            bottomButtonsStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -2 * Constants.spacing),
            bottomButtonsStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -2 * Constants.spacing)
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        graphView.clipsToBounds = true
        graphView.layer.cornerRadius = Constants.cornerRadius
        
        viewModel.setUpLocation()

        self.hideStackView()
        viewModel.getCurrentCity(completion: { [weak self] cityResult in

            guard let self = self else { fatalError() }

            switch cityResult {

            case .success(let city):
                
                self.centerMap(on: CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude)), coordinateSpan: Constants.narrowCoordinateSpan)

            case .error:
                break
            }
        })
    }

    @objc func appMovedToForeground() {
    
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
        guard let didSelectAnnotation = viewModel.latestSelectedAnnotation else { return }

        mapView.deselectAnnotation(didSelectAnnotation, animated: false)
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(title: NSLocalizedString("OPEN_SETTINGS_KEYBOARD", comment: ""), action: #selector(showSettingsViewController), input: "s", modifierFlags: .command, alternates: [], discoverabilityTitle: NSLocalizedString("OPEN_SETTINGS_KEYBOARD", comment: ""), attributes: .destructive, state: .on),
            UIKeyCommand(title: NSLocalizedString("OPEN_INSIGHTS_KEYBOARD", comment: ""), action: #selector(showSettingsViewController), input: "d", modifierFlags: .command, alternates: [], discoverabilityTitle: NSLocalizedString("OPEN_INSIGHTS_KEYBOARD", comment: ""), attributes: .destructive, state: .on)
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
        cancellableBag.removeAll()
    }

    @objc func showSettingsViewController() {

        viewModel.coordinatorDelegate?.showSettingsViewController()
    }

    @objc func showInsightsViewController() {

        guard let latestSelectedStation = self.viewModel.latestSelectedBikeStation else { return }
        
        self.viewModel.selectedRoute(station: latestSelectedStation)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    fileprivate func setupBindings() {
        
        settingsButton.publisher(for: .touchUpInside).sink { button in
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            self.showSettingsViewController()
        }.store(in: &cancellableBag)
        
        insightsButton.publisher(for: .touchUpInside).sink { _ in
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            self.showInsightsViewController()
        }.store(in: &cancellableBag)
        
        otherCancellable = viewModel.$stations.sink(receiveValue: { stations in
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

            switch UITestingHelper.sharedInstance.isUITesting() {
            case true:
                guard let unwrappedCity = self.viewModel.currentCity else { return }

                let currentLocationFromDevice = CLLocation(latitude: CLLocationDegrees(unwrappedCity.latitude), longitude: CLLocationDegrees(unwrappedCity.longitude))
                
                self.selectClosestAnnotationGraph(stations: stations, currentLocation: currentLocationFromDevice)
            case false:
                break
            }
        })        
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        dismissGraphView()
    }

    func hideStackView() {

        FeedbackGenerator.sharedInstance.generator.impactOccurred()

        graphView.fadeOut(0.2)
        graphViewDelegate?.hideGraphView()
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

    func showInsightsButton() {
        insightsButton.fadeIn(0.2)
    }

    func hideRoutePlannerButton() {
        insightsButton.fadeOut(0.2)
    }
}


/// https://www.avanderlee.com/swift/custom-combine-publisher/
/// A custom subscription to capture UIControl target events.
final class UIControlSubscription<SubscriberType: Subscriber, Control: UIControl>: Subscription where SubscriberType.Input == Control {
    private var subscriber: SubscriberType?
    private let control: Control

    init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        control.addTarget(self, action: #selector(eventHandler), for: event)
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        subscriber = nil
    }

    @objc private func eventHandler() {
        _ = subscriber?.receive(control)
    }
}

/// A custom `Publisher` to work with our custom `UIControlSubscription`.
struct UIControlPublisher<Control: UIControl>: Publisher {

    typealias Output = Control
    typealias Failure = Never

    let control: Control
    let controlEvents: UIControl.Event

    init(control: Control, events: UIControl.Event) {
        self.control = control
        self.controlEvents = events
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == UIControlPublisher.Failure, S.Input == UIControlPublisher.Output {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
        subscriber.receive(subscription: subscription)
    }
}

/// Extending the `UIControl` types to be able to produce a `UIControl.Event` publisher.
protocol CombineCompatible { }
extension UIControl: CombineCompatible { }
extension CombineCompatible where Self: UIControl {
    func publisher(for events: UIControl.Event) -> UIControlPublisher<UIControl> {
        return UIControlPublisher(control: self, events: events)
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
            
            markerAnnotationView.glyphText = "\(stationsDictFromViewModel.freeBikes)"
            
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

//        var apiQueryStationValue: String?

        let apiQueryStationValue = annotationFromPin.stationInformation.id
        
        graphViewDelegate?.setStationTitleFor(name: annotationFromPin.stationInformation.stationName)

        viewModel.getAllDataFromApi(city: viewModel.currentCity!.apiName, station: apiQueryStationValue, completion: { res in

            // As soon as new data is retrieved from the API show the graph
            self.showStackView()

            switch res {

            case .success(let payload):

                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.availabilityArray = payload["today"]
                self.viewModel.stationsDict.value[annotationFromPin.stationInformation.stationName]!.predictionArray = payload["prediction"]

                self.insightsButton.isEnabled = true
                self.showInsightsButton()
                self.graphView.accessibilityLabel = NSLocalizedString("SELECTED_STATION_GRAPH_ACCESIBILITY_LABEL", comment: "").replacingOccurrences(of: "%name", with: annotationFromPin.stationInformation.stationName)

            case .error:
                break
            }
        })
    }
}

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

        // Find the index of the current station
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
    
    func centerMap(on point: CLLocationCoordinate2D, coordinateSpan: MKCoordinateSpan) {

        let region = MKCoordinateRegion(center: point, span: coordinateSpan)
        self.mapView.setRegion(region, animated: false)
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
