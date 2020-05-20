//
//  User.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

struct User: Codable {

    let apikey: String
    let mobile: String
    let pin: String
    let showErrors: Int

    enum CodingKeys: String, CodingKey {
        case apikey = "apiKey"
        case mobile = "mobile"
        case pin = "pin"
        case showErrors = "show_errors"
    }
}
