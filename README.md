LocationTracker
====

Easy location tracking in Swift.

* Add multiple observers for a single location change.
* Configure the minimum distance before a new location is published.
* Supports reverse geocoding.
* Target iOS or OS X.

##Usage

Create a `LocationTracker` instance with the default minimum distance threshold of 0 meters:

	let locationTracker = LocationTracker()

Create a `LocationTracker` with a minimum distance threshold of 50 meters:

	let locationTracker = LocationTracker(threshold: 50.0)

Add a location change observer to an existing `LocationTracker` instance:

```
locationTracker.addLocationChangeObserver { (result) -> () in
    switch result {
    case .Success(let location):
        // handle new location
    case .Failure(let reason):
        // handle failure
    }
}
```

The location is returned as a `LocationResult` type, representing either a `Location` or a `Reason` why the location could not be obtained.

```
public enum LocationResult {
    case Success(Location)
    case Failure(Reason)
}

public enum Reason {
    case UnknownLocation
    case Other(NSError)
}
```

The `Location` type combines a `CLLocation` with metadata for the associated city, state, and neighborhood. Address infomation is obstained using `CLGeocoder`.

```
public struct Location {
    let physical: CLLocation
    let city: String
    let state: String
    let neighborhood: String
}
```

See the `LocationTrackerExample` project for iOS and OS X demos.

##Installation

Clone the repo and copy `LocationTracker.swift` into your Xcode project.

##Configuration

Starting in iOS 8, the privacy settings require you to [specify *why* the location is needed](http://stackoverflow.com/a/24063578) before the app is authorized to use it. Add an entry into the `Info.plist` for `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription`.

If location is only required when app is active.

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Location required because...</string>

If the location is always required.

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Location always required because...</string>

## License

The MIT License