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

    func isUITesting() -> Bool {
        return ProcessInfo.processInfo.arguments.contains("is_ui_testing")
    }

    override func start() {

        if isUITesting() {
            guard let selectedCity = availableCities["Bilbao"] else { return }
            currentCity = availableCities["Bilbao"]
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
    var currentCity: City?

    fileprivate func showHomeViewController() {

        let compositeDisposable = CompositeDisposable()
        homeViewModel = HomeViewModel(city: currentCity ?? nil, compositeDisposable: compositeDisposable, dataManager: dataManager)
        let homeViewController = HomeViewController(viewModel: homeViewModel!, compositeDisposable: compositeDisposable)
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

    func handleModalDismissed() {

        localDataManager.getCurrentCity(completion: { getCurrentCityResult in
            switch getCurrentCityResult {

            case .success(let suc):
                self.homeViewModel?.city = suc

            case .error(let err):
                // TODO: Mostrar error
                print(err.localizedDescription)
            }
        })
    }
}

extension AppCoordinator: SettingsViewModelCoordinatorDelegate {

    // Re-centers the map when the UIPickerView changes value
    func changedCitySelectionInPickerView(city: City) {

        homeViewModel?.removeAnnotationsFromMap()

        print("Selected from coordinator \(city.formalName)")

        guard let homeViewModel = homeViewModel else { return }

        let centerCoordinates = CLLocationCoordinate2D(latitude: CLLocationDegrees(city.latitude), longitude: CLLocationDegrees(city.longitude))

        homeViewModel.delegate?.centerMap(on: centerCoordinates)

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

extension AppCoordinator: HomeViewModelCoordinatorDelegate {

    func didTapRestart() {

    }

    func showSettingsViewController() {
        presentModallySettingsViewController()
    }
}
