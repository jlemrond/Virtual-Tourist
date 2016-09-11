//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/11/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var id: NSNumber?
    @NSManaged var index: NSNumber?
    @NSManaged var image: NSData?
    @NSManaged var url: String?
    @NSManaged var pin: NSManagedObject?

}
