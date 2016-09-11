//
//  Networkable.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import UIKit


protocol Networkable {

    func makeAPIRequest(request: NSMutableURLRequest, completionHandler: (result: AnyObject?, error: NSError?) -> Void)

}

extension Networkable {

    /// Perform API requests and check for the appropriate errors.
    func makeAPIRequest(request: NSMutableURLRequest, completionHandler: (result: AnyObject?, error: NSError?) -> Void) {

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in

            // Sending Errors
            func sendError(message: String) {
                print(message)
                print("Error: \(error)")
                print("Response: \(response)")

                let userInfo = [NSLocalizedDescriptionKey: message]
                let code = (response as? NSHTTPURLResponse)?.statusCode ?? 1
                completionHandler(result: nil, error: NSError(domain: "APIRequest", code: code, userInfo: userInfo))
            }

            // Next 4 guard statements validate we did not recieve an error and
            // the data we received is valid.
            guard error == nil else {
                sendError(error?.localizedDescription ?? "There was an error with your request")
                return
            }

            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError(error?.localizedDescription ?? "There was an error with your request")
                return
            }

            guard let data = data else {
                sendError("No Data Returned with your request")
                return
            }

            guard let result = self.parseJSONData(data) else {
                sendError("Unable to Parse Data")
                return
            }

            completionHandler(result: result, error: nil)
            
        }
        
        task.resume()
        
    }


    /// Parse returned data into readable JSON.
    func parseJSONData(data: NSData) -> AnyObject? {

        // Delete the first 5 characters in the data. (Udacity Specific Thing)
        let newData = data.subdataWithRange(NSMakeRange(14, data.length - 15))

        // Parse data into JSON
        var jsonData: AnyObject!
        do {
            jsonData = try NSJSONSerialization.JSONObjectWithData(newData, options: .AllowFragments)
        } catch {
            print("Unable to deserialize JSON data")
            return nil
        }

        print("JSON Data parsed: \n\(jsonData)")

        return jsonData
    }


}