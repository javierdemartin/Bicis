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

    lazy var dataManager: DataManager = {
        return DataManager(localDataManager: self.localDataManager, remoteDataManager: self.remoteDataManager)
    }()

    init(window: UIWindow) {
        self.window = window
    }

    override func start() {

        if UITestingHelper.sharedInstance.isUITesting() {
            currentCity = availableCities["New York"]
            localDataManager.saveCurrentCity(apiCityName: availableCities["New York"]!, completion: { _ in })
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

    var routePlannerViewController: RoutePlannerViewController?

    fileprivate func showHomeViewController() {

        let compositeDisposable = CompositeDisposable()
        homeViewModel = HomeViewModel(city: currentCity ?? nil, compositeDisposable: compositeDisposable, dataManager: dataManager)
        homeViewController = HomeViewController(viewModel: homeViewModel!, compositeDisposable: compositeDisposable)
        self.window.rootViewController = homeViewController

        homeViewModel!.coordinatorDelegate = self
        homeViewModel!.delegate = homeViewController
        UIView.transition(with: window, duration: 0.3, options: [UIView.AnimationOptions.transitionCrossDissolve], animations: {}, completion: nil)
        window.makeKeyAndVisible()
    }

    fileprivate func presentModallySettingsViewController() {

        let compositeDisposable = CompositeDisposable()
        let settingsViewModel = SettingsViewModel(currentCity: currentCity ?? nil, compositeDisposable: compositeDisposable, dataManager: dataManager)

        let settingsViewController = SettingsViewController(viewModel: settingsViewModel, compositeDisposable: compositeDisposable)

        settingsViewController.reactive.trigger(for: #selector(settingsViewController.viewDidDisappear(_:))).observe { _ in self.handleModalDismissed() }

        settingsViewModel.coordinatorDelegate = self
        settingsViewModel.delegate = settingsViewController
        settingsViewController.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(settingsViewController, animated: true, completion: nil)
    }

    fileprivate func handleModalDismissed() {

        localDataManager.getCurrentCity(completion: { getCurrentCityResult in
            switch getCurrentCityResult {

            case .success(let suc):
                self.homeViewModel?.city = suc

            case .error:
                break
            }
        })
    }
}

extension AppCoordinator: SettingsViewModelCoordinatorDelegate {
    func presentRestorePurchasesViewControllerFromCoordinatorDelegate() {

        let compositeDisposable = CompositeDisposable()
        let restorePurchasesViewModel = RestorePurchasesViewModel(compositeDisposable: compositeDisposable)
        let restorePurchasesViewController = RestorePurchasesViewController(compositeDisposable: compositeDisposable, viewModel: restorePurchasesViewModel)

        restorePurchasesViewController.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(restorePurchasesViewController, animated: true, completion: nil)
    }

    // Re-centers the map when the UIPickerView changes value
    func changedCitySelectionInPickerView(city: City) {

        homeViewModel?.removeAnnotationsFromMap()

        print("Selected from coordinator \(city.formalName)")

        guard let homeViewModel = homeViewModel else { return }

        let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude))

        homeViewModel.delegate?.centerMap(on: centerCoordinates, coordinateSpan: Constants.wideCoordinateSpan)

        homeViewModel.stations.value = []
        homeViewModel.stationsDict.value = [:]

        // Dismiss the graphview
        homeViewModel.delegate?.dismissGraphView()

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

extension AppCoordinator: RoutePlannerViewModelCoordinatorDelegate {

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

extension AppCoordinator: HomeViewModelCoordinatorDelegate {

    /// Presents the UIViewController in charge of planning the route to the destination station
    func modallyPresentRoutePlannerWithRouteSelected(stationsDict: BikeStation) {

        let compositeDisposable = CompositeDisposable()
        let routePlannerViewModel = RoutePlannerViewModel(compositeDisposable: compositeDisposable, dataManager: dataManager, stationsDict: nil, destinationStation: stationsDict)
        routePlannerViewModel.coordinatorDelegate = self
        routePlannerViewController = RoutePlannerViewController(viewModel: routePlannerViewModel, compositeDisposable: compositeDisposable)

        routePlannerViewController!.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(routePlannerViewController!, animated: true, completion: nil)
    }

    func showSettingsViewController() {
        presentModallySettingsViewController()
    }
}
