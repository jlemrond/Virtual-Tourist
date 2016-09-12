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

        getImages()

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

        guard let photosArray = pin.photos else {
            print("No set of photos")
            return
        }

        for (index, photo) in photosArray.enumerate() {

            let indexPath = NSIndexPath(forItem: index, inSection: 0)

            guard let photo = photo as? Photo else {
                print("Unable to access Photo")
                return
            }

            guard let url = photo.url else {
                print("Photo object does not have URL attached.")
                return
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

                    print(indexPath)

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

}



// ******************************************************
//   MARK: - Collection View Delegate
// ******************************************************


extension PinDetailViewController: UICollectionViewDelegate {



}



// ******************************************************
//   MARK: - Collection View DataSource
// ******************************************************


extension PinDetailViewController: UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let items = pin.photos?.count else {
            return 0
        }

        print("Count: \(items)")

        return items
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickerPhotosCollectionCell", forIndexPath: indexPath) as! FlickrDetailViewCell

        let photo = fetchedResultsController?.objectAtIndexPath(indexPath) as? Photo

        cell.backgroundColor = UIColor.whiteColor()

        guard let imageData = photo?.image else {
            cell.loadingIndicator.startAnimating()
            return cell
        }

        cell.cellImage.image = UIImage(data: imageData)
        print(cell.cellImage.image)

        return cell

    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FlickrDetailViewCell
        print(indexPath.section)
        cell.loadingIndicator.stopAnimating()

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

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        collectionView.reloadItemsAtIndexPaths([indexPath!])

    }


}
