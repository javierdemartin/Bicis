//
//  RestorePurchasesViewModel.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 15/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import ReactiveSwift

protocol RestorePurchasesViewModelDelegate: class {
    func celebratePurchase()
}

protocol RestorePurchasesViewModelCoordinatorDelegate: class {
    func reParseMainFeedShowingNewColors()
}

class RestorePurchasesViewModel: NSObject {

    let compositeDisposable: CompositeDisposable

    weak var delegate: RestorePurchasesViewModelDelegate?
    weak var coordinatorDelegate: RestorePurchasesViewModelCoordinatorDelegate?

    var hasPurchased = Binding<Bool>(value: false)

    func unlockDataInsights() {

        StoreKitProducts.store.requestProducts({ [weak self] success, products in

            guard let self = self else { return }

            if success {
                dump(products)

                guard let products = products else { return }

                let foundProduct = products.first(where: { $0.productIdentifier == StoreKitProducts.DataInsights })

                NotificationCenter.default.addObserver(self, selector: #selector(self.didSuccessfullyFinishStoreKitOperation), name: .IAPHelperPurchaseNotification, object: nil)

                StoreKitProducts.store.buyProduct(foundProduct!)
            }
        })
    }

    @objc func didSuccessfullyFinishStoreKitOperation() {

        coordinatorDelegate?.reParseMainFeedShowingNewColors()
        delegate?.celebratePurchase()
    }

    func restorePurchases() {

        NotificationCenter.default.addObserver(self, selector: #selector(didSuccessfullyFinishStoreKitOperation), name: .IAPHelperPurchaseNotification, object: nil)

        StoreKitProducts.store.restorePurchases()
    }

    init(compositeDisposable: CompositeDisposable) {
        self.compositeDisposable = compositeDisposable

        super.init()

        setUpBindings()
    }

    func setUpBindings() {

        hasPurchased.value = StoreKitProducts.store.isProductPurchased(StoreKitProducts.DataInsights)
    }
}
