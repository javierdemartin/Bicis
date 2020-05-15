//
//  NBTextView.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 15/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

extension NBButtonable where Self: UITextView {}

class NBTextView: UITextView, NBButtonable {
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyProtocolUIAppearance() {
        isScrollEnabled = false
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isSelectable = false
        isEditable = false
        isUserInteractionEnabled = true
        isScrollEnabled = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
//        textColor = UIColor(hex: downloadedTheme?.fontColor ?? "") ?? UIColor.white
        font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
    }
}
