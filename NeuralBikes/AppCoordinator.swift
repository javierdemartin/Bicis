//
//  AppCoordinator.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit
import ReactiveSwift
import SwiftUI
import CoreLocation

class AppCoordinator: Coordinator {

    let window: UIWindow

    var dismissingSettingsViewController = false

    lazy var localDataManager: LocalDataManager = {
        return DefaultLocalDataManager()
    }()

    lazy var remoteDataManager: RemoteDataManager = {
        return DefaultRemoteDataManager()
    }()
    
    lazy var bikeServicesDataManager: BikeServicesDataManager = {
       return NextBikeBikeServicesDataManager()
    }()

    lazy var dataManager: DataManager = {
        return DataManager(localDataManager: self.localDataManager, remoteDataManager: self.remoteDataManager, bikeServicesDataManager: bikeServicesDataManager)
    }()
    
    lazy var locationService: LocationServiceable = {
       return LocationServiceCoreLocation()
    }()
    
    var scannerViewModel: ScannerViewModel?

    init(window: UIWindow) {
        self.window = window
    }

    override func start() {

        if UITestingHelper.sharedInstance.isUITesting() {
            currentCity = availableCities["Madrid"]
            localDataManager.saveCurrentCity(apiCityName: availableCities["Madrid"]!, completion: { _ in })
            showHomeViewController()

        } else {

            localDataManager.getCurrentCity { (getCurrentCityResult) in

                switch getCurrentCityResult {
                case .success(let suc):
                    self.currentCity = suc

                    self.showHomeViewController()
                case .error(let err):
                    print(err.localizedDescription)

                    self.showHomeViewController()
                    self.presentModallySettingsViewController()
                }
            }
        }
    }

    override func finish() {

    }

    var homeViewModel: HomeViewModel?
    var homeViewController: HomeViewController?
    var currentCity: City?

    var routePlannerViewController: InsightsViewController?
    
    fileprivate func showHomeViewController() {

        let compositeDisposable = CompositeDisposable()
        homeViewModel = HomeViewModel(city: currentCity ?? nil, compositeDisposable: compositeDisposable, dataManager: dataManager, locationService: locationService)
        homeViewController = HomeViewController(viewModel: homeViewModel!, compositeDisposable: compositeDisposable)
        self.window.rootViewController = homeViewController

        homeViewModel!.coordinatorDelegate = self
        homeViewModel!.delegate = homeViewController
        UIView.transition(with: window, duration: 0.3, options: [UIView.AnimationOptions.transitionCrossDissolve], animations: {}, completion: nil)
        window.makeKeyAndVisible()
    }

    var settingsViewController: SettingsViewController?
    var logInViewController: LogInViewController?

    fileprivate func presentModallySettingsViewController() {

        let compositeDisposable = CompositeDisposable()
        let settingsViewModel = SettingsViewModel(currentCity: currentCity ?? nil, compositeDisposable: compositeDisposable, dataManager: dataManager)

        settingsViewController = SettingsViewController(viewModel: settingsViewModel, compositeDisposable: compositeDisposable)

        settingsViewController?.reactive.trigger(for: #selector(settingsViewController?.viewDidDisappear(_:))).observe { _ in self.handleModalDismissed() }

        settingsViewModel.coordinatorDelegate = self
        settingsViewModel.delegate = settingsViewController
        settingsViewController?.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(settingsViewController!, animated: true, completion: nil)
    }

    fileprivate func handleModalDismissed() {

        localDataManager.getCurrentCity(completion: { getCurrentCityResult in
            switch getCurrentCityResult {

            case .success(let suc):
                self.homeViewModel?.currentCity = suc

            case .error:
                break
            }
        })
    }
}

extension AppCoordinator: ScannerViewModelCoordinatorDelegate {
    func scannedCodeWith(number: Int?) {
        homeViewModel?.finishRentProcess(bike: number)
    }
}

extension AppCoordinator: RestorePurchasesViewModelCoordinatorDelegate {
    func reParseMainFeedShowingNewColors() {

        localDataManager.getCurrentCity(completion: { cityResult in

            switch cityResult {

            case .success(let city):
                self.homeViewModel?.getMapPinsFrom(city: city)
            case .error:
                break
            }
        })
    }
}

extension AppCoordinator: SettingsViewModelCoordinatorDelegate {
    
