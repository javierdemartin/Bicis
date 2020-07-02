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
}
