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

        mapView.delegate = self

        let longPressOnMap = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        mapView.addGestureRecognizer(longPressOnMap)

    }

    @IBAction func editPins() {
        print("Edit Pins Selected")
    }

    func addPin(gestureRecognizer: UIGestureRecognizer) {

        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            print("Adding Pin to Map")

            // Convert Point of Touch to Coordinates.
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let pinCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

            // Create Annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = pinCoordinates
            mapView.addAnnotation(annotation)

        }

    }

}

extension MapViewController: MKMapViewDelegate {




}

