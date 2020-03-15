//
//  RestorePurchasesViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 15/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift


class RestorePurchasesViewModel: NSObject {

    let compositeDisposable: CompositeDisposable

    init(compositeDisposable: CompositeDisposable) {
        self.compositeDisposable = compositeDisposable

        super.init()

        setUpBindings()


    }

    func setUpBindings() {

    }
}
