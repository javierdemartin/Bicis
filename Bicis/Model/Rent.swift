//
//  Rent.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

struct Rent: Codable {

    let apikey: String
    let bike: String
    let loginkey: String
    let showErrors: Int

    enum CodingKeys: String, CodingKey {
        case showErrors = "show_errors"
        case apikey
        case bike
        case loginkey
    }
}
