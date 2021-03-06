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


    func checkIfFirstLaunch() {

        if !NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedBefore") {
            print("First Launch")
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedBefore")
            let coordinates = CLLocationCoordinate2D(latitude: Double(30), longitude: Double(-40))
            let span = MKCoordinateSpan(latitudeDelta: 117.7, longitudeDelta: 179.9)
            let region = MKCoordinateRegion(center: coordinates, span: span) as? AnyObject
            NSUserDefaults.standardUserDefaults().setObject(region, forKey: "MapViewRegion")
        }
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        stack.autoSave(10)
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

