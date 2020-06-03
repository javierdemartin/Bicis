//
//  NextBikeBikeServicesDataManager.swift
//  NeuralBikes
//
//  Created by Javier de Martín Gil on 27/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import Foundation

class NextBikeBikeServicesDataManager: BikeServicesDataManager {
    
    func isUserLoggedIn(credentials: UserCredentials, completion: @escaping (Result<LogInResponse>) -> Void) {
        self.logIn(credentials: credentials, completion: { logInResult in
            
            switch logInResult {
                
            case .success(let logInApiResponse):
                
                completion(.success(logInApiResponse))
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
        
        urlComponents.scheme = "https"
        urlComponents.host = "webview.nextbike.net"
        urlComponents.path = "/getAPIKey.json"
        
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
    
    func getActiveRentals(apiKey: String, logInKey: String, completion: @escaping(Result<GetActiveRentalsResponse>) -> Void) {
        
        urlComponents.scheme = "https"
        urlComponents.host = "api.nextbike.net"
        urlComponents.path = "/api/getOpenRentals.json"
        
        guard let url = urlComponents.url else {
            preconditionFailure("Failed to construct URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
                        
        let parameters = ["apikey": apiKey, "loginkey": logInKey, "show_errors": "1"]
        
        do {
            
            let encodedData = try JSONSerialization.data(withJSONObject: parameters)
            
            request.httpBody = encodedData
            
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to data object and set it as request body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Do something...
                DispatchQueue.main.async {
                
                    if let data = data {

                        do {

                            let decoded = try JSONDecoder().decode(GetActiveRentalsResponse.self, from: data)
                            
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
            
        } catch {
            print(error)
        }
    }
    
    func logIn(credentials: UserCredentials, completion: @escaping(Result<LogInResponse>) -> Void) {
        
        urlComponents.scheme = "https"
        urlComponents.host = "api.nextbike.net"
        urlComponents.path = "/api/login.json"

        guard let url = urlComponents.url else {
            preconditionFailure("Failed to construct URL")
        }
        
        getApiKey(completion: { apiKeyResult in
            switch apiKeyResult {
                
            case .success(let apiKey):
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                                
                let parameters = ["apikey": apiKey.apiKey, "mobile": credentials.mobile, "pin": credentials.pin, "show_errors": "1"]
                
                do {
                    
                    let encodedData = try JSONSerialization.data(withJSONObject: parameters)
                    
                    request.httpBody = encodedData
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to data object and set it as request body
                    
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
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
    
    func forgotPassword(username: String, completion: @escaping(Result<Void>) -> Void) {
        
        urlComponents.scheme = "https"
        urlComponents.host = "api.nextbike.net"
        urlComponents.path = "/api/pinRecover.xml"
        
        guard let url = urlComponents.url else {
            preconditionFailure("Failed to construct URL")
        }
     
        getApiKey(completion: { apiKeyResult in
            
            switch apiKeyResult {
                
            case .success(let apiKey):
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                                
                let parameters = ["apikey": apiKey.apiKey, "mobile": username] as [String: Any]
                
                do {
                    
                    let encodedData = try JSONSerialization.data(withJSONObject: parameters)
                    
                    request.httpBody = encodedData
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to data object and set it as request body
                    
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        // Do something...
                        
                        DispatchQueue.main.async {
                            
                            if data != nil {
                                completion(.success(()))
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
    
    func rent(loginKey: String, bike number: Int, completion: @escaping(Result<Void>) -> Void) {
        
        urlComponents.scheme = "https"
        urlComponents.host = "api.nextbike.net"
        urlComponents.path = "/api/rent.json"
        
        guard let url = urlComponents.url else {
            preconditionFailure("Failed to construct URL")
        }
        
        getApiKey(completion: { apiKeyResult in
            switch apiKeyResult {
                
            case .success(let apiKey):
                                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                                
                let parameters = ["apikey": apiKey.apiKey, "loginkey": loginKey, "bike": number, "show_errors": "1"] as [String: Any]
                
                do {
                    
                    let encodedData = try JSONSerialization.data(withJSONObject: parameters)
                    
                    request.httpBody = encodedData
                    
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to data object and set it as request body
                    
                    let task = URLSession.shared.dataTask(with: request) { data, _, error in
                        // Do something...
                        
                        DispatchQueue.main.async {
                            
                            if let data = data {
                                
                                do {
                                    
                                    let decoded = try JSONDecoder().decode(RentResponse.self, from: data)
                                    
                                    dump(decoded)
                                    
                                    if decoded.error != nil {
                                        completion(.error(BikeServicesError.bikeNotFound))
                                    } else {
                                        completion(.success(()))
                                    }
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
                    
                } catch {
                    print(error)
                }
            case .error(let error):
                completion(.error(error))
            }
        })
    }
}
