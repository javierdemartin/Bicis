//
//  UIView.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 12/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    /// Makes the view **appear** with an annimation
    func fadeIn(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
        self.alpha = 0
        self.isHidden = false
        UIView.animate(withDuration: duration!,
                       animations: { self.alpha = 1 },
                       completion: { (_: Bool) in
                          if let complete = onCompletion { complete() }
                       }
        )
    }

    /// Makes the view **dissapear** with an annimation
    func fadeOut(_ duration: TimeInterval? = 0.2, onCompletion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration!,
                       animations: { self.alpha = 0 },
                       completion: { (_: Bool) in
                           self.isHidden = true
                           if let complete = onCompletion { complete() }
                       }
        )
    }
}
