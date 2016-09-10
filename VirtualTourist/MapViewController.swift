//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var editButton: UIBarButtonItem!

    override func viewDidLoad() {
        print("Map View Loaded")

    }

    @IBAction func editPins() {
        print("Edit Pins Selected")
    }



}

