//
//  ViewController.swift
//  Example-iOS
//
//  Created by Andrew Shepard on 4/28/15.
//  Copyright (c) 2015 Andrew Shepard. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var locationLabel: UILabel!
    
    let locationTracker = LocationTracker(threshold: 10.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.updateLocationLabel(withText: "Unknown")
        
        self.locationTracker.addLocationChangeObserver { (result) -> () in
            switch result {
            case .success(let location):
                let coordinate = location.physical.coordinate
                let locationString = "\(coordinate.latitude), \(coordinate.longitude)"
                self.updateLocationLabel(withText: locationString)
            case .failure:
                self.updateLocationLabel(withText: "Failure")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func updateLocationLabel(withText text: String) -> Void {
        self.locationLabel.text = "Location: \(text)"
    }
}

