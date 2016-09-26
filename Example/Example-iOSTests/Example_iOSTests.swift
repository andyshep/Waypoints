//
//  Example_iOSTests.swift
//  Example-iOSTests
//
//  Created by Andrew Shepard on 4/28/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreLocation
import XCTest

class Example_iOSTests: XCTestCase {
    
    typealias LocationUpdate = (_ manager: CLLocationManager) -> Void
    
    class FakeLocationManager: CLLocationManager {
        let locatonUpdate: LocationUpdate
        
        init(update: @escaping LocationUpdate) {
            self.locatonUpdate = update
            super.init()
        }
        
        override func startUpdatingLocation() {
            let delay = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: delay) {
                self.locatonUpdate(self)
            }
        }
        
        override func stopUpdatingLocation() {
            // nothing
        }
    }
    
    func testLocationUpdateIsPublished() {
        let fakeLocationManager = FakeLocationManager { (manager) -> Void in
            let location = self.location
            manager.delegate?.locationManager?(manager, didUpdateLocations: [location])
        }
        
        let locationTracker = LocationTracker(threshold: 0.0, locationManager: fakeLocationManager)
        let expectation = self.expectation(description: "Should publish location change")
        
        locationTracker.addLocationChangeObserver { (result) -> () in
            switch result {
            case .success(let location):
                XCTAssertEqual(location.physical.coordinate.latitude, self.location.coordinate.latitude, "Latitude is wrong")
                XCTAssertEqual(location.physical.coordinate.longitude, self.location.coordinate.longitude, "Longitude is wrong")
                
                expectation.fulfill()
            case .failure:
                XCTFail("Location should be valid")
            }
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    private var location: CLLocation {
        return CLLocation(latitude: 25.7877, longitude: -80.2241)
    }
}
