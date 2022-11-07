//
//  SearchTrainInteractorTests.swift
//  MyTravelHelperTests
//
//  Created by Apple on 06/11/22.
//  Copyright © 2022 Sample. All rights reserved.
//

import XCTest

@testable import MyTravelHelper

class SearchTrainInteractorTests: XCTestCase {
    
    var searchTrainInteractor : SearchTrainInteractor = SearchTrainInteractor()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        searchTrainInteractor._sourceStationCode = "lburn"
        searchTrainInteractor._destinationStationCode = "newry"

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFetchAllStations(){
        searchTrainInteractor.fetchallStations()
        XCTAssertNotEqual(self.searchTrainInteractor.stationsCount, 0)
        XCTAssertGreaterThan(self.searchTrainInteractor.stationsCount, 0)

    }
    
    func testFetchTrainsFromSource(){
        //Mock source and destination codes
        searchTrainInteractor.fetchTrainsFromSource(sourceCode: "lburn", destinationCode: "newry")
        XCTAssertNotEqual(self.searchTrainInteractor.availableTrainsCount, 0)
        XCTAssertGreaterThan(self.searchTrainInteractor.availableTrainsCount, 0)

    }
        

}
