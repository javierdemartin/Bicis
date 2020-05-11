//
//  NextBikeBikeServicesDataManager.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

class NextBikeBikeServicesDataManager: BikeServicesDataManager {
    
    func isUserLoggedIn(credentials: UserCredentials, completion: @escaping (Result<()>) -> Void) {
        self.logIn(credentials: credentials, completion: { logInResult in
            
            switch logInResult {
                
            case .success(let logInApiResponse):
                completion(.success(()))
            case .error(let error):
                completion(.error(error))
            }
        })
    }
    
    var urlComponents: URLComponents

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    init() {

        urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "webview.nextbike.net"
    }
}

// MARK: NextBike API endpoints

extension NextBikeBikeServicesDataManager {

    func getApiKey(completion: @escaping (Result<Key>) -> Void) {
        
        urlComponents.path = "getAPIKey.json"
        
        guard let url = urlComponents.url else {
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
    
    func logIn(credentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void) {
        
        urlComponents.path = "/api/login.json"

        guard let url = urlComponents.url else {
            preconditionFailure("Failed to construct URL")
        }
        
        getApiKey(completion: { apiKeyResult in
            switch apiKeyResult {
                
            case .success(let apiKey):
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let logInFormData = LogInFormData(apiKey: apiKey.apiKey, mobile: credentials.mobile, pin: credentials.mobile, show_errors: 1)
                
                do {
                    let encodedData = try self.encoder.encode(logInFormData)
                    
                    let task = URLSession.shared.uploadTask(with: request, from: encodedData) { data, response, error in
                        // Do something...
                        
                        if let data = data {

                            do {

                                let decoded = try JSONDecoder().decode(LogInResponse.self, from: data)

                                if decoded.error != nil {
                                    if decoded.error?.code == 1 {
                                        completion(.error(BikeServicesDataManagerError.incorrectCredentials))
                                    }
                                }
                                
                                completion(.success(decoded))

                            } catch {
                                print("[ERR] Error decoding API Key")
                                print("The received JSON String is")
                                print(String(data: data, encoding: .utf8) as Any)
                                completion(.error(BikeServicesDataManagerError.errorDecodingApiKey))
                            }
                        }
                    }

                    task.resume()
                    
                } catch {
                    print(error)
                }
                
            case .error(let error):
                completion(.error(error))
            }
        })
    }
}
