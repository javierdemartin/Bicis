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

enum ShowsNumberInAnnotation {
    
    case freeBikes
    case freeDocks
}

class HomeViewController: UIViewController {

    weak var graphViewDelegate: HomeViewControllerGraphViewDelegate?
    
    @ObservedObject var viewModel: HomeViewModel

    var whatsShown: ShowsNumberInAnnotation = .freeBikes
    
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
    
    lazy var activeRentalScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.scrollsToTop = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.isDirectionalLockEnabled = true
        scrollView.isHidden = true

        return scrollView
    }()
    
    private lazy var activeRentalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [activeRentalBike])
        stackView.alignment = UIStackView.Alignment.center
        stackView.backgroundColor = .white
        stackView.addBackground(color: .red)
        stackView.axis = NSLayoutConstraint.Axis.horizontal
        stackView.distribution  = UIStackView.Distribution.equalSpacing
        stackView.spacing = Constants.spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    lazy var blurAlertView: UIView = {
        let blur = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blur)
        let vibrancy = UIVibrancyEffect(blurEffect: blur)
        let vibrantView = UIVisualEffectView(effect: blurView.effect)
        vibrantView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.contentView.addSubview(vibrantView)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.layer.cornerRadius = 20
        blurView.layer.masksToBounds = true
        let blendView = UIView()
        blendView.backgroundColor = .white
        blendView.alpha = 0.4
        blendView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        blurView.contentView.addSubview(blendView)
