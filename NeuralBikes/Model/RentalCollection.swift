//
//  RentalCollection.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

struct RentalCollection: Codable {
    let showCloseLockInfo: Bool
    let startPlaceName: String
    let bike: String
    let lockCode: String

    enum CodingKeys: String, CodingKey {
        case showCloseLockInfo = "show_close_lock_info"
        case startPlaceName = "start_place_name"
        case bike = "bike"
        case lockCode = "code"
    }
}
