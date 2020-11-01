//
//  GBFS.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 19/06/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

// Station information

struct GbfsStationInformation: Codable {
    var data: GbfsStationStatusDataInformation
    
}

struct GbfsStationStatusDataInformation: Codable {
    var stations: [GbfsStationStatusInformation]
}

struct GbfsStationStatusInformation: Codable {
    var stationId: String
    var latitude: Double
    var longitude: Double
    var stationName: String
    
    enum CodingKeys: String, CodingKey {
        case stationId = "station_id"
        case latitude = "lat"
        case longitude = "lon"
        case stationName = "name"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        stationName = try container.decode(String.self, forKey: .stationName)
        
        do {
            stationId = "\(try container.decode(Int.self, forKey: .stationId))"
        } catch DecodingError.typeMismatch {
            stationId = try container.decode(String.self, forKey: .stationId)
        }
    }
}

// Station staus

struct GbfsStationStatus: Codable {
    var data: GbfsStationStatusData
}

struct GbfsStationStatusData: Codable {
    var stations: [GbfsStationStatusStation]
}

struct GbfsStationStatusStation: Codable {
    var stationId: String
    var numberOfBikesAvailable: Int
    var numberOfDocksAvailable: Int
    
    enum CodingKeys: String, CodingKey {
        case stationId = "station_id"
        case numberOfBikesAvailable = "num_bikes_available"
        case numberOfDocksAvailable = "num_docks_available"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        numberOfBikesAvailable = try container.decode(Int.self, forKey: .numberOfBikesAvailable)
        numberOfDocksAvailable = try container.decode(Int.self, forKey: .numberOfDocksAvailable)
        
        do {
            stationId = "\(try container.decode(Int.self, forKey: .stationId))"
        } catch DecodingError.typeMismatch {
            stationId = try container.decode(String.self, forKey: .stationId)
        }
    }
}
