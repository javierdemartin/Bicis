//
//  FeedBackGenerator.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 07/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

class FeedbackGenerator {

    static let sharedInstance: FeedbackGenerator = {
        let instance = FeedbackGenerator()
        return instance
    }()

    let generator = UIImpactFeedbackGenerator(style: .rigid)
}
