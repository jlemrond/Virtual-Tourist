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

        // Set MapView region.
        if NSUserDefaults.standardUserDefaults().boolForKey("RegionEstablished") {
            print("Region is set")

            let longitude = NSUserDefaults.standardUserDefaults().doubleForKey("Longitude")
            let latitude = NSUserDefaults.standardUserDefaults().doubleForKey("Latitude")
            let longitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("LongitudeDelta")
            let latitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("LatitudeDelta")

            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)

        } else {
            print("Not Set")
            setUserDefaultsForMap()
        }

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

        deselectAnnotations()

    }

    // ******************************************************
    //   MARK: - Button Actions
    // ******************************************************

    /// Enter Edit Pin Mode.
    @IBAction func editPins(sender: UIBarButtonItem) {
        editable = !editable

        deselectAnnotations()

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

    /// Adds a pin to the Map View upon a long press.  Pin is added at the location
    /// of the gesture.
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

    /// Get Data from Flickr for each annotation.  Including URLs for photos in the area.
    func getDataForAnnotation(pin pin: Pin) {

        FlickrClient.sharedInstance.getPhotosForPin(longitude: String(pin.coordinates!.longitude), latitude: String(pin.coordinates!.latitude), pin: pin, page: nil, completionHandler: { (result, error) in

            guard error == nil else {
                self.displayOneButtonAlert("Alert", message: error)
                return
            }

            guard let photoArray = result as? [[String: AnyObject]] else {
                self.displayOneButtonAlert("Alert", message: "No photos returned")
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
                    let newPhoto = Photo(index: index, url: url, id: Int(id)!, context: context)
                    newPhoto!.pin = pin
                })
                
            }

        })

    }



    /// Gets the pins already currently stored in Core Data.
    func getPinData() {

        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack

        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(Model.pin, inManagedObjectContext: stack.backgroundContext)

        stack.performBackgroundBatchOperation { (context) in
            var results: [Pin]
            do {
                results = try stack.backgroundContext.executeFetchRequest(fetchRequest) as! [Pin]
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
                performOnMain({ 
                    self.mapView.addAnnotation(annotation)
                })
            }
        }
    }

    /// Check for selected annotations and deselect them.
    func deselectAnnotations() {
        for annotation in mapView.selectedAnnotations {
            mapView.deselectAnnotation(annotation, animated: true)
        }
    }

    /// Store user location on Map.
    func setUserDefaultsForMap() {
        let region = mapView.region
        let longitude = region.center.longitude
        let latitude = region.center.latitude
        let longitudeDelta = region.span.longitudeDelta
        let latitudeDelta = region.span.latitudeDelta

        NSUserDefaults.standardUserDefaults().setDouble(longitude, forKey: "Longitude")
        NSUserDefaults.standardUserDefaults().setDouble(latitude, forKey: "Latitude")
        NSUserDefaults.standardUserDefaults().setDouble(longitudeDelta, forKey: "LongitudeDelta")
        NSUserDefaults.standardUserDefaults().setDouble(latitudeDelta, forKey: "LatitudeDelta")

        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "RegionEstablished")
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

        guard let annotation = view.annotation as? TravelLocationPointAnnotation else {
            return
        }

        guard editable == false else {
            performOnMain({
                self.mapView.removeAnnotation(view.annotation!)
            })
            self.stack.performBackgroundBatchOperation({ (context) in
                context.deleteObject(annotation.pin)
            })
            return
        }

        guard let pinDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("PinDetailViewController") as? PinDetailViewController else {
            displayOneButtonAlert("Alert", message: "Unable to display detail view")
            return
        }

        deselectAnnotations()

        pinDetailViewController.pin = annotation.pin
        navigationController?.pushViewController(pinDetailViewController, animated: true)

    }

    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        setUserDefaultsForMap()
    }

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        setUserDefaultsForMap()
    }


}







