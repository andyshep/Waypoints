//
//  LocationTrackerTests.swift
//  Waypoints
//
//  Created by Andrew Shepard on 4/24/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreLocation
import XCTest

class LocationTrackerTests: XCTestCase {
    
    typealias LocationUpdate = (manager: CLLocationManager) -> Void
    
    class FakeLocationManager: CLLocationManager {
        let locatonUpdate: LocationUpdate
        
        init(update: LocationUpdate) {
            self.locatonUpdate = update
            super.init()
        }
        
        override func startUpdatingLocation() {
            dispatch_after(1, dispatch_get_main_queue()) { () -> Void in
                self.locatonUpdate(manager: self)
            }
        }
        
        override func stopUpdatingLocation() {
            // nothing
        }
    }
    
    func testLocationUpdateIsPublished() {
        let fakeLocationManager = FakeLocationManager { (manager) -> Void in
            let location = self.location
            manager.delegate.locationManager?(manager, didUpdateLocations: [location])
        }
        
        let locationTracker = LocationTracker(threshold: 0.0, locationManager: fakeLocationManager)
        let expectation = expectationWithDescription("Should publish location change")
        
        locationTracker.addLocationChangeObserver { (result) -> () in
            switch result {
            case .Success(let location):
                XCTAssertEqual(location.physical.coordinate.latitude, self.location.coordinate.latitude, "Latitude is wrong")
                XCTAssertEqual(location.physical.coordinate.longitude, self.location.coordinate.longitude, "Longitude is wrong")
                expectation.fulfill()
            case .Failure:
                XCTFail("Location should be valid")
            }
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    private var location: CLLocation {
        return CLLocation(latitude: 25.7877, longitude: -80.2241)
    }
}
