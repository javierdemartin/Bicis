//
//  NextBikeBikeServicesDataManager.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

class NextBikeBikeServicesDataManager: BikeServicesDataManager {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    var myComponents = URLComponents()

    init() {

        myComponents.scheme = "https"
        myComponents.host = "webview.nextbike.net"
    }

    func getApiKey(completion: @escaping (Result<Key>) -> String) {
        myComponents.path = "getAPIKey.json"
        
        guard let url = myComponents.url else {
            preconditionFailure("Failed to construct URL")
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, _ in

            DispatchQueue.main.async {

                if let data = data {

                    do {

                        let decoder = JSONDecoder()

                        let decoded = try decoder.decode(Key.self, from: data)

                        completion(.success(decoded))

                    } catch {
                        print("[ERR] Error decoding API Key")
                        print("The received JSON String is")
                        print(String(data: data, encoding: .utf8) as Any)
                        completion(.error(BikeServicesDataManagerError.errorDecodingApiKey))
                    }
                }
            }
        }

        task.resume()
        
    }
}
