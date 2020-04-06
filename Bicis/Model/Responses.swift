//
//  Responses.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

struct Key: Codable {

    let apiKey: String
}

struct UserCredentials: Codable {

    let mobile: String
    let pin: String
}

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

struct LogInResponse: Codable {
    let user: UserR?
    let error: LogInResponseError?
}

struct LogInResponseError: Codable {
    let code: Int
    let message: String
}

struct BaseResponse: Codable {
    let serverTime: Int

    enum CodingKeys: String, CodingKey {
        case serverTime = "server_time"
    }
}

struct UserR: Codable {
    let loginkey: String
}

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

struct RentResponse: Codable {

    let base: BaseResponse
    let rental: Rent
}

//struct ApiRoot: Decodable {
//
//    // CityBikes API
//    var newYorkValues: CityBikesElements?
//
//    // NextBike API
//    var nextBikeValues: [CountriesNextBike]?
//
//    private enum CityBikesKeys: String, CodingKey {
//        case newYorkValues = "network"
//    }
//
//    private enum NextBikeKeys: String, CodingKey {
//        case nextBikeValues = "countries"
//    }
//
//    init(from decoder: Decoder) throws {
//
//        let values = try decoder.container(keyedBy: NextBikeKeys.self)
//
//        if let valos = try values.decodeIfPresent([CountriesNextBike].self, forKey: .nextBikeValues) {
//            nextBikeValues = valos
//        } else {
//            let cityBikesValues = try decoder.container(keyedBy: CityBikesKeys.self)
//
//            if let valis = try cityBikesValues.decodeIfPresent(CityBikesElements.self, forKey: .newYorkValues) {
//                newYorkValues = valis
//            }
//        }
//    }
//
//}





struct BikeList: Codable {

    let number: String
}

/**


 */
struct GetActiveRentalsResponse: Codable {
    let rentalCollection: [RentalCollection]
}

struct RentalCollection: Codable {
    let showCloseLockInfo: Bool
    let startPlaceName: String

    enum CodingKeys: String, CodingKey {
        case showCloseLockInfo = "show_close_lock_info"
        case startPlaceName = "start_place_name"
    }
}

// MY API

struct MyAPIResponse: Codable {
    let values: [String: Int]
}

struct MyAllAPIResponseItem: Codable {
    let today: [String: Int]
    let prediction: [String: Int]
}

/// Endpoint: https:://javierdemart.in/api/v1/all/STATION_ID
struct MyAllAPIResponse: Codable {
    let values: MyAllAPIResponseItem
    let discharges: [String]
    let refill: [String]
}
