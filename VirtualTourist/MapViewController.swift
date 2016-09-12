//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    // ******************************************************
    //   MARK: - Variables
    // ******************************************************

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var editButton: UIBarButtonItem!
    @IBOutlet var deleteStateView: UIView!

    var editable = false

    let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    var stack: CoreDataStack!



    // ******************************************************
    //   MARK: - Load/Appear Functions
    // ******************************************************

    override func viewDidLoad() {
        print("Map View Loaded")

        // Set Delegate.
        mapView.delegate = self
        stack = delegate.stack

        // Create Long Press Gesture to Add Pin.
        let longPressOnMap = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        mapView.addGestureRecognizer(longPressOnMap)

        // Configure Edit Button.
        editButton.title = "Edit"
        deleteStateView.hidden = !editable

        // Get Pin Data from Database.
        getPinData()

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

                // Get Touch Point.
                let touchPoint = gestureRecognizer.locationInView(self.mapView)
                let pinCoordinates = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)

                // Create Pin in Background Context for Data Model.
                var newPin: Pin!
                self.stack.performBackgroundBatchOperation({ (context) in
                    newPin = Pin(coordinates: pinCoordinates, context: context)
                    print("Added pin with id: \(newPin?.id)")

                    // Create Annotation.
                    let annotation = TravelLocationPointAnnotation(pin: newPin)
                    annotation.coordinate = pinCoordinates
                    print("New Pin Coord: \(pinCoordinates)")
                    performOnMain({
                        self.mapView.addAnnotation(annotation)
                    })

                    performHighPriority(action: {
                        self.getDataForAnnotation(pin: newPin)
                    })
                })

            })

        }

    }


    func getDataForAnnotation(pin pin: Pin) {

        // Get Data for Annotation
        FlickrClient.sharedInstance.getPhotosFromCoordinates(longitude: String(pin.coordinates.longitude), latitude: String(pin.coordinates.latitude), completionHandler: { (result, error) in

            guard error == nil else {
                self.displayOneButtonAlert("Alert", message: error)
                return
            }

            guard let photoArray = result as? [[String: AnyObject]] else {
                self.displayOneButtonAlert("Oops", message: "Something went wrong here.")
                return
            }

            for (index, value) in photoArray.enumerate() {

                guard let id = value["id"] as? String else {
                    print("No ID")
                    continue
                }

                guard let url = value["url_z"] as? String else {
                    print("No URL Available")
                    continue
                }

                self.stack.performBackgroundBatchOperation({ (context) in
                    let newPhoto = Photo(pin: pin, index: index, url: url, id: Int(id)!, context: context)
                    print("New Photo: \(newPhoto)")
                })

            }

        })

    }



    /// Get Pin Data form Database.
    func getPinData() {

        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(Model.pin, inManagedObjectContext: stack.mainContext)

        var results: [Pin]
        do {
            results = try stack.mainContext.executeFetchRequest(fetchRequest) as! [Pin]
            print("Results \(results)")
        } catch {
            let fetchError = error as NSError
            print(fetchError)
            return
        }

        for item in results {

            guard let latitude = item.latitude,
                let longitude = item.longitude else {
                    continue
            }

            let annotation = TravelLocationPointAnnotation(pin: item)
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
            mapView.addAnnotation(annotation)

        }

    }

}




// ******************************************************
//   MARK: - Map View Delegate
// ******************************************************


extension MapViewController: MKMapViewDelegate {

    /// If a pin is selected, a check will be peformed to see if the user is in 'Edit' mode.  If they
    /// are in 'Edit' mode, the pin will be delete.  If they are not the PinDetailViewController for 
    /// that pin will be pushed on the stack and presented.
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        guard editable == false else {
            performOnMain({ 
                self.mapView.removeAnnotation(view.annotation!)
                // TODO: Delete from Database.
            })
            return
        }

        guard let annotation = view.annotation as? TravelLocationPointAnnotation else {
            return
        }

        guard let pinDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("PinDetailViewController") as? PinDetailViewController else {
            displayOneButtonAlert("Alert", message: "Unable to display detail view")
            return
        }

        pinDetailViewController.pin = annotation.pin
        navigationController?.pushViewController(pinDetailViewController, animated: true)

    }


}







