//
//  DefaultRemoteDataManager.swift
//  Bicis
//
//  Created by Javier de Martín Gil on 03/11/2019.
//  Copyright © 2019 Javier de Martín Gil. All rights reserved.
//

import Foundation

class DefaultRemoteDataManager: RemoteDataManager {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    var myComponents = URLComponents()

    init() {

        myComponents.scheme = "https"
        myComponents.host = "javierdemart.in"
    }

    func getPredictionForStation(city: String, type: String, name: String, completion: @escaping(MyAPIResponse?) -> Void) {

        // PERCENT ENCODED: SAN%20PEDRO
        myComponents.path = "/api/v1/\(type)/\(city)/\(name)"

        guard let url = myComponents.url else {
            preconditionFailure("Failed to construct URL")
        }

//        print("> Querying \(url)")

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in

            DispatchQueue.main.async {

                if let data = data {

                    do {

                        let decoder = JSONDecoder()
                        let decoded = try decoder.decode(MyAPIResponse.self, from: data)

                        completion(decoded)

                    } catch {
                        print("error trying to convert data to JSON")
                        return
                    }
                }
            }
        }

        task.resume()
    }

    func getStations(city: String, completion: @escaping (Result<[BikeStation]>) -> Void) {

        guard let selectedCity = availableCities[city]  else { return }

        guard let apiUrl = URL(string: selectedCity.apiUrl) else { return }

        print("> Parsing \(city) with URL \(apiUrl)")

        var apiRequest = URLRequest(url: apiUrl)

        if city == "Madrid" {
            getApiKeyForBiciMad(completion: { result in
                switch result {

                case .success(let apiToken):
                    apiRequest.setValue(apiToken, forHTTPHeaderField: "accessToken")

                    let task = URLSession.shared.dataTask(with: apiRequest, completionHandler: { (data, _, error) in

                        DispatchQueue.main.async {

                            if error != nil {
                                print("[ERROR] \(error!.localizedDescription)")
                            }

                            if let data = data {

                                do {

                                    switch selectedCity.formalName {
                                    case "New York":
                                        let result = try JSONDecoder().decode(CitiBikesRoot.self, from: data)
                                        completion(.success(result.stationBeanList))
                                    case "Bilbao":
                                        let result = try JSONDecoder().decode(NextBikeRoot.self, from: data)
                                        completion(.success(result.countries[0].cities[0].places))
                                    case "Madrid":
                                        let result = try JSONDecoder().decode(BiciMadRoot.self, from: data)
                                        completion(.success(result.data))
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

                case .error:
                    completion(.error(RemoteDataManagerError.couldntGetApiKeyFromBiciMad))

                }
            })
        } else {
            let task = URLSession.shared.dataTask(with: apiRequest, completionHandler: { (data, _, error) in

                DispatchQueue.main.async {

                    if error != nil {
                        print("[ERROR] \(error!.localizedDescription)")
                    }

                    if let data = data {

                        do {

                            switch selectedCity.formalName {
                            case "New York":
                                let result = try JSONDecoder().decode(CitiBikesRoot.self, from: data)
                                completion(.success(result.stationBeanList))
                            case "Bilbao":
                                let result = try JSONDecoder().decode(NextBikeRoot.self, from: data)
                                completion(.success(result.countries[0].cities[0].places))
                            default:
                                completion(.error(RemoteDataManagerError.didNotGetAnyStation))
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

    // MARK: Madrid's bike service

    func getApiKeyForBiciMad(completion: @escaping (Result<String>) -> Void) {

        guard let biciMadTokenUrl = URL(string: "https://openapi.emtmadrid.es/v1/mobilitylabs/user/login/") else { return }

        var tokenRequest = URLRequest(url: biciMadTokenUrl)
        tokenRequest.setValue("javierdemartin@me.com", forHTTPHeaderField: "email")
        tokenRequest.setValue("zXF2AbQt7L6#", forHTTPHeaderField: "password")
        tokenRequest.setValue("76eb9ed5-25b6-4e57-a905-71d4ac2ecdf2", forHTTPHeaderField: "X-ApiKey")
        tokenRequest.setValue("f64bb631-8b03-426d-a1e3-9939a571003a", forHTTPHeaderField: "X-ClientId")

        let task = URLSession.shared.dataTask(with: tokenRequest, completionHandler: { (data, _, error) in

            DispatchQueue.main.async {

                if let error = error {
                    dump(error)
                }

                guard let data = data else { return }

                do {

                    let result = try JSONDecoder().decode(BiciMadOpenApiTokenResponse.self, from: data)

                    completion(.success(result.data[0].accessToken))

                } catch {

                    dump(error)
                }

            }
        })

        task.resume()
    }
}
