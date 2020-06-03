//
//  DataObserverProducer.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 23/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import RxSwift

protocol DataObserverProducer {
    var publishSubject: PublishSubject<[BikeStation]> { get set }
}
