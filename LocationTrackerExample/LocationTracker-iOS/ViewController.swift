//
//  ViewController.swift
//  LocationTrackerExample
//
//  Created by Andrew Shepard on 3/15/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var locationLabel: UILabel!
    
    let locationTracker = LocationTracker(threshold: 10.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.updateLocationLabel("Unknown")
        
        self.locationTracker.addLocationChangeObserver { (result) -> () in
            switch result {
            case .Success(let location):
                let coordinate = location.physical.coordinate
                let locationString = "\(coordinate.latitude), \(coordinate.longitude)"
                self.updateLocationLabel(locationString)
            case .Failure(let reason):
                self.updateLocationLabel("Failure")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateLocationLabel(text: String) -> Void {
        self.locationLabel.text = "Location: \(text)"
    }
}

