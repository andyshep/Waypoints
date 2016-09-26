//
//  LocationTracker.swift
//  LocationTracker
//
//  Created by Andrew Shepard on 3/15/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreLocation

/**
    The LocationTracker class defines a mechanism for determining the current location and observing location changes.
*/
final class LocationTracker: NSObject {
    
    /// An alias for the location change observer type.
    public typealias Observer = (_ location: LocationResult) -> ()
    
    /// The last location result received. Initially the location is unknown.
    fileprivate var lastResult: LocationResult = .failure(.unknownLocation)
    
    /// The collection of location observers
    fileprivate var observers: [Observer] = []
    
    /// The minimum distance traveled before a location change is published.
    fileprivate let threshold: Double
    
    /// The internal location manager
    fileprivate let locationManager: CLLocationManager
    
    /// A `LocationResult` representing the current location.
    public var currentLocation: LocationResult {
        return self.lastResult
    }
    
    /**
        Initializes a new LocationTracker with the default minimum distance threshold of 0 meters.
    
        - returns: LocationTracker with the default minimum distance threshold of 0 meters.
    */
    public convenience override init() {
        self.init(threshold: 0.0)
    }
    
    /**
        Initializes a new LocationTracker with the specified minimum distance threshold.
    
        - parameter threshold: The minimum distance change in meters before a new location is published.
    
        - returns: LocationTracker with the specified minimum distance threshold.
    */
    public init(threshold: Double, locationManager:CLLocationManager = CLLocationManager()) {
        self.threshold = threshold
        self.locationManager = locationManager
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        self.locationManager.startUpdatingLocation()
    }
    
    /**
        Adds a location change observer to execute whenever the location significantly changes.
    
        - parameter observer: The callback function to execute when a location change occurs.
    */
    final func addLocationChangeObserver(_ observer: @escaping Observer) -> Void {
        observers.append(observer)
    }
}

extension LocationTracker: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        #if os(iOS)
            switch status {
            case .authorizedWhenInUse:
                locationManager.startUpdatingLocation()
            default:
                locationManager.requestWhenInUseAuthorization()
            }
        #elseif os(OSX)
            locationManager.startUpdatingLocation()
        #endif
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let result = LocationResult.failure(.other(error))
        self.publishChange(with: result)
        self.lastResult = result
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.first {
            if shouldUpdate(using: currentLocation) {
                CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) -> Void in
                    if let placemark = placemarks?.first {
                        let city = placemark.locality ?? ""
                        let state = placemark.administrativeArea ?? ""
                        let neighborhood = placemark.subLocality ?? ""
                        
                        let location = Location(location: currentLocation, city: city, state: state, neighborhood: neighborhood)
                        
                        let result = LocationResult.success(location)
                        self.publishChange(with: result)
                        self.lastResult = result
                    }
                    else if let error = error {
                        let result = LocationResult.failure(.other(error))
                        self.publishChange(with: result)
                        self.lastResult = result
                    }
                })
            }
            
            // location hasn't changed significantly
        }
    }
}

extension LocationTracker {
    fileprivate func publishChange(with result: LocationResult) {
        let _ = observers.map { (observer) -> Void in
            observer(result)
        }
    }
    
    fileprivate func shouldUpdate(using location: CLLocation) -> Bool {
        switch lastResult {
        case .success(let loc):
            return location.distance(from: loc.physical) > threshold
        case .failure:
            return true
        }
    }
}

/**
 Type representing either a Location or a Reason the location could not be determined.
 
 - Success: A successful result with a valid Location.
 - Failure: An unsuccessful result with a Error for failure.
 */
public enum LocationResult {
    case success(Location)
    case failure(LocationError)
}

public enum LocationError {
    case unknownLocation
    case other(Error)
}

/**
 Location value representing a `CLLocation` and some local metadata.
 
 - physical: A CLLocation object for the current location.
 - city: The city the location is in.
 - state: The state the location is in.
 - neighborhood: The neighborhood the location is in.
 */
public struct Location: Equatable {
    public let physical: CLLocation
    public let city: String
    public let state: String
    public let neighborhood: String
    
    init(location physical: CLLocation, city: String, state: String, neighborhood: String) {
        self.physical = physical
        self.city = city
        self.state = state
        self.neighborhood = neighborhood
    }
}

public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.physical == rhs.physical
}
