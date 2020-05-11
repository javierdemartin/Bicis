//
//  BaseResponse.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

struct BaseResponse: Codable {
    let serverTime: Int

    enum CodingKeys: String, CodingKey {
        case serverTime = "server_time"
    }
}
