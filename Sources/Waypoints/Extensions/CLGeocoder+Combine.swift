import CoreLocation
import Combine

enum GeocoderError: Error {
    case notFound
    case other(Error)
}

class ReverseGeocoderSubscription<SubscriberType: Subscriber>: Subscription where SubscriberType.Input == Result<[CLPlacemark], Error> {
    
    private var subscriber: SubscriberType?
    private let geocoder: CLGeocoder
    
    init(subscriber: SubscriberType, location: CLLocation, geocoder: CLGeocoder) {
        self.subscriber = subscriber
        self.geocoder = geocoder
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                _ = subscriber.receive(.failure(GeocoderError.other(error)))
            } else if let placemarks = placemarks {
                _ = subscriber.receive(.success(placemarks))
            } else {
                _ = subscriber.receive(.failure(GeocoderError.notFound))
            }
        }
    }
    
    func request(_ demand: Subscribers.Demand) {
        // No need to handle `demand` because events are sent when they occur
    }
    
    func cancel() {
        subscriber = nil
    }
}

public struct ReverseGeocoderPublisher: Publisher {
    public typealias Output = Result<[CLPlacemark], Error>
    public typealias Failure = Never
    
    private let location: CLLocation
    private let geocoder: CLGeocoder
    
    init(location: CLLocation, geocoder: CLGeocoder = CLGeocoder()) {
        self.location = location
        self.geocoder = geocoder
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, ReverseGeocoderPublisher.Failure == S.Failure, ReverseGeocoderPublisher.Output == S.Input {
        let subscription = ReverseGeocoderSubscription(
            subscriber: subscriber,
            location: location,
            geocoder: geocoder
        )
        subscriber.receive(subscription: subscription)
    }
}

public extension CLGeocoder {
    func reverseGeocodingPublisher(for location: CLLocation) -> AnyPublisher<Result<[CLPlacemark], Error>, Never> {
        return ReverseGeocoderPublisher(location: location, geocoder: self)
            .eraseToAnyPublisher()
    }
}
