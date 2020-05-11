//
//  NBStackView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 10/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension NBButtonable where Self: UIStackView {}

class NBStackView: UIStackView, NBButtonable {
    
    func applyProtocolUIAppearance() {
        translatesAutoresizingMaskIntoConstraints = false
        spacing = 5.0
        layoutMargins = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        isLayoutMarginsRelativeArrangement = true
        alignment = .center
        distribution  = .equalCentering
    }
}
