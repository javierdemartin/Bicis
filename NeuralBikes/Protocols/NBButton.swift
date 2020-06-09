//
//  MyButton.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 26/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

protocol NBButtonable {
    
    func applyProtocolUIAppearance()
}

extension NBButtonable where Self: UIButton {}

class NBButton: UIButton, NBButtonable {
    
    func applyProtocolUIAppearance() {
        backgroundColor = .systemBlue
        layer.cornerRadius = Constants.cornerRadius
        isUserInteractionEnabled = true
        isEnabled = true
        clipsToBounds = true
        titleLabel?.adjustsFontForContentSizeCategory = true
        titleLabel?.font = UIFont.preferredFont(for: .body, weight: .bold)
        
        setTitleColor(UIColor.systemGray4, for: .disabled)
        setTitleColor(.darkGray, for: .highlighted)
        setTitleShadowColor(.darkGray, for: .highlighted)
        setTitleColor(.white, for: .normal)
        translatesAutoresizingMaskIntoConstraints = false
//        titleLabel?.numberOfLines = 0
        imageView?.tintColor = .white
        titleLabel?.textAlignment = .center
        sizeToFit()
        contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        if #available(iOS 13.4, *) {
            let gesture = UIHoverGestureRecognizer(target: self, action: #selector(viewHoverChanged))
            self.addGestureRecognizer(gesture)
            
            let interaction = UIPointerInteraction(delegate: nil)
            self.addInteraction(interaction)
        } else {
            // Fallback on earlier versions
        }
        
        addTarget(self, action: #selector(tapped), for: .touchUpInside)

    }
    
    @objc private func viewHoverChanged(_ gesture: UIHoverGestureRecognizer) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction], animations: {
            switch gesture.state {
            case .began, .changed:
                
                self.layer.transform = CATransform3DMakeScale(1.1, 1.1, 1)
            case .ended:
                self.layer.transform = CATransform3DIdentity
            default: break
            }
        }, completion: nil)
    }
    
    @objc func tapped() {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
       }
}
