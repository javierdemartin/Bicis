//
//  RoutePlannerTableViewCell.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 11/03/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation
import UIKit

class RoutePlannerTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: "cell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
