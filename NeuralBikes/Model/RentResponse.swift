//
//  RentResponse.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

struct RentResponse: Codable {

    let serverTime: Int
    let error: LogInResponseError?
    
    enum CodingKeys: String, CodingKey {
        case serverTime = "server_time"
        case error = "error"
    }
}

