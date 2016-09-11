//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import UIKit
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let stack = CoreDataStack(model: "Model")!

    func preloadData() {

        do {
            try stack.dropAllData()
        } catch {
            print("Unable to clear model")
        }

        print("Data Cleared")

        let orlandoCoords = CLLocationCoordinate2D(latitude: 28.497529128283965, longitude: -81.368113679399485)
        let jacksonvilleCoords = CLLocationCoordinate2D(latitude: 30.347467074628618, longitude: -81.624461151231131)
        let newYorkCoords = CLLocationCoordinate2D(latitude: 40.736047244935008, longitude: -73.999948604838309)

        let orlando = Pin(coordinates: orlandoCoords, context: stack.mainContext)
        let jacksonville = Pin(coordinates: jacksonvilleCoords, context: stack.mainContext)
        let newYork = Pin(coordinates: newYorkCoords, context: stack.mainContext)

        print(orlando)
        print(jacksonville)
        print(newYork)

    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        stack.autoSave(10)
        //preloadData()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        stack.save()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        stack.save()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

