//
//  NBGradient.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 18/06/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension NBButtonable where Self: CAGradientLayer {}

class CAGradient: CAGradientLayer, NBButtonable {
    
    override init(layer: Any) {
        super.init(layer: layer)
        
        needsDisplayOnBoundsChange = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyProtocolUIAppearance() {
                
//        let initial = UIColor.white.cgColor
//        let middle = UIColor.systemFill.cgColor
//        let final = UIColor.white.cgColor
//
//        colors = [initial, middle, final]
//        locations = [0.0, 0.5, 1.0]
//        startPoint = CGPoint(x: 0.0, y: 0.0)
//        endPoint = CGPoint(x: 0.5, y: 1)
        
        // Add Border
//        let layer: CALayer? = self.lay
//        layer?.cornerRadius = 8.0
//        layer?.masksToBounds = true
//        layer?.borderWidth = 1.0
//        layer?.borderColor = UIColor(white: 0.5, alpha: 0.2).cgColor
//
//        // Add Shine
//        let shineLayer = CAGradientLayer()
//        shineLayer.frame = layer?.bounds ?? CGRect.zero
//        shineLayer.colors = [UIColor(white: 1.0, alpha: 0.4).cgColor, UIColor(white: 1.0, alpha: 0.2).cgColor, UIColor(white: 0.75, alpha: 0.2).cgColor, UIColor(white: 0.4, alpha: 0.2).cgColor, UIColor(white: 1.0, alpha: 0.4).cgColor]
//        shineLayer.locations = [NSNumber(value: 0.0), NSNumber(value: 0.5), NSNumber(value: 0.5), NSNumber(value: 1.0), NSNumber(value: 1.0)]
//        layer?.addSublayer(shineLayer)
    }
}

