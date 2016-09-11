//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import CoreData

struct CoreDataStack {

    // ******************************************************
    //   MARK: - Variables
    // ******************************************************

    private let model: NSManagedObjectModel
    private let storeCoordinator: NSPersistentStoreCoordinator

    private let persistentContext: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext

    private let modelURL: NSURL
    private let databaseURL: NSURL

    typealias Batch = (context: NSManagedObjectContext) -> ()



    // *************************************
    //   MARK: - Initialize
    // *************************************

    init?(model modelName: String) {

        // Get URL for model specified.
        guard let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            print("Unable to find data model named \(modelName)")
            return nil
        }

        self.modelURL = modelURL


        // Setup Model.
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            print("Unable to find model at \(modelURL)")
            return nil
        }

        self.model = model


        // Setup Store Coordinator.
        storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)


        // Setup Contexts.
        persistentContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        persistentContext.persistentStoreCoordinator = storeCoordinator
        persistentContext.name = "Persistent Context"

        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mainContext.parentContext = persistentContext
        mainContext.name = "Main Context"

        backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundContext.parentContext = mainContext
        backgroundContext.name = "Background Context"


        // Get Database URL From File Manager
        let fileManager = NSFileManager.defaultManager()

        guard let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first else {
            print("Unable to get database URL from File Manager Directory")
            return nil
        }

        databaseURL = documentsURL.URLByAppendingPathComponent("model.sqlite")


        // Create Persistent Store
        do {
            try storeCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: databaseURL, options: nil)
        } catch {
            print("Unable to add store at \(databaseURL)")
        }

    }



    // ******************************************************
    //   MARK: - Delete Data Functions
    // ******************************************************

    /// Drop all Data and restore with an empty data set.
    func dropAllData() throws {

        try storeCoordinator.destroyPersistentStoreAtURL(databaseURL, withType: NSSQLiteStoreType, options: nil)

        try storeCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: databaseURL, options: nil)

    }



    // ******************************************************
    //   MARK: - Save Data Functions
    // ******************************************************

    /// Save Data on specified context.
    func saveContext(context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            fatalError("Error while saving \(context.name): \(error)")
        }
    }


    /// Save Data from Main Thread via Persistent Context.
    func save() {

        mainContext.performBlock { 

            if self.mainContext.hasChanges {

                // Save from Main Context to Persistent Context.
                self.saveContext(self.mainContext)

                // Save form Persistent Context to Store Coordinator.
                self.persistentContext.performBlock({ 
                    self.saveContext(self.persistentContext)
                })

            }

        }

    }


    /// Auto Save based on the Time interval specified.
    func autoSave(delayInSeconds: Int) {

        if delayInSeconds > 0 {
            print("Autosaving.")

            save()

            performOnMainAfter(delayInSeconds, action: { 
                self.autoSave(delayInSeconds)
            })
            
        }

    }



    // ******************************************************
    //   MARK: - Batch Data Functions
    // ******************************************************

    /// Create Batch on Background Thread
    func performBackgroundBatchOperation(batch: Batch) {

        backgroundContext.performBlock {
            // Perform operation in closure.
            batch(context: self.backgroundContext)

            // Save to Main Context.
            self.saveContext(self.backgroundContext)

        }

    }

}


// ******************************************************
//   MARK: - Model Constants
// ******************************************************


struct Model {


    static let pin = "Pin"
    static let photo = "Photo"


    struct PinKeys {

        static let id = "id"
        static let createDate = "createDate"
        static let latitude = "latitude"
        static let longitude = "longitude"

    }

    struct PhotoKeys {

        static let id = "id"
        static let image = "image"
        static let index = "index"
        static let url = "url"

    }


}