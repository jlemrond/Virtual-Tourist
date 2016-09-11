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

    // ******************************************************
    //   MARK: - Variables
    // ******************************************************

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var deleteStateView: UIView!

    var editable = false


    // ******************************************************
    //   MARK: - Load/Appear Functions
    // ******************************************************

    override func viewDidLoad() {
        print("Map View Loaded")

        mapView.delegate = self

        let longPressOnMap = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        mapView.addGestureRecognizer(longPressOnMap)

        editButton.title = "Edit"
        deleteStateView.hidden = !editable

    }

    // ******************************************************
    //   MARK: - Button Actions
    // ******************************************************

    /// Enter Edit Pin Mode.
    @IBAction func editPins(sender: UIBarButtonItem) {
        editable = !editable

        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }

        if editable == true {
            editButton.title = "Done"
        } else {
            editButton.title = "Edit"
        }

        deleteStateView.hidden = !editable
    }


    // ******************************************************
    //   MARK: - Functions
    // ******************************************************

    /// Adds a pin to the Map View.
    func addPin(gestureRecognizer: UIGestureRecognizer) {

        if gestureRecognizer.state == UIGestureRecognizerState.Began {

            guard editable == false else {
                displayOneButtonAlert("Oops", message: "Please exit edit mode to add new pins")
                return
            }

            print("Adding Pin to Map")

            performHighPriority(action: {
                
                let touchPoint = gestureRecognizer.locationInView(self.mapView)
                let pinCoordinates = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
                print(String(pinCoordinates.latitude))

                // Create Annotation
                let annotation = MKPointAnnotation()
                annotation.coordinate = pinCoordinates
                print("New Pin Coord: \(pinCoordinates)")
                performOnMain({ 
                    self.mapView.addAnnotation(annotation)
                })

                // Get Data for Annotation
                FlickrClient.sharedInstance.getPhotosFromCoordinates(longitude: String(pinCoordinates.longitude), latitude: String(pinCoordinates.latitude), completionHandler: { (result, error) in

                    guard error == nil else {
                        self.displayOneButtonAlert("Alert", message: error)
                        return
                    }



                })

            })

        }

    }

}




// ******************************************************
//   MARK: - Map View Delegate
// ******************************************************


extension MapViewController: MKMapViewDelegate {

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        print("Pin Selected")

        if editable == true {
            performOnMain({ 
                self.mapView.removeAnnotation(view.annotation!)
            })
        }
    }


}

