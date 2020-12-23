import CoreLocation
import Combine

#if os(iOS)
import UIKit
#endif

enum LocationError: Error {
    case unknown
}

public protocol LocationTracking {
    
    /// Emits when the location changes, either through an error or a location update.
    var locationUpdatePublisher: AnyPublisher<Result<Location, Error>, Never> { get }
}

/// The LocationTracker class defines a mechanism for determining the current location and observing location changes.
public final class LocationTracker: LocationTracking {
    
    // MARK: Dependencies
    
    private let locationManager: LocationManaging
    private let geocoder: GeocoderProviding
    private let notificationCenter: NotificationCentering
    
    // MARK: <LocationTracking>
    
    public var locationUpdatePublisher: AnyPublisher<Result<Location, Error>, Never> {
        return locationSubject
            .flatMap { (result) -> AnyPublisher<Result<Location, Error>, Never> in
                switch result {
                case .success(let location):
                    return self.geocoder
                        .reverseGeocodingPublisher(for: location)
                        .map { (result) in
                            switch result {
                            case .success(let placemarks):
                                return placemarks.location(physical: location)
                            case .failure(let error):
                                return .failure(error)
                            }
                        }
                        .eraseToAnyPublisher()
                case .failure(let error):
                    return Just(Result<Location, Error>.failure(error))
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    private let locationSubject = CurrentValueSubject<Result<CLLocation, Error>, Never>(.failure(LocationError.unknown))
    
    private var cancelables: [AnyCancellable] = []
    
    /// Creates a new instance of a `LocationTracker`
    /// - Parameters:
    ///   - makeLocationManager: Factory function that returns a `CLLocationManager`
    ///   - geocoder: A geocoder object; defaults to `CLGeocoder`.
    ///   - notificationCenter: A notification center; defaults to `NotificationCenter.default`.
    ///   - queue: A queue for observing notication changes. Defaults to `DispatchQueue.main`
    ///   - interval: An interval to wait before receiving location updates. Defaults to 60 seconds.
    public init(locationManager makeLocationManager: LocationManagerMaking = { CLLocationManager() },
                geocoder: GeocoderProviding = CLGeocoder(),
                notificationCenter: NotificationCentering = NotificationCenter.default,
                queue: DispatchQueue = DispatchQueue.main,
                updateInterval interval : TimeInterval = 60.0) {
        self.locationManager = makeLocationManager()
        self.geocoder = geocoder
        self.notificationCenter = notificationCenter
        
        watchForApplicationLifecycleChanges()
        watchForLocationChanges(interval: interval, scheduler: queue)
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    deinit {
        cancelables.forEach { $0.cancel() }
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: Private
    
    private func watchForApplicationLifecycleChanges() {
        #if os(iOS)
        notificationCenter
            .publisher(for: UIApplication.willResignActiveNotification)
            .map { _ in () }
            .sink(receiveValue: { [weak self] _ in
                self?.locationManager.stopUpdatingLocation()
            })
            .store(in: &cancelables)
        
        notificationCenter
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in () }
            .sink(receiveValue: { [weak self] _ in
                self?.locationManager.startUpdatingLocation()
            })
            .store(in: &cancelables)
        #endif
    }
    
    private func watchForLocationChanges(interval: TimeInterval, scheduler: DispatchQueue) {
        let locationPublisher = locationManager
            .publisher()
            .share()
        
        // grab the first location and respond to it
        locationPublisher
            .prefix(1)
            .sink { [weak self] (result) in
                self?.updateLocationSubject(with: result)
            }
            .store(in: &cancelables)
        
        // then grab a new location every `interval` seconds
        locationPublisher
            .dropFirst()
            .throttle(
                for: DispatchQueue.SchedulerTimeType.Stride.init(floatLiteral: interval),
                scheduler: scheduler,
                latest: true
            )
            .sink { [weak self] (result) in
                self?.updateLocationSubject(with: result)
            }
            .store(in: &cancelables)
    }
    
    private func updateLocationSubject(with result: Result<[CLLocation], Error>) {
        switch result {
        case .success(let locations):
            if let location = locations.first {
                locationSubject.send(.success(location))
            } else {
                locationSubject.send(.failure(LocationError.unknown))
            }
        case .failure(let error):
            locationSubject.send(.failure(error))
        }
    }
}

private extension Array where Element: CLPlacemark {
    func location(physical: CLLocation) -> Result<Location, Error> {
        guard
            let placemark = self.first,
            let city = placemark.locality,
            let state = placemark.administrativeArea
        else { return .failure(LocationError.unknown) }
        
        let location = Location(location: physical, city: city, state: state)
        return .success(location)
    }
}

/// Factory function for creating a `LocationManaging` object
public typealias LocationManagerMaking = () -> LocationManaging

/// Wraps `CLGeocoder` for dependency injection
public protocol GeocoderProviding {
    func reverseGeocodingPublisher(for location: CLLocation) -> AnyPublisher<Result<[CLPlacemark], Error>, Never>
}

extension CLGeocoder: GeocoderProviding { }

/// Wraps `CLLocationManager` for dependency injection
public protocol LocationManaging {
    func stopUpdatingLocation()
    func startUpdatingLocation()
    func requestWhenInUseAuthorization()
    
    func publisher() -> AnyPublisher<Result<[CLLocation], Error>, Never>
}

extension CLLocationManager : LocationManaging { }

/// Wraps `NotificationCenter` for dependency injection
public protocol NotificationCentering {
    func publisher(for name: Notification.Name) -> AnyPublisher<Notification, Never>
}

extension NotificationCenter: NotificationCentering {
    
    /// Returns a publisher that emits when the notification `name` is received
    /// - Parameter name: Notification name to watch for
    /// - Returns: Publisher that emits with the notification triggered by `name`.
    public func publisher(for name: Notification.Name) -> AnyPublisher<Notification, Never> {
        return publisher(for: name, object: nil)
            .eraseToAnyPublisher()
    }
}
