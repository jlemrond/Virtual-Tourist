//
//  PinDetailViewController.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/11/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreData

class PinDetailViewController: UIViewController {

    // ******************************************************
    //   MARK: - Variables
    // ******************************************************

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var noImagesLabel: UILabel!
    @IBOutlet var newCollectionButton: UIBarButtonItem!

    var pin: Pin!
    var stack: CoreDataStack!
    var photoArray: NSSet?
    var blockOperations: [NSBlockOperation] = []
    var page: Int!


    var fetchedResultsController: NSFetchedResultsController? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
            print("Reload")
            collectionView.reloadData()
        }
    }


    // ******************************************************
    //   MARK: - Load/Appear Functions
    // ******************************************************

    override func viewDidLoad() {

        page = 1

        setUpMapView()

        collectionView.delegate = self
        collectionView.dataSource = self

        createFetchResultsController()

        noImagesLabel.hidden = true

    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        blockOperations.removeAll()
    }


    // ******************************************************
    //   MARK: - UI Setup Functions
    // ******************************************************

    /// Set up map at the top of view to display the location of the pin and the
    /// surrounding area.
    func setUpMapView() {
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinates!, 1500, 1500)
        mapView.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinates!
        mapView.addAnnotation(annotation)
    }

    /// Get the images from the photoSet within the fetched Resulsts Controller.  Uses
    /// the URL attached to the photo to return an NSData object to create the images.
    func getImages(completion: () -> Void) {

        stack.performBackgroundBatchOperation { (context) in
            guard let photoSet = self.fetchedResultsController?.fetchedObjects as? [Photo] else {
                print("No set of photos")
                return
            }

            if photoSet.count == 0 {
                performOnMain({
                    self.noImagesLabel.hidden = false
                })
            }

            for photo in photoSet {

                guard let indexPath = self.fetchedResultsController?.indexPathForObject(photo) else {
                    print("Unable to locate object")
                    return
                }

                if photo.image != nil {
                    print("Photo already available")
                    continue
                }

                FlickrClient.sharedInstance.getImageFromURL(String(photo.url!), completionHandler: { (result, error) in
                    guard error == nil else {
                        print("Error getting image: \(error)")
                        return
                    }

                    guard let imageData = result as? NSData else {
                        print("Unable to get image data.")
                        return
                    }

                    self.stack.performBackgroundBatchOperation({ (context) in
                        let photo = self.fetchedResultsController?.objectAtIndexPath(indexPath) as! Photo
                        photo.image = imageData
                    })
                })
            }
            
            completion()
        }
    }




    // ******************************************************
    //   MARK: - Core Data Functions
    // ******************************************************

    /// Create Fetched Results Controller.
    func createFetchResultsController() {

        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        stack = delegate.stack

        let request = NSFetchRequest(entityName: Model.photo)
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        request.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.backgroundContext, sectionNameKeyPath: nil, cacheName: nil)

    }

    /// Execute Fetch Request Search and then begin getting images based on the
    /// data proved by Flickr.
    func executeSearch(){

        do {
            try fetchedResultsController!.performFetch()

            getImages({ 
                performOnMain({
                    self.newCollectionButton.enabled = true
                })
            })

        } catch let error as NSError {
            displayOneButtonAlert("Alert", message: error.localizedDescription)
        }
    }



    // ******************************************************
    //   MARK: - Buttons
    // ******************************************************

    /// Deletes the current photos attached to the respective pin and then executes
    /// another API Call to get a refresh on the photos from Flickr.
    @IBAction func getNewCollection() {
        print("Get New Collection Called")

        newCollectionButton.enabled = false

        stack.performBackgroundBatchOperation { (context) in
            self.deletePhotos {
                self.getCollection({ () in
                    self.createFetchResultsController()
                })
            }
        }

    }



    // ******************************************************
    //   MARK: - Functions
    // ******************************************************

    /// Makes a call to the Flickr API to get photos based on the pin location.
    func getCollection(completion: () -> Void) {
        stack.performBackgroundBatchOperation { (context) in
            FlickrClient.sharedInstance.getPhotosForPin(longitude: String(self.pin.coordinates!.longitude), latitude: String(self.pin.coordinates!.latitude), pin: self.pin, page: self.page) { (result, error) in

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

                    let newPhoto = Photo(index: index, url: url, id: Int(id)!, context: self.stack.backgroundContext)
                    newPhoto!.pin = self.pin
                    
                }

                self.page = self.page + 1
                
                completion()
                
            }
        }
    }

    /// Deletes the current photos in the collection view.
    func deletePhotos(completion: () -> Void) {

        stack.performBackgroundBatchOperation { (context) in
            for entity in self.fetchedResultsController?.fetchedObjects as! [Photo] {

                self.fetchedResultsController?.managedObjectContext.deleteObject(entity)
                
            }
        }

        completion()

    }

}




