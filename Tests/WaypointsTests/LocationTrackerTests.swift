import XCTest
import Combine

#if os(iOS)
import UIKit
#endif

@testable import Waypoints

class LocationTrackerTests: XCTestCase {
    
    var sut: LocationTracker!
    
    var locationManager: MockLocationManager!
    var geocoder: MockGeocoder!
    var notificationCenter: MockNotificationCenter!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        locationManager = MockLocationManager()
        geocoder = MockGeocoder()
        notificationCenter = MockNotificationCenter()
        
        sut = LocationTracker(
            locationManager: { locationManager },
            geocoder: geocoder,
            notificationCenter: notificationCenter
        )
    }
    
    func testLocationDoesUpdate() {
        let expected = expectation(description: "Should publish location change")
        
        sut.locationUpdatePublisher
            .dropFirst()
            .sink { (result) in
                switch result {
                case .success(let location):
                    XCTAssertEqual(location.city, "Miami")
                    
                    expected.fulfill()
                case .failure:
                    XCTFail("Should update location")
                }
            }
            .store(in: &cancellables)
        
        locationManager.steer(MockFactory.makeLocation())
        geocoder.steer(MockFactory.makePlacemark())
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testErrorsWhenLocationIsEmpty() {
        let expected = expectation(description: "Should publish location change")
        
        sut.locationUpdatePublisher
            .dropFirst()
            .sink { (result) in
                switch result {
                case .success:
                    XCTFail("Should error when empty locations")
                case .failure(let error):
                    if case LocationError.unknown = error {
                        expected.fulfill()
                    } else {
                        XCTFail("Should error with `noData`")
                    }
                }
            }
            .store(in: &cancellables)
        
        locationManager.steerEmpty()
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testErrorsWhenReverseGeocodingFails() {
        let expected = expectation(description: "Should publish location change")
        
        sut.locationUpdatePublisher
            .dropFirst()
            .sink { (result) in
                switch result {
                case .success:
                    XCTFail("Should error when empty locations")
                case .failure(let error):
                    if case LocationError.unknown = error {
                        expected.fulfill()
                    } else {
                        XCTFail("Should error with `noData`")
                    }
                }
            }
            .store(in: &cancellables)
        
        locationManager.steer(MockFactory.makeLocation())
        geocoder.steer(MockFactory.makeBadPlacemark())
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    #if os(iOS)
    func testStopsLocationUpdatesOnResignActive() {
        sut.locationUpdatePublisher
            .sink { _ in }
            .store(in: &cancellables)

        let notification = Notification(name: UIApplication.willResignActiveNotification)
        notificationCenter.steer(notification)

        XCTAssertEqual(locationManager.stopUpdatingLocationCount, 1)
    }

    func testStartsLocationUpdatesOnBecomeActive() {
        sut.locationUpdatePublisher
            .sink { _ in }
            .store(in: &cancellables)

        let notification = Notification(name: UIApplication.didBecomeActiveNotification)
        notificationCenter.steer(notification)

        XCTAssertEqual(locationManager.startUpdatingLocationCount, 1)
    }
    #endif
}
