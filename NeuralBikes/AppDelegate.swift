//
//  AppDelegate.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 02/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    lazy var appCoordinator: AppCoordinator = {
        guard let window = self.window else { fatalError() }
        let coordinator = AppCoordinator(window: window)
        return coordinator
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        StoreKitHelper.incrementNumberOfTimesLaunched()

        appCoordinator.start()

        return true
    }

    private func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
}
