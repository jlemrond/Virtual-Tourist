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

    convenience init?(coordinates: CLLocationCoordinate2D, context: NSManagedObjectContext) {

        guard let entity = NSEntityDescription.entityForName(Model.pin, inManagedObjectContext: context) else {
            fatalError("Unable to create pin")
        }

        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.id = NSNumber(unsignedInt: arc4random_uniform(UInt32(INT32_MAX)))
        longitude = NSNumber(double: coordinates.longitude)
        latitude = NSNumber(double: coordinates.latitude)
        createDate = NSDate()

    }

    var coordinates: CLLocationCoordinate2D? {
        guard let latitude = latitude,
            let longitude = longitude else {
                return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }

        return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
    }


}
