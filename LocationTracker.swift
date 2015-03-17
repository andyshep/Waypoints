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
public class LocationTracker: NSObject, CLLocationManagerDelegate {
    
    /// An alias for the location change observer type.
    public typealias Observer = (location: LocationResult) -> ()
    
    /// The last location result received. Initially the location is unknown.
    private var lastResult: LocationResult = .Failure(.UnknownLocation)
    
    /// The collection of location observers
    private var observers: [Observer] = []
    
    /// the minimum distance traveled before a location change is published.
    private let threshold: Double
    
    /// A `LocationResult` representing the current location.
    var currentLocation: LocationResult {
        return self.lastResult
    }
    
    /**
    Type representing either a Location or a Reason the location could not be determined.
    
    - Success: A successful result with a valid Location.
    - Failure: An unsuccessful result with a Reason for failure.
    */
    public enum LocationResult {
        case Success(Location)
        case Failure(Reason)
    }
    
    /**
    Type representing either an unknown location or an NSError describing why the location failed.
    
    - UnknownLocation: The location is unknown because it has not been determined yet.
    - Other: The NSError describing why the location could not be determined.
    */
    public enum Reason {
        case UnknownLocation
        case Other(NSError)
    }
    
    /**
    Location value representing a `CLLocation` and some local metadata.
    
    - physical: A CLLocation object for the current location.
    - city: The city the location is in.
    - state: The state the location is in.
    - neighborhood: The neighborhood the location is in.
    */
    public struct Location: Equatable {
        let physical: CLLocation
        let city: String
        let state: String
        let neighborhood: String
        
        init(location physical: CLLocation, city: String, state: String, neighborhood: String) {
            self.physical = physical
            self.city = city
            self.state = state
            self.neighborhood = neighborhood
        }
    }
    
    /**
        Initializes a new LocationTracker with the default minimum distance threshold of 0 meters.
    
        :returns: LocationTracker with the default minimum distance threshold of 0 meters.
    */
    convenience override init() {
        self.init(threshold: 0.0)
    }
    
    /**
        Initializes a new LocationTracker with the specified minimum distance threshold.
    
        :param: threshold The minimum distance change in meters before a new location is published.
    
        :returns: LocationTracker with the specified minimum distance threshold.
    */
    init(threshold: Double) {
        self.threshold = threshold
        super.init()
        
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Public
    
    /**
        Adds a location change observer to execute whenever the location significantly changes.
    
        :param: observer The callback function to execute when a location change occurs.
    */
    func addLocationChangeObserver(observer: Observer) -> Void {
        observers.append(observer)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        #if os(iOS)
            switch status {
            case .AuthorizedWhenInUse:
                locationManager.startUpdatingLocation()
            default:
                locationManager.requestWhenInUseAuthorization()
            }
        #elseif os(OSX)
            locationManager.startUpdatingLocation()
        #endif
    }
    
    public func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        let result = LocationResult.Failure(Reason.Other(error))
        self.publishChangeWithResult(result)
        self.lastResult = result
    }
    
    public func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let currentLocation = locations.first as? CLLocation {
            if shouldUpdateWithLocation(currentLocation) {
                CLGeocoder().reverseGeocodeLocation(currentLocation, completionHandler: { (placemarks, error) -> Void in
                    if let placemark = placemarks?.first as? CLPlacemark {
                        if let city = placemark.locality {
                            if let state = placemark.administrativeArea {
                                if let neighborhood = placemark.subLocality {
                                    let location = Location(location: currentLocation, city: city, state: state, neighborhood: neighborhood)
                                    
                                    let result = LocationResult.Success(location)
                                    self.publishChangeWithResult(result)
                                    self.lastResult = result
                                }
                            }
                        }
                    }
                    else {
                        let result = LocationResult.Failure(Reason.Other(error))
                        self.publishChangeWithResult(result)
                        self.lastResult = result
                    }
                })
            }
            
            // location hasn't changed significantly
        }
    }
    
    // MARK: - Private
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        return locationManager
    }()
    
    private func publishChangeWithResult(result: LocationResult) {
        observers.map { (observer) -> Void in
            observer(location: result)
        }
    }
    
    private func shouldUpdateWithLocation(location: CLLocation) -> Bool {
        switch lastResult {
        case .Success(let loc):
            return location.distanceFromLocation(loc.physical) > threshold
        case .Failure:
            return true
        }
    }
}

public func ==(lhs: LocationTracker.Location, rhs: LocationTracker.Location) -> Bool {
    return lhs.physical == rhs.physical
}