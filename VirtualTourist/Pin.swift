//
//  Pin.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/11/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    convenience init?(coordinates: CLLocationCoordinate2D, context: NSManagedObjectContext) {

        guard let entity = NSEntityDescription.entityForName(Model.pin, inManagedObjectContext: context) else {
            fatalError("Unable to create pin")
        }

        self.init(entity: entity, insertIntoManagedObjectContext: context)
        id = NSNumber(unsignedInt: arc4random_uniform(UInt32(INT32_MAX)))
        longitude = NSNumber(double: coordinates.longitude)
        latitude = NSNumber(double: coordinates.latitude)
        createDate = NSDate()

    }

}
