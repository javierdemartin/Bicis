//
//  DefaultRemoteDataManager.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation
import RxSwift

class DefaultRemoteDataManager: RemoteDataManager {
    var publishSubject: PublishSubject<[BikeStation]>
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    var myComponents = URLComponents()

    init() {

        myComponents.scheme = "https"
        myComponents.host = "javierdemart.in"
        publishSubject = PublishSubject<[BikeStation]>()
    }

    func getAllDataFromApi(city: String, station: String, completion: @escaping(Result<MyAllAPIResponse>) -> Void) {

        myComponents.path = "/api/v1/all/\(city)/\(station)"

        guard let url = myComponents.url else {
            preconditionFailure("Failed to construct URL")
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in

            DispatchQueue.main.async {

                if let data = data {

                    do {

                        let decoder = JSONDecoder()

                        let decoded = try decoder.decode(MyAllAPIResponse.self, from: data)

                        completion(.success(decoded))

                    } catch {
                        print("[ERR] Error decoding API Response from \(city) for station \(station)")
                        print("The received JSON String is")
                        print(String(data: data, encoding: .utf8) as Any)
                        return completion(.error(RemoteDataManagerError.errorParsingNeuralBikesApi))
                    }
                }
            }
        }

        task.resume()

    }

    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(Result<MyAPIResponse>) -> Void) {

        myComponents.path = "/api/v1/\(type)/\(city)/\(name)"

        guard let url = myComponents.url else {
            preconditionFailure("Failed to construct URL")
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in

            DispatchQueue.main.async {

                if let data = data {

                    do {

                        let decoder = JSONDecoder()
                        let decoded = try decoder.decode(MyAPIResponse.self, from: data)

                        completion(.success(decoded))

                    } catch {
                        print("[ERR] Error decoding API Response from \(city) for station \(name)")
                        print("The received JSON String is")
                        print(String(data: data, encoding: .utf8) as Any)
                        return completion(.error(RemoteDataManagerError.errorParsingNeuralBikesApi))
                    }
                }
            }
        }

        task.resume()
    }

    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void) {

        guard let selectedCity = availableCities[city]  else { return }
        
        if let hasGbfs = availableCities[selectedCity.formalName]?.gbfs {
            getGbfsData(city: selectedCity, completion: { gbfsCity in
                
                guard let gbfsCity = gbfsCity else {
                    
                    completion(.error(RemoteDataManagerError.couldntParseFeed))
                    return
                }
                
                completion(.success(gbfsCity))
            })
        } else if let hasLogIn = availableCities[selectedCity.formalName]?.logInCredentials {
         
            guard let apiUrl = URL(string: selectedCity.apiUrl) else { return }
            
            var apiRequest = URLRequest(url: apiUrl)
            
            getApiKeyIfNeeded(city: selectedCity, completion: { apiKeyResult in
                
                if let apiKeyAccessToken = apiKeyResult {
                    apiRequest.setValue(apiKeyAccessToken, forHTTPHeaderField: "accessToken")
                }
                
                let task = URLSession.shared.dataTask(with: apiRequest, completionHandler: { (data, _, error) in
                    
                    DispatchQueue.main.async {
                        
                        if error != nil {
                            print("[ERROR] \(error!.localizedDescription)")
                        }
                        
                        if let data = data {
                            
                            do {
                                
                                let result = try JSONDecoder().decode(BiciMadRoot.self, from: data)
                                completion(.success(result.data))
                                
//                                switch selectedCity.formalName {
//                                case "New York":
//                                    let result = try JSONDecoder().decode(CitiBikesRoot.self, from: data)
//                                    completion(.success([]))
//                                case "Bilbao":
//                                    let result = try JSONDecoder().decode(NextBikeRoot.self, from: data)
//                                    completion(.success(result.countries[0].cities[0].places))
//                                case "Madrid":
//                                    let result = try JSONDecoder().decode(BiciMadRoot.self, from: data)
//                                    completion(.success(result.data))
//                                default:
//                                    completion(.error(RemoteDataManagerError.couldntParseFeed))
//                                }
                                
                            } catch {
                                
                                print("Error parsing \(city)")
                                dump(error.localizedDescription)
                                
                                return
                            }
                        }
                    }
                })
                
                task.resume()
            })
        } else {
            
            guard let apiUrl = URL(string: selectedCity.apiUrl) else { return }
        
            let task = URLSession.shared.dataTask(with: apiUrl, completionHandler: { (data, _, error) in
                
                DispatchQueue.main.async {
                    
                    if error != nil {
                        print("[ERROR] \(error!.localizedDescription)")
                    }
                    
                    if let data = data {
                        
                        do {
                                                    
                            switch selectedCity.formalName {
                            case "Bilbao":
                                let result = try JSONDecoder().decode(NextBikeRoot.self, from: data)
                                completion(.success(result.countries[0].cities[0].places))
                            default:
                                completion(.error(RemoteDataManagerError.couldntParseFeed))
                            }
                            
                        } catch {
                            
                            print("Error parsing \(city)")
                            dump(error.localizedDescription)
                            
                            return
                        }
                    }
                }
            })
            
            task.resume()
        }
    }
    
    func getGbfsData(city: City, completion: @escaping ([BikeStation]?) -> Void) {
        
        guard let gbfs = availableCities[city.formalName] else {
            completion(nil)
            return
        }
                
        var gbfsStationStatus: [GbfsStationStatusStation] = []
        var gbfsStationInformation: [GbfsStationStatusInformation] = []
        
        guard let stationStatusUrl = URL(string: availableCities[city.formalName]?.gbfs?.stationStatus ?? "") else { return }
        
        var apiRequest = URLRequest(url: stationStatusUrl)

        let group = DispatchGroup()
        
        group.enter()
        
        let task = URLSession.shared.dataTask(with: apiRequest, completionHandler: { (data, _, error) in
            
            DispatchQueue.main.async {
                
                if error != nil {
                    print("[ERROR] \(error!.localizedDescription)")
                }
                
                if let data = data {
                    
                    do {
                        
                        let result = try JSONDecoder().decode(GbfsStationStatus.self, from: data)
                        
                        gbfsStationStatus = result.data.stations
                    } catch {
                        
                        print("Error parsing \(city)")
                        dump(error.localizedDescription)
                        return
                    }
                    
                    group.leave()
                }
            }
        })
        
        task.resume()
        
        // -------------------------------------------------------------
        
        guard let stationInformation = URL(string: availableCities[city.formalName]?.gbfs?.stationInformation ?? "") else { return }
        
        let apiRequest2 = URLRequest(url: stationInformation)
        
        group.enter()
        
        let task2 = URLSession.shared.dataTask(with: apiRequest2, completionHandler: { (data, _, error) in
            
            DispatchQueue.main.async {
                
                if error != nil {
                    print("[ERROR] \(error!.localizedDescription)")
                }
                
                if let data = data {
                    
                    do {
                        
                        let result = try JSONDecoder().decode(GbfsStationInformation.self, from: data)
                        
                        gbfsStationInformation = result.data.stations
                    } catch {
                        
                        print("Error parsing \(city)")
                        dump(error.localizedDescription)
                        return
                    }
                    group.leave()
                }
            }
        })
        
        task2.resume()
        
        // -------------------------------------------------------------
        
        group.notify(queue: .main) {
            
            print(gbfsStationInformation)
            print(gbfsStationStatus)
            print("Finished")
            
            var stations: [BikeStation] = []
            
            for stInfo in gbfsStationInformation {
                
                gbfsStationStatus.map({
                    
                    if $0.stationId == stInfo.stationId {
                     
                        var station = CitiBikesStation(latitude: stInfo.latitude, longitude: stInfo.longitude, stationName: stInfo.stationName, id: stInfo.stationId, freeBikes: $0.numberOfBikesAvailable, freeRacks: $0.numberOfDocksAvailable)
                        
                        stations.append(station)
                    }
                })
            }
            
            completion(stations)
        }
        
    }

    // MARK: Madrid's bike service
    
    func getApiKeyIfNeeded(city: City, completion: @escaping (String?) -> Void) {
    
        guard let apiLogIn = availableCities[city.formalName]?.logInCredentials else {
            completion(nil)
            return
        }
        
        guard let biciMadTokenUrl = URL(string: apiLogIn.url) else { return }

        var tokenRequest = URLRequest(url: biciMadTokenUrl)
        tokenRequest.setValue(apiLogIn.username, forHTTPHeaderField: "email")
        tokenRequest.setValue(apiLogIn.password, forHTTPHeaderField: "password")
        tokenRequest.setValue(apiLogIn.apiKey, forHTTPHeaderField: "X-ApiKey")
        tokenRequest.setValue(apiLogIn.clientId, forHTTPHeaderField: "X-ClientId")

        let task = URLSession.shared.dataTask(with: tokenRequest, completionHandler: { (data, _, error) in

            DispatchQueue.main.async {

                if let error = error {
                    dump(error)
                }

                guard let data = data else { return }

                do {

                    let result = try JSONDecoder().decode(BiciMadOpenApiTokenResponse.self, from: data)

                    completion(result.data[0].accessToken)

                } catch {

                    dump(error)
                }

            }
        })

        task.resume()
        
        
    }
}
