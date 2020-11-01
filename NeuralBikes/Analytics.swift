//
//  Analytics.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 31/10/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

struct Counter {
    func hit(_ option: CounterOption) {
        
        // TODO: Change to correct key
        guard let url = URL(string: "https://api.countapi.xyz/hit/placeholder/\(option.rawValue)") else { return }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    }
    
    enum CounterOption: String {
        case settings
    }
}
