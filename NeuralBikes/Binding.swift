//
//  Binding.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 14/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

class Binding<T> {

    var value: T {
        didSet {
            listener?(value)
        }
    }
    private var listener: ((T) -> Void)?
    init(value: T) {
        self.value = value
    }
    func bind(_ closure: @escaping (T) -> Void) {
        closure(value)
        listener = closure
    }
}
