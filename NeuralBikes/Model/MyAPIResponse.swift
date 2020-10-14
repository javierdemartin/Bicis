//
//  MyAPIResponse.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

/// Endpoint: https:://javierdemart.in/api/v1/all/STATION_ID
struct MyAllAPIResponse: Codable {
    let values: MyAllAPIResponseItem
    let discharges: [String]
    let refill: [String]
}

struct MyAPIResponse: Codable {
    let values: [String: Int]
}

struct MyAllAPIResponseItem: Codable {
    let today: [String: Int]
    let prediction: [String: Int]
    
    
}
