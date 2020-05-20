//
//  LogInFormData.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 11/05/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

struct LogInFormData: Codable {
    let apikey: String
    let mobile: String
    let pin: String
    let show_errors: Int
    
//    enum CodingKeys: String, CodingKey {
//    case showCloseLockInfo = "show_close_lock_info"
}