    func dismissSettingsViewController() {
        DispatchQueue.main.async {
            self.settingsViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func presentRestorePurchasesViewControllerFromCoordinatorDelegate() {

        self.settingsViewController?.dismiss(animated: true, completion: nil)

        let compositeDisposable = CompositeDisposable()
        let restorePurchasesViewModel = RestorePurchasesViewModel(compositeDisposable: compositeDisposable)
        restorePurchasesViewModel.coordinatorDelegate = self
        let restorePurchasesViewController = RestorePurchasesViewController(compositeDisposable: compositeDisposable, viewModel: restorePurchasesViewModel)

        restorePurchasesViewController.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(restorePurchasesViewController, animated: true, completion: nil)
    }

    // Re-centers the map when the UIPickerView changes value
    func changedCitySelectionInPickerView(city: City) {

        homeViewModel?.removeAnnotationsFromMap()
        
        if city.allowsLogIn {
            homeViewModel?.delegate?.shouldShowRentBikeButton()
        } else {
            homeViewModel?.delegate?.shouldHideRentBikeButton()
        }

        print("Selected from coordinator \(city.formalName)")

        guard let homeViewModel = homeViewModel else { return }

        let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude))

        homeViewModel.delegate?.centerMap(on: centerCoordinates, coordinateSpan: Constants.wideCoordinateSpan)

        homeViewModel.stations.value = []
        homeViewModel.stationsDict.value = [:]

        homeViewModel.dataManager.getStations(city: city.formalName, completion: { resultStations in

            switch resultStations {

            case .success(let res):

                res.forEach({ individualStation in
                    self.homeViewModel?.stationsDict.value[individualStation.stationName] = individualStation
                })

                self.homeViewModel?.stations.value = res
            case .error:
                break
            }
        })
    }
}

extension AppCoordinator: InsightsViewModelCoordinatorDelegate {

    /// Dismisses the UIViewController presented after starting the commute
    func dismissModalRoutePlannerViewController() {

        DispatchQueue.main.async {
            self.routePlannerViewController?.dismiss(animated: true, completion: nil)
        }
    }

    /// Send the route between the user's current location to the destination station to be drawn on the map
    func sendSelectedDestinationToHomeViewController(station: BikeStation) {
        homeViewModel?.destinationStation.value = station
    }
}

extension AppCoordinator: LogInVieWModelCoordinatorDelegate {
    func dismissViewController() {
        DispatchQueue.main.async {
            self.logInViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension AppCoordinator: HomeViewModelCoordinatorDelegate {
    func presentScannerViewController() {
        let compositeDisposable = CompositeDisposable()
        scannerViewModel = ScannerViewModel(compositeDisposable: compositeDisposable)
        let scannerViewController = ScannerViewController(compositeDisposable: compositeDisposable, viewModel: scannerViewModel!)
        
        scannerViewModel?.delegate = scannerViewController
        scannerViewModel?.coordinatorDelegate = self
        scannerViewController.modalPresentationStyle = .formSheet
        self.window.rootViewController?.present(scannerViewController, animated: true, completion: nil)
    }
    
    func presentLogInViewController() {
        let compositeDisposable = CompositeDisposable()
        let logInViewModel = LogInViewModel(compositeDisposable: compositeDisposable, dataManager: dataManager)
        logInViewController = LogInViewController(compositeDisposable: compositeDisposable, viewModel: logInViewModel)
        logInViewModel.delegate = logInViewController
        logInViewModel.coordinatorDelegate = self
        logInViewController!.modalPresentationStyle = .formSheet
        self.window.rootViewController?.present(logInViewController!, animated: true, completion: nil)
    }
    
    /// Presents the UIViewController in charge of planning the route to the destination station
    func modallyPresentRoutePlannerWithRouteSelected(stationsDict: BikeStation, closestAnnotations: [BikeStation]) {

        let compositeDisposable = CompositeDisposable()
        
        let routePlannerViewModel = InsightsViewModel(compositeDisposable: compositeDisposable, locationService: locationService, dataManager: dataManager, destinationStation: stationsDict)
   
        let swiftUIView = InsightsSwiftUIView(viewModel: routePlannerViewModel)
        let viewCtrl = UIHostingController(rootView: swiftUIView)


//        let routePlannerViewModel = InsightsViewModel(compositeDisposable: compositeDisposable, dataManager: dataManager, stationsDict: nil, closestAnnotations: closestAnnotations, destinationStation: stationsDict)
//        routePlannerViewModel.coordinatorDelegate = self
//        routePlannerViewController = InsightsViewController(viewModel: routePlannerViewModel, compositeDisposable: compositeDisposable)
//        routePlannerViewModel.delegate = routePlannerViewController!
//
//        routePlannerViewController!.modalPresentationStyle = .formSheet
        
        viewCtrl.modalPresentationStyle = .formSheet

//        self.window.rootViewController?.present(routePlannerViewController!, animated: true, completion: nil)
        self.window.rootViewController?.present(viewCtrl, animated: true, completion: nil)
    }

    func showSettingsViewController() {
        presentModallySettingsViewController()
    }
}
