//
//  BicisTests.swift
//  BicisTests
//
//  Created by Javier de Martín Gil on 09/04/2020.
//  Copyright © 2020 Javier de Martín Gil. All rights reserved.
//

import XCTest

class NeuralBikesTests: XCTestCase {

    let remoteDataManager = DefaultRemoteDataManager()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertTrue(true)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

    /// Test if the API endpoint for all of the available ciites exists and the parsing is done correctly
    func testApiOpenDataEndpoints() {

        for (city, _) in availableCities {

            print("> Testing \(city)")
            let expectation = XCTestExpectation.init(description: city)

            remoteDataManager.getStations(city: city, completion: { parseResult in
                // Got data from the api
                switch parseResult {

                case .success(let data):

                    guard let randomStation = data.randomElement() else {
                        return XCTFail("Couldn't get a random station")
                    }

                    XCTAssert(randomStation.id.count > 0)

                    XCTAssert(randomStation.freeBikes >= 0)
                    XCTAssert(randomStation.freeRacks >= 0)

                    XCTAssert(randomStation.stationName.count >= 0)

                    expectation.fulfill()

                case .error(let error):
                    XCTFail(error.localizedDescription)
                }

            })

            self.wait(for: [expectation], timeout: 20)
        }
    }

    /// Test my API and check if it
    func testPredictionAvailabilityApi() {
        
        for (city, cityData) in availableCities {
            
            let expectation = XCTestExpectation.init(description: city)
            
            self.wait(for: [expectation], timeout: 15)

            print("> Testing \(city)")

            remoteDataManager.getStations(city: city, completion: { parseResult in
                // Got data from the api
                switch parseResult {

                case .success(let data):
                    
                    for station in data {
                        /// Check if the fields match the expected types
                        if type(of: station.id) != String.self {
                            XCTFail("Type mismatch")
                        }
                        
                        if type(of: station.freeBikes) != Int.self {
                            XCTFail("Type mismatch")
                        }
                        
                        if type(of: station.freeRacks) != Int.self {
                            XCTFail("Type mismatch")
                        }
                        
                        if type(of: station.latitude) != Double.self {
                            XCTFail("Type mismatch")
                        }
                        
                        if type(of: station.longitude) != Double.self {
                            XCTFail("Type mismatch")
                        }
                        
                        self.remoteDataManager.getAllDataFromApi(city: cityData.apiName, station: station.id, completion: { allApiResult in
                            switch allApiResult {

                            case .success(let allData):
                                XCTAssertTrue(allData.values.today.count >= 0)
                            case .error(let error):
                                XCTFail("Error for station \(station.stationName) (id. \(station.id)) in city \(cityData.formalName). \(error.localizedDescription)")
                            }
                        })
                    }

                case .error(let error):
                    XCTFail(error.localizedDescription)
                }
            })
            
            expectation.fulfill()
            
        }
    }

}

/// TODO: Test performance of parsing feeds
