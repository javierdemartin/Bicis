//
//  ScannerViewModel.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 14/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation


protocol ScannerViewModelCoordinatorDelegate: class {
    func scannedCodeWith(number: Int?)
}

protocol ScannerViewModelDelegate: class {
    
}

class ScannerViewModel {
    
    weak var delegate: ScannerViewModelDelegate?
    weak var coordinatorDelegate: ScannerViewModelCoordinatorDelegate?
    
    init() {
        
    }
    
    func scannedCode(number: Int?) {
        self.coordinatorDelegate?.scannedCodeWith(number: number)
    }
}