// ******************************************************
//   MARK: - Collection View DataSource
// ******************************************************


extension PinDetailViewController: UICollectionViewDataSource {


    /// Number of Items In Section based on the number of objects in the fetchedResultsController.
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let fetchedResultsController = fetchedResultsController else {
            return 0
        }

        return fetchedResultsController.sections![section].numberOfObjects
    }

    /// Creates cells based on the information attached to each photo.  If no image is attached a 
    /// loading indicator is displayed as a placeholder.
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickerPhotosCollectionCell", forIndexPath: indexPath) as! FlickrDetailViewCell

        let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo

        cell.photo = photo
        cell.backgroundColor = UIColor.whiteColor()

        if let imageData = photo?.image {
                cell.cellImage.image = UIImage(data: imageData)
                cell.loadingIndicator.stopAnimating()
        } else {
                cell.loadingIndicator.startAnimating()
        }

        return cell

    }

    /// Delete a cell if it is selected.
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? FlickrDetailViewCell else {
            return
        }

        stack.performBackgroundBatchOperation { (context) in
            self.fetchedResultsController?.managedObjectContext.deleteObject(cell.photo)
        }

    }

}



// ******************************************************
//   MARK: - Collection View Flow Layout Delegate
// ******************************************************


extension PinDetailViewController: UICollectionViewDelegateFlowLayout {

    /// Size of cell based on 1/3 the width of the screen.
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {

        let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width
        let cellWidth: CGFloat = (screenWidth - 6) / 3
        let size = CGSize(width: cellWidth, height: cellWidth)

        return size

    }

}




// ******************************************************
//   MARK: - Fetched Results Delegate
// ******************************************************

extension PinDetailViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(controller: NSFetchedResultsController) {

        blockOperations.removeAll(keepCapacity: false)
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        guard let indexPath = indexPath else {
            return
        }

        switch type {
        case .Insert:
            let block = NSBlockOperation(block: { 
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            })

            blockOperations.append(block)

        case .Delete:
            let block = NSBlockOperation(block: {
                print("Deleting")
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            })

            blockOperations.append(block)

        case .Move:
            let block = NSBlockOperation(block: {
                guard let newIndexPath = newIndexPath else {
                    return
                }

                self.collectionView.moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)
            })

            blockOperations.append(block)

        case .Update:
            let block = NSBlockOperation(block: {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            })

            blockOperations.append(block)
        }

    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {

        switch type {
        case .Insert:
            let block = NSBlockOperation(block: {
                self.collectionView.insertSections(NSIndexSet(index: sectionIndex))
            })

            blockOperations.append(block)

        case .Delete:
            let block = NSBlockOperation(block: {
                self.collectionView.deleteSections(NSIndexSet(index: sectionIndex))
            })

            blockOperations.append(block)

        default:
            let block = NSBlockOperation(block: {
                self.collectionView.reloadSections(NSIndexSet(index: sectionIndex))
            })
            
            blockOperations.append(block)
        }

        
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        performOnMain { 
            self.collectionView.performBatchUpdates({

                for block in self.blockOperations {
                    block.start()
                }

            }) { (success) in
                self.blockOperations.removeAll(keepCapacity: false)
                self.collectionView.reloadData()
            }
        }

    }

}
