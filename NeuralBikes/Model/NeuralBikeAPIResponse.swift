//
//  MyAPIResponse.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

/// Endpoint: https:://javierdemart.in/api/v1/all/STATION_ID
struct NeuralBikeAllAPIResponse: Codable {
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            today = try container.decode([String:Int].self, forKey: .today)
        } catch DecodingError.valueNotFound {
            today = [:]
        }
        
        do {
            prediction = try container.decode([String:Int].self, forKey: .prediction)
        } catch DecodingError.valueNotFound {
            prediction = [:]
        }
    }
}
