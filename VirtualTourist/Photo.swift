//
//  Photo.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/11/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Photo: NSManagedObject {

    convenience init?(index: Int, url: String, id: Int, context: NSManagedObjectContext) {

        guard let entity = NSEntityDescription.entityForName(Model.photo, inManagedObjectContext: context) else {
            fatalError("Unable to create photo in database")
        }

        self.init(entity: entity, insertIntoManagedObjectContext: context)
        self.index = NSNumber(integer: index)
        self.url = url
        self.id = id
        
    }

}
