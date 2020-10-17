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

    var currentCity: City?

    lazy var localDataManager: LocalDataManager = {
        return DefaultLocalDataManager()
    }()

    lazy var remoteDataManager: RemoteDataManager = {
        return DefaultRemoteDataManager()
    }()
    
    

    lazy var dataManager: DataManager = {
        return DataManager(localDataManager: self.localDataManager, remoteDataManager: self.remoteDataManager)
    }()
    
    lazy var locationService: LocationServiceable = {
       return LocationServiceCoreLocation()
    }()

    init(window: UIWindow) {
        self.window = window
    }

    override func start() {

        if UITestingHelper.sharedInstance.isUITesting() {
            
            if let uiTestingCity = UITestingHelper.sharedInstance.isForceFeedingCity() {
                currentCity = uiTestingCity
                localDataManager.saveCurrentCity(apiCityName: uiTestingCity, completion: { _ in })
            }
            
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

    var homeViewModel: HomeViewModel?
        
    fileprivate func showHomeViewController() {
        
        homeViewModel = HomeViewModel(city: currentCity ?? nil, dataManager: dataManager, locationService: locationService)
        let homeViewController = HomeViewController(viewModel: homeViewModel!)
        self.window.rootViewController = homeViewController

        homeViewModel!.coordinatorDelegate = self
        homeViewModel!.delegate = homeViewController
        UIView.transition(with: window, duration: 0.3, options: [UIView.AnimationOptions.transitionCrossDissolve], animations: {}, completion: nil)
        window.makeKeyAndVisible()
    }

    var settingsViewController: UIHostingController<SettingsViewControllerSwiftUI>?

    fileprivate func presentModallySettingsViewController() {

        let settingsViewModel = SettingsViewModel(currentCity: currentCity ?? nil, locationService: locationService, dataManager: dataManager)

        settingsViewModel.coordinatorDelegate = self
        
        settingsViewController = UIHostingController(rootView: SettingsViewControllerSwiftUI(viewModel: settingsViewModel))
        
        settingsViewController?.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(settingsViewController!, animated: true, completion: nil)
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
        
        print("Selected from coordinator \(city.formalName)")

        guard let homeViewModel = homeViewModel else { return }

        let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude))

        homeViewModel.delegate?.centerMap(on: centerCoordinates, coordinateSpan: Constants.wideCoordinateSpan)

        homeViewModel.stations = []
        homeViewModel.stationsDictCombine = [:]

        homeViewModel.dataManager.getStations(city: city.formalName, completion: { resultStations in

            switch resultStations {

            case .success(let res):

                res.forEach({ individualStation in
                    self.homeViewModel?.stationsDict.value[individualStation.stationName] = individualStation
                })

                self.homeViewModel?.stations = res
            case .error:
                break
            }
        })
    }
}

extension AppCoordinator: TutorialViewModelCoordinatorDelegate {
    func didTapFinishTutorial() {
        showHomeViewController()
    }
}

extension AppCoordinator: HomeViewModelCoordinatorDelegate {
    
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
        let viewController = UIHostingController(rootView: swiftUIView)
        
        viewController.modalPresentationStyle = .formSheet

        self.window.rootViewController?.present(viewController, animated: true, completion: nil)
    }

    func showSettingsViewController() {
        presentModallySettingsViewController()
    }
}
