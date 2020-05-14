//
//  ScannerViewModel.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 14/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift

protocol ScannerViewModelCoordinatorDelegate: class {
    func scannedCodeWith(number: Int?)
}

protocol ScannerViewModelDelegate: class {
    
}

class ScannerViewModel {
    
    let compositeDisposable: CompositeDisposable
    
    weak var delegate: ScannerViewModelDelegate?
    weak var coordinatorDelegate: ScannerViewModelCoordinatorDelegate?
    
    init(compositeDisposable: CompositeDisposable) {
        self.compositeDisposable = compositeDisposable
    }
    
    func scannedCode(number: Int?) {
        self.coordinatorDelegate?.scannedCodeWith(number: number)
    }
}
