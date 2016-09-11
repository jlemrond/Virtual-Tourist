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



    // ******************************************************
    //   MARK: - Load/Appear Functions
    // ******************************************************

    override func viewDidLoad() {
        print("Map View Loaded")

        // Set Delegate.
        mapView.delegate = self

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


    /// Get Pin Data form Database.
    func getPinData() {

        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(Model.pin, inManagedObjectContext: stack.mainContext)

        do {
            let results = try stack.mainContext.executeFetchRequest(fetchRequest)
            print("Results \(results)")
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }

//        let fetchRequest = NSFetchRequest(entityName: Model.pin)
//        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Model.PinKeys.createDate, ascending: false)]
//
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
//                                                          managedObjectContext: stack.mainContext,
//                                                            sectionNameKeyPath: nil,
//                                                                     cacheName: nil)
//
//        print("Attempt to fetch results")
//        do {
//            let result = try fetchedResultsController.performFetch()
//            print(result)
//        } catch {
//            print("There was an error fetching your results")
//        }

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







