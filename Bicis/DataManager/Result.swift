//
//  Result.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case error(Error)
}
