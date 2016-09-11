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

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var collectionViewCell: UICollectionViewCell!

    var pin: Pin!

    override func viewDidLoad() {
        print("View for \(pin) loaded")
    }

}

