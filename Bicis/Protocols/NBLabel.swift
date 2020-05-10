//
//  NBLabel.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 10/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension NBButtonable where Self: UILabel {}

class NBLabel: UILabel, NBButtonable {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyProtocolUIAppearance() {
        translatesAutoresizingMaskIntoConstraints = false
        numberOfLines = 0
        font = Constants.tertiaryFont
    }
}
