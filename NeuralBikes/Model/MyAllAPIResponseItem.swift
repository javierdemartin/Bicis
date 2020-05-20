//
//  MyAllAPIResponseItem.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

struct MyAllAPIResponseItem: Codable {
    let today: [String: Int]
    let prediction: [String: Int]
}
