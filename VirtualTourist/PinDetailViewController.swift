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

    var pin: Pin!
    var stack: CoreDataStack!
    var photoArray: [Photo]!
    var blockOperations: [NSBlockOperation] = []

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
        print("View for \(pin) loaded")

        setUpMapView()

        collectionView.delegate = self
        collectionView.dataSource = self

        createFetchResultsController()

    }


    // ******************************************************
    //   MARK: - UI Setup Functions
    // ******************************************************

    func setUpMapView() {
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinates, 1500, 1500)
        mapView.setRegion(region, animated: true)

        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinates
        mapView.addAnnotation(annotation)
    }


    func getImages() {

        guard let photosArray = photoArray else {
            print("No set of photos")
            return
        }

        for (index, photo) in photosArray.enumerate() {

            let indexPath = NSIndexPath(forItem: index, inSection: 0)

            guard let url = photo.url else {
                print("Photo object does not have URL attached.")
                return
            }

            if photo.image != nil {
                print("Photo already available")
                continue
            }

            performHighPriority(action: { 
                FlickrClient.sharedInstance.getImageFromURL(url, completionHandler: { (result, error) in
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
            })
        }
    }




    // ******************************************************
    //   MARK: - Core Data Functions
    // ******************************************************

    func createFetchResultsController() {

        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        stack = delegate.stack

        let request = NSFetchRequest(entityName: Model.photo)
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        request.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])

        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: stack.mainContext, sectionNameKeyPath: nil, cacheName: nil)

        do {
            photoArray = try stack.mainContext.executeFetchRequest(request) as? [Photo]
        } catch {
            print("Unable to get photos")
        }

        print("PhotoArray: \(photoArray)")

        getImages()

    }

    func executeSearch(){
        guard  let fetchedResultsController = fetchedResultsController else {
            print("Unable to get Fetch Results Controlelr")
            return
        }

        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error while trying to perform a search: \n\(error)\n\(fetchedResultsController)")
        }
    }

    func changeExisitingPhotos(photoArray: [[String: AnyObject]]) {

        let request = NSFetchRequest(entityName: Model.photo)
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        request.predicate = predicate

        stack.performBackgroundBatchOperation { (context) in
            do {
                let entities = try context.executeFetchRequest(request) as! [Photo]

                for (index, entity) in entities.enumerate() {

                    guard let id = photoArray[index]["id"] as? String else {
                        print("No ID")
                        continue
                    }

                    guard let url = photoArray[index]["url_z"] as? String else {
                        print("No URL Available")
                        continue
                    }

                    FlickrClient.sharedInstance.getImageFromURL(url, completionHandler: { (result, error) in
                        guard error == nil else {
                            print("Error getting image: \(error)")
                            return
                        }

                        guard let imageData = result as? NSData else {
                            print("Unable to get image data.")
                            return
                        }

                        entity.image = imageData
                        entity.id = Int(id)
                        entity.url = url

                    })

                }
                
            } catch let error as NSError {
                self.displayOneButtonAlert("Alert", message: "Unable to delete existing photos")
                print(error)
            }
        }
    }



    // ******************************************************
    //   MARK: - Buttons
    // ******************************************************

    @IBAction func getNewCollection() {
        print("Get New Collection Called")

        deletePhotos()

//        getCollection { (photoArray) in
//            self.changeExisitingPhotos(photoArray)
//        }
    }

    func getCollection(completion: (photoArray: [[String: AnyObject]]) -> Void) {
        FlickrClient.sharedInstance.getPhotosForPin(longitude: String(pin.coordinates.longitude), latitude: String(pin.coordinates.latitude), pin: pin) { (result, error) in

            guard error == nil else {
                self.displayOneButtonAlert("Alert", message: error)
                return
            }

            guard let photoArray = result as? [[String: AnyObject]] else {
                self.displayOneButtonAlert("Aleft", message: "No Data Returned")
                return
            }

            print("PhotoArray: \(photoArray)")

            completion(photoArray: photoArray)

        }

    }

    func deletePhotos() {

        let request = NSFetchRequest(entityName: Model.photo)
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        request.predicate = predicate

        stack.performBackgroundBatchOperation { (context) in

            do {
                let entitiesToDelete = try context.executeFetchRequest(request) as? [Photo]

                for entity in entitiesToDelete! {
                    context.deleteObject(entity)
                }
            } catch {
                print("Unable to delete photos")
            }

        }

    }

}




// ******************************************************
//   MARK: - Collection View DataSource
// ******************************************************


extension PinDetailViewController: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let items = pin.photos?.count else {
            return 0
        }

        return items
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickerPhotosCollectionCell", forIndexPath: indexPath) as! FlickrDetailViewCell

        let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo

        cell.photo = photo
        cell.backgroundColor = UIColor.whiteColor()

        guard let imageData = photo?.image else {
            cell.loadingIndicator.startAnimating()
            return cell
        }

        cell.loadingIndicator.stopAnimating()
        cell.cellImage.image = UIImage(data: imageData)

        return cell

    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrDetailViewCell

        fetchedResultsController?.managedObjectContext.deleteObject(cell.photo)

    }

}



// ******************************************************
//   MARK: - Collection View Flow Layout Delegate
// ******************************************************


extension PinDetailViewController: UICollectionViewDelegateFlowLayout {

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
        print("Will Change")

        blockOperations.removeAll(keepCapacity: false)
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        guard let indexPath = indexPath else {
            return
        }

        print("Change Type: \(type.rawValue)")

        switch type {
        case .Insert:
            let block = NSBlockOperation(block: { 
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            })

            blockOperations.append(block)

        case .Delete:
            let block = NSBlockOperation(block: { 
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

        print("Change Type: \(type.rawValue)")

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
        collectionView.performBatchUpdates({

            print("Did Finish")

            for block in self.blockOperations {
                block.start()
            }

            }) { (success) in
                self.blockOperations.removeAll(keepCapacity: false)
                performOnMain({ 
                    self.collectionView.reloadData()
                })
        }
    }

}
