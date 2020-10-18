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
        
        neuralbikes_open(url: url)
    }
    
    static func sendToTwitter(profile: String) {
        guard let url = URL(string: "https://twitter.com/\(profile)") else { return }
        
        neuralbikes_open(url: url)
    }
    
    static func sendToPrivacyPolicy() {
        guard let url = URL(string: "https://neuralbike.app/privacy") else { return }
        
        neuralbikes_open(url: url)
    }
    
    static func sendToWeb() {
        guard let url = URL(string: "https://neuralbike.app") else { return }
        
        neuralbikes_open(url: url)
    }
}


func neuralbikes_open(url: URL) {
    DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
