//
//  LocationTracker.swift
//  LocationTracker
//
//  Created by Andrew Shepard on 3/15/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import Foundation
import CoreLocation

public typealias Observer = (location: LocationResult) -> ()

public class LocationTracker: NSObject, CLLocationManagerDelegate {
    
    private var lastResult: LocationResult = .Failure(.UnknownLocation)
    private var observers: [Observer] = []
    private let threshold: Double
    
    var currentLocation: LocationResult {
        return self.lastResult
    }
    
    convenience override init() {
        self.init(threshold: 0.0)
    }
    
    init(threshold: Double) {
        self.threshold = threshold
        super.init()
        
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - Public
    
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
                    if let placemark = placemarks?.first as? CLPlacemark,
                        let city = placemark.locality,
                        let state = placemark.administrativeArea,
                        let neighborhood = placemark.subLocality {
                            
                            let location = Location(location: currentLocation, city: city, state: state, neighborhood: neighborhood)
                            
                            let result = LocationResult.Success(location)
                            self.publishChangeWithResult(result)
                            self.lastResult = result
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

public enum LocationResult {
    case Success(Location)
    case Failure(Reason)
}

public enum Reason {
    case UnknownLocation
    case Other(NSError)
}

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

public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.physical == rhs.physical
}