//        return blurView
        
        let childView = UIHostingController(rootView: BlurAlertView())
        childView.view.translatesAutoresizingMaskIntoConstraints = false
        childView.view.addSubview(blendView)
        childView.view.layer.masksToBounds = true
        childView.view.layer.cornerRadius = 20
        
        childView.view.isHidden = true
                
        return childView.view
        
    }()
    
    var activeRentalBike: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.setTitle("", for: .normal)

        return button
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

    // MARK: Renting
    
    private lazy var bottomButtonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [rentButton, insightsButton, alternateDocksBikesButton, settingsButton])
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
        button.setImage(UIImage(systemName: "info.circle.fill"), for: .normal)
        button.isHidden = true

        return button
    }()
    
    var rentButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "RENT_BIKE"
        button.accessibilityLabel = NSLocalizedString("RENT_BIKE_ACCESIBILITY_LABEL", comment: "")
        button.isHidden = true
        button.setImage(UIImage(systemName: "lock.fill"), for: .normal)
        return button
    }()

    private var settingsButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "SETTINGS"
        button.accessibilityLabel = NSLocalizedString("SETTINGS_ACCESIBILITY_BUTTON", comment: "")
        button.setImage(UIImage(systemName: "gear"), for: .normal)
        button.imageView?.tintColor = .white
        
        return button
    }()
    
    private var alternateDocksBikesButton: UIButton = {

        let button = NBButton()
        button.applyProtocolUIAppearance()
        button.accessibilityIdentifier = "SETTINGS"
        button.accessibilityLabel = NSLocalizedString("SETTINGS_ACCESIBILITY_BUTTON", comment: "")
        button.setImage(UIImage(systemName: "circle"), for: .normal)
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
        
        activeRentalScrollView.addSubview(activeRentalStackView)
        mapView.addSubview(activeRentalScrollView)

        view.addSubview(statisticsAndGraphViewStackView)
        view.bringSubviewToFront(statisticsAndGraphViewStackView)
        view.addSubview(bottomButtonsStackView)
        
        view.addSubview(blurAlertView)
        view.bringSubviewToFront(blurAlertView)

        // MARK: Settings Button constraints

        // Align to the bottom right
        NSLayoutConstraint.activate([
            bottomButtonsStackView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -2 * Constants.spacing),
            bottomButtonsStackView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -2 * Constants.spacing)
        ])
        
        // MARK: Active Rentals
        NSLayoutConstraint.activate([
            activeRentalScrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16.0),
            activeRentalScrollView.trailingAnchor.constraint(equalTo: bottomButtonsStackView.leadingAnchor, constant: -16.0),
            activeRentalScrollView.heightAnchor.constraint(equalToConstant: 100.0),
            activeRentalScrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 16.0)
        ])
        
        NSLayoutConstraint.activate([
//            activeRentalScrollView.heightAnchor.constraint(equalTo: self.view.heightAnchor, constant: self.activeRentalScrollView.frame.height - 16.0)
        ])
        
        NSLayoutConstraint.activate([
            activeRentalStackView.topAnchor.constraint(equalTo: activeRentalScrollView.topAnchor, constant: 0.0),
            activeRentalStackView.trailingAnchor.constraint(equalTo: activeRentalScrollView.trailingAnchor, constant: 0),
            activeRentalStackView.leadingAnchor.constraint(equalTo: activeRentalScrollView.leadingAnchor, constant: 0),
            activeRentalStackView.bottomAnchor.constraint(equalTo: activeRentalScrollView.bottomAnchor, constant: 0)
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
        
        NSLayoutConstraint.activate([
            blurAlertView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            blurAlertView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
        
//        blurAlertView.didMove(toParent: self)


    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        viewModel.viewWillAppear()
        viewModel.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        graphView.clipsToBounds = true
        graphView.layer.cornerRadius = Constants.cornerRadius

        self.hideStackView()
//        viewModel.getCurrentCity(completion: { [weak self] cityResult in
        viewModel.getCurrentCity(completion: { [weak self] cityResult in

            guard let self = self else { fatalError() }

            switch cityResult {

            case .success(let city):
                
                if city.allowsLogIn {
                    self.shouldShowRentBikeButton()
                }

//                self.centerMap(on: cityCoordinates, coordinateSpan: Constants.narrowCoordinateSpan)

            case .error:
                break
            }
        })
    }

    @objc func appMovedToForeground() {
    
//        viewModel.getCurrentCity(completion: { currentCityResult in
        viewModel.getCurrentCity(completion: { currentCityResult in
            switch currentCityResult {

            case .success(let currentCity):
//                self.viewModel.currentCity = currentCity
                self.viewModel.currentCity = currentCity

//                guard let unwrappedCity = self.viewModel.currentCity else { return }
                guard let unwrappedCity = self.viewModel.currentCity else { return }

                self.viewModel.getMapPinsFrom(city: unwrappedCity)
//                self.viewModel.getMapPinsFrom(city: unwrappedCity)

            case .error(let err):
                self.presentAlertViewWithError(title: "Error", body: err.localizedDescription)
                print(err.localizedDescription)
            }
        })
    }

    @objc func appMovedToBackground() {
        print("App moved to Background!")

//        guard let didSelectAnnotation = viewModel.latestSelectedAnnotation else { return }
        guard let didSelectAnnotation = viewModel.latestSelectedAnnotation else { return }

        mapView.deselectAnnotation(didSelectAnnotation, animated: false)
    }

    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(title: "OPEN_SETTINGS_KEYBOARD".localize(file: "Home"), action: #selector(showSettingsViewController), input: "s", modifierFlags: .command, alternates: [], discoverabilityTitle: "OPEN_SETTINGS_KEYBOARD".localize(file: "Home"), attributes: .destructive, state: .on),
            UIKeyCommand(title: "OPEN_INSIGHTS_KEYBOARD".localize(file: "Home"), action: #selector(showSettingsViewController), input: "d", modifierFlags: .command, alternates: [], discoverabilityTitle: "OPEN_INSIGHTS_KEYBOARD".localize(file: "Home"), attributes: .destructive, state: .on)
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
//        viewModel.coordinatorDelegate?.showSettingsViewController()
        viewModel.coordinatorDelegate?.showSettingsViewController()
    }

    @objc func showInsightsViewController() {
//        guard let latestSelectedStation = self.viewModel.latestSelectedBikeStation else { return }
        guard let latestSelectedStation = self.viewModel.latestSelectedBikeStation else { return }
        
//        self.viewModel.selectedRoute(station: latestSelectedStation)
        self.viewModel.selectedRoute(station: latestSelectedStation)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    var cancellable: AnyCancellable?
    var otherCancellable: AnyCancellable?
    var cancellableBag = Set<AnyCancellable>()

    fileprivate func setupBindings() {
        
        settingsButton.publisher(for: .touchUpInside).sink { button in
            
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            LogHelper.logTAppedSettingsButton()
            self.showSettingsViewController()
        }.store(in: &cancellableBag)
        
        insightsButton.publisher(for: .touchUpInside).sink { _ in
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
            self.showInsightsViewController()
        }.store(in: &cancellableBag)
        
        rentButton.publisher(for: .touchUpInside).sink { _ in
//            self.viewModel.startRentProcess()
            self.viewModel.startRentProcess()
        }.store(in: &cancellableBag)
        
        alternateDocksBikesButton.publisher(for: .touchUpInside).sink { _ in
            self.blurAlertView.fadeIn(0.2, onCompletion: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.blurAlertView.fadeOut(0.2)
                })
            })
            
            FeedbackGenerator.sharedInstance.generator.impactOccurred()
                        
            if self.whatsShown == .freeBikes {
                self.whatsShown = .freeDocks
                self.alternateDocksBikesButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
            } else {
                self.whatsShown = .freeBikes
                self.alternateDocksBikesButton.setImage(UIImage(systemName: "circle"), for: .normal)
            }
            
            let stations = self.mapView.annotations
            
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            self.mapView.addAnnotations(stations)
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

            var currentLocationFromDevice = CLLocation()

            switch UITestingHelper.sharedInstance.isUITesting() {
            case true:

//                guard let unwrappedCity = self.viewModel.currentCity else { return }
                guard let unwrappedCity = self.viewModel.currentCity else { return }

                currentLocationFromDevice = CLLocation(latitude: CLLocationDegrees(unwrappedCity.latitude), longitude: CLLocationDegrees(unwrappedCity.longitude))
                
                self.selectClosestAnnotationGraph(stations: stations, currentLocation: currentLocationFromDevice)
            case false:
                break
            }
        })

//        viewModel.stations.bind { stations in
//
//            stations.forEach({ pin in
//
//                let pinCoordinate: CLLocationCoordinate2D = {
//                    let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude),
//                                                            longitude: CLLocationDegrees(pin.longitude))
//                    return coordinate
//                }()
//
//                self.mapView.addAnnotation(MapPin(title: pin.stationName,
//                                                  coordinate: pinCoordinate,
//                                                  stationInformation: pin))
//            })
//
//            var currentLocationFromDevice = CLLocation()
//
//            switch UITestingHelper.sharedInstance.isUITesting() {
//            case true:
//
//                guard let unwrappedCity = self.viewModel.currentCity else { return }
//
//                currentLocationFromDevice = CLLocation(latitude: CLLocationDegrees(unwrappedCity.latitude), longitude: CLLocationDegrees(unwrappedCity.longitude))
//                
//                self.selectClosestAnnotationGraph(stations: stations, currentLocation: currentLocationFromDevice)
//            case false:
//                break
//            }
//        }
        
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
//            if viewModel.latestSelectedAnnotation != nil {
//            mapView.deselectAnnotation(viewModel.latestSelectedAnnotation, animated: false)
            mapView.deselectAnnotation(viewModel.latestSelectedAnnotation, animated: false)
        }
    }

    /// Hide the `PredictionGraphView` pushing the Start commute ubtton up
    func showStackView() {

        FeedbackGenerator.sharedInstance.generator.impactOccurred()
        graphView.fadeIn(0.2)
    }

    func showRoutePlannerButton() {
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
