//
//  NBActions.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 06/10/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

struct NBActions {
    static func sendToMail() {
        
        guard let url = URL(string: "mailto:javierdemartin@me.com") else { return }
        
        phr_open(url: url)
    }
    
    static func sendToTwitter() {
        guard let url = URL(string: "https://twitter.com/javierdemartin") else { return }
        
        phr_open(url: url)
    }
}


func phr_open(url: URL) {
    DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
