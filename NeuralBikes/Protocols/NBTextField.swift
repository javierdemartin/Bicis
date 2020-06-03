//
//  NBTextField.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension NBButtonable where Self: UITextField {}

class NBTextField: UITextField, NBButtonable {
    func applyProtocolUIAppearance() {
        layer.borderWidth = 1.2
        borderStyle = .roundedRect
        layer.masksToBounds = true
        layer.cornerRadius = 5.0
        backgroundColor = .clear
        text = ""
        layer.borderColor = UIColor.systemGray.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        adjustsFontForContentSizeCategory = true
        font = UIFont.preferredFont(forTextStyle: .body)
    }
}
