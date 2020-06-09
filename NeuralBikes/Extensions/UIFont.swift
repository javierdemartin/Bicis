//
//  UIFont.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 30/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    static func preferredFont(for style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
//        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)
        
        // Here we get San Francisco with the desired weight
        let systemFont = UIFont.systemFont(ofSize: desc.pointSize, weight: weight)

        // Will be SF Compact or standard SF in case of failure.
        let font: UIFont

        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: desc.pointSize)
        } else {
            font = systemFont
        }
        
        return metrics.scaledFont(for: font)
    }
}
