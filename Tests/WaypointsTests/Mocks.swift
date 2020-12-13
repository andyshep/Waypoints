import CoreLocation
import Combine
import Contacts
import Intents

@testable import Waypoints

final class MockLocationManager: LocationManaging {
    private let locationPublisher = PassthroughSubject<Result<[CLLocation], Error>, Never>()
    
    private(set) var stopUpdatingLocationCount = 0
    private(set) var startUpdatingLocationCount = 0
    
    func steer(_ location: CLLocation) {
        locationPublisher.send(.success([location]))
    }
    
    func steerEmpty() {
        locationPublisher.send(.success([]))
    }
    
    func steer(_ error: Error) {
        locationPublisher.send(.failure(error))
    }
     
    // MARK: <LocationManaging>
    
    func stopUpdatingLocation() {
        stopUpdatingLocationCount += 1
    }
    
    func startUpdatingLocation() {
        startUpdatingLocationCount += 1
    }
    
    func requestWhenInUseAuthorization() {
        //
    }
    
    func publisher() -> AnyPublisher<Result<[CLLocation], Error>, Never> {
        return locationPublisher.eraseToAnyPublisher()
    }
}

final class MockGeocoder: GeocoderProviding {
    private let geocoderPublisher = PassthroughSubject<Result<[CLPlacemark], Error>, Never>()
    
    func steer(_ placemark: CLPlacemark) {
        geocoderPublisher.send(.success([placemark]))
    }
    
    func steer(_ error: Error) {
        geocoderPublisher.send(.failure(error))
    }
    
    // MARK: <GeocoderProviding>
    
    func reverseGeocodingPublisher(for location: CLLocation) -> AnyPublisher<Result<[CLPlacemark], Error>, Never> {
        return geocoderPublisher.eraseToAnyPublisher()
    }
}

final class MockNotificationCenter: NotificationCentering {
    let notificationPublisher = PassthroughSubject<Notification, Never>()
    
    func steer(_ notification: Notification) {
        notificationPublisher.send(notification)
    }
    
    // MARK: <NotificationCentering>
    
    func publisher(for name: Notification.Name) -> AnyPublisher<Notification, Never> {
        return notificationPublisher.eraseToAnyPublisher()
    }
}

enum MockFactory {
    static func makePlacemark() -> CLPlacemark {
        let location = makeLocation()
        let postmark = CNMutablePostalAddress()
        postmark.city = "Miami"
        postmark.state = "FL"
        postmark.postalCode = "33122"
        
        return CLPlacemark(location: location, name: "Miami, FL", postalAddress: postmark)
    }

    static func makeLocation() -> CLLocation {
        return CLLocation(latitude: 25.7617, longitude: 80.1918)
    }

    static func makeBadPlacemark() -> CLPlacemark {
        let location = makeLocation()
        return CLPlacemark(location: location, name: nil, postalAddress: nil)
    }
    
    static func makeError() -> Swift.Error {
        return Error.mock
    }
    
    private enum Error: Swift.Error {
        case mock
    }
}
