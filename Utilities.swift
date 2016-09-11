//
//  Utilities.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import UIKit


func performOnMain(action: () -> Void) {

    dispatch_async(GlobalQueue.main) {
        action()
    }

}

func performHighPriority(action action: () -> Void) {

    dispatch_async(GlobalQueue.interactive) {
        action()
    }

}

func performStandardPriority(action action: () -> Void) {

    dispatch_async(GlobalQueue.initiated) {
        action()
    }

}

func performInBackground(action: () -> Void) {

    dispatch_async(GlobalQueue.utility) {
        action()
    }

}

func performLowPriority(action action: () -> Void) {

    dispatch_async(GlobalQueue.utility) {
        action()
    }

}

func performOnMainAfter(seconds: Int, action: () -> Void) {

    let delay = UInt64(seconds) * NSEC_PER_SEC
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
    dispatch_after(time, GlobalQueue.main) {
        action()
    }

}



struct GlobalQueue {
    static var main: dispatch_queue_t {
        return dispatch_get_main_queue()
    }

    static var interactive: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.rawValue), 0)
    }

    static var initiated: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)
    }

    static var utility: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.rawValue), 0)
    }

    static var background: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.rawValue), 0)
    }

    static var defaultQueue: dispatch_queue_t {
        return dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.rawValue), 0)
    }
}



// MARK: - Alert Controller Functions

extension UIViewController {

    func displayOneButtonAlert(title: String?, message: String?) {

        if message != nil {
            print("Error: \(message)")
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        performOnMain {
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
}

