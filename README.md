# Waypoints

![Swift 5.0](https://img.shields.io/badge/swift-5.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-ios%20%7C%20macos-lightgrey.svg)

Easy location tracking in Swift.

* Add multiple observers for a single location change.
* Configure the minimum distance before a new location is published.
* Supports reverse geocoding.
* Target iOS or macOS.

## Usage

Create a `LocationTracker` instance:

	let locationTracker = LocationTracker()

Subscribe to location changes:

```
locationTracker
    .locationUpdatePublisher
    .sink { [weak self] (result) in
        switch result {
        case .success(let location):
            // handle new location
        case .failure(let error):
            // handle error
        }
    }
    .store(in: &cancellables)
```

The location is returned as a `Result<Location, Error>` type, representing either the `Location` or an `Error` about why the location could not be obtained.

The `Location` type combines a `CLLocation` with metadata for the associated city and state. Address information is obtained using `CLGeocoder`.

```
public struct Location {
    let physical: CLLocation
    let city: String
    let state: String
}
```

## Requirements

* Xcode 12
* Swift 5
* iOS 13, macOS 11

## Installation

Clone the repo directly and copy `LocationTracker.swift` into your Xcode project.

## Configuration

Starting in iOS 8, the privacy settings require you to [specify *why* the location is needed](http://stackoverflow.com/a/24063578) before the app is authorized to use it. Add an entry into the `Info.plist` for `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription`.

If location is only required when app is active.

    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Location required because...</string>

If the location is always required.

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Location always required because...</string>

## License

The MIT License
