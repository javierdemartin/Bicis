//
//  RoutePlannerTimerServices.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 11/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UserNotifications

class RoutePlannerTimerServices {

    static let sharedInstance: RoutePlannerTimerServices = {

        let instance = RoutePlannerTimerServices()
        return instance
    }()

    var internalTimer: Timer?
    var numberOfTimesLeft: Int = 0

    init() {

    }

    func startTimer() {

        guard self.internalTimer == nil else {
            return
        }

        self.internalTimer = Timer.scheduledTimer(timeInterval: 5.0 /*seconds*/, target: self, selector: #selector(fireTimerAction), userInfo: nil, repeats: true)

        print("Timer has started...")
    }

    func stopTimer(){
        guard self.internalTimer != nil else {
            fatalError("No timer active, start the timer before you stop it.")
        }
        self.internalTimer?.invalidate()
        self.internalTimer = nil
    }

    @objc func fireTimerAction(sender: AnyObject?) {
        debugPrint("Timer Fired! \(sender)")
    }

}
