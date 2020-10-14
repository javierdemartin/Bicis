//
//  AppCoordinator.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit
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
                    
                    self.presenTutorialViewController()
                }
            }
        }
    }

    override func finish() {

    }

    var homeViewModel: HomeViewModel?
    var homeViewController: HomeViewController?
    var currentCity: City?
    
    fileprivate func showHomeViewController() {

        homeViewModel = HomeViewModel(city: currentCity ?? nil, dataManager: dataManager, locationService: locationService)
        homeViewController = HomeViewController(viewModel: homeViewModel!)
        self.window.rootViewController = homeViewController

        homeViewModel!.coordinatorDelegate = self
        homeViewModel!.delegate = homeViewController
        UIView.transition(with: window, duration: 0.3, options: [UIView.AnimationOptions.transitionCrossDissolve], animations: {}, completion: nil)
        window.makeKeyAndVisible()
    }

    var settingsViewController: UIHostingController<SettingsViewControllerSwiftUI>? // SettingsViewController?
    var logInViewController: LogInViewController?

    fileprivate func presentModallySettingsViewController() {

        let settingsViewModel = SettingsViewModel(currentCity: currentCity ?? nil, locationService: locationService, dataManager: dataManager)

        

        settingsViewModel.coordinatorDelegate = self
//        settingsViewModel.delegate = settingsViewController
        
        
        settingsViewController = UIHostingController(rootView: SettingsViewControllerSwiftUI(viewModel: settingsViewModel)) //<SettingsViewControllerSwiftUI>() //SettingsViewController(viewModel: settingsViewModel)
        
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

extension AppCoordinator: SettingsViewModelCoordinatorDelegate {
    
    func dismissSettingsViewController() {
        DispatchQueue.main.async {
            self.settingsViewController?.dismiss(animated: true, completion: nil)
        }
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

//        homeViewModel.stations.value = []
        homeViewModel.stations = []
        homeViewModel.stationsDictCombine = [:]
//        homeViewModel.stationsDict.value = [:]

        homeViewModel.dataManager.getStations(city: city.formalName, completion: { resultStations in

            switch resultStations {

            case .success(let res):

                res.forEach({ individualStation in
                    self.homeViewModel?.stationsDict.value[individualStation.stationName] = individualStation
                })

                self.homeViewModel?.stations = res
//                self.homeViewModel?.stations.value = res
            case .error:
                break
            }
        })
    }
}

extension AppCoordinator: LogInVieWModelCoordinatorDelegate {
    func dismissViewController() {
        DispatchQueue.main.async {
            self.logInViewController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension AppCoordinator: TutorialViewModelCoordinatorDelegate {
    func didTapFinishTutorial() {
        showHomeViewController()
    }
}

extension AppCoordinator: HomeViewModelCoordinatorDelegate {
    func presentScannerViewController() {
        scannerViewModel = ScannerViewModel()
        let scannerViewController = ScannerViewController(viewModel: scannerViewModel!)
        
        scannerViewModel?.delegate = scannerViewController
        scannerViewModel?.coordinatorDelegate = self
        scannerViewController.modalPresentationStyle = .formSheet
        self.window.rootViewController?.present(scannerViewController, animated: true, completion: nil)
    }
    
    func presentLogInViewController() {
        let logInViewModel = LogInViewModel(dataManager: dataManager)
        logInViewController = LogInViewController(viewModel: logInViewModel)
        logInViewModel.delegate = logInViewController
        logInViewModel.coordinatorDelegate = self
        logInViewController!.modalPresentationStyle = .formSheet
        self.window.rootViewController?.present(logInViewController!, animated: true, completion: nil)
    }
    
    func presenTutorialViewController() {
        
        
        let tutorialViewModel = TutorialViewModel()
        tutorialViewModel.coordinatorDelegate = self
        
        let swiftUIView = TutorialViewController(viewModel: tutorialViewModel)
        let viewCtrl = UIHostingController(rootView: swiftUIView)
        
        self.window.rootViewController = viewCtrl

        UIView.transition(with: window, duration: 0.3, options: [UIView.AnimationOptions.transitionCrossDissolve], animations: {}, completion: nil)
        window.makeKeyAndVisible()
    }
    
    /// Presents the UIViewController in charge of planning the route to the destination station
    func modallyPresentRoutePlannerWithRouteSelected(stationsDict: BikeStation, closestAnnotations: [BikeStation]) {
        
        let routePlannerViewModel = InsightsViewModel(locationService: locationService, dataManager: dataManager, destinationStation: stationsDict)
   
        let swiftUIView = InsightsViewController(viewModel: routePlannerViewModel)
        let viewCtrl = UIHostingController(rootView: swiftUIView)
        
        viewCtrl.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(viewCtrl, animated: true, completion: nil)
    }

    func showSettingsViewController() {
        presentModallySettingsViewController()
    }
}
