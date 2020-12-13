import CoreLocation

/// Location value representing a `CLLocation` and some local metadata.
public struct Location: Equatable, Identifiable {
    public let id: UUID = UUID()
    
    /// A CLLocation object for the current location.
    public let physical: CLLocation
    
    /// The city the location is in.
    public let city: String
    
    /// The state the location is in.
    public let state: String
    
    init(location physical: CLLocation, city: String, state: String) {
        self.physical = physical
        self.city = city
        self.state = state
    }
}

public func ==(lhs: Location, rhs: Location) -> Bool {
    return lhs.physical == rhs.physical
}
