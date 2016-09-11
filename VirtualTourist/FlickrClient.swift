//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jason Lemrond on 9/10/16.
//  Copyright © 2016 Jason Lemrond. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: Networkable {

    // ******************************************************
    //   MARK: - Variables
    // ******************************************************

    static let sharedInstance = FlickrClient()

    let session = NSURLSession.sharedSession()

    

    // ******************************************************
    //   MARK: - Functions
    // ******************************************************

    func getPhotosFromCoordinates(longitude longitude: String, latitude: String, completionHandler: (result: AnyObject?, error: String?) -> Void) {

        let url = buildFlickrAPIURL(longitude: longitude, latitude: latitude)

        let request = NSMutableURLRequest(URL: url)

        makeAPIRequest(request) { (result, error) in
            guard error == nil else {
                completionHandler(result: nil, error: error?.localizedDescription)
                return
            }

            completionHandler(result: result, error: nil)
        }


    }


    func buildFlickrAPIURL(longitude longitude: String, latitude: String) -> NSURL {

        // Need query items

        let quereyItems: [NSURLQueryItem] = [
            NSURLQueryItem(name: QueryKeys.method, value: QueryValues.method),
            NSURLQueryItem(name: QueryKeys.apiKey, value: QueryValues.APIKey),
            NSURLQueryItem(name: QueryKeys.latitude, value: latitude),
            NSURLQueryItem(name: QueryKeys.longitude, value: longitude),
            NSURLQueryItem(name: QueryKeys.limit, value: QueryValues.limit),
            NSURLQueryItem(name: QueryKeys.extras, value: QueryValues.url),
            NSURLQueryItem(name: QueryKeys.format, value: QueryValues.format)
        ]

        let components = NSURLComponents()
        components.scheme = URL.scheme
        components.host = URL.host
        components.path = URL.path
        components.queryItems = quereyItems
        
        return components.URL!

    }

}


extension FlickrClient {

    struct URL {
        static let scheme = "https"
        static let host = "api.flickr.com"
        static let path = "/services/rest/"
    }

    struct QueryKeys {
        static let method = "method"
        static let apiKey = "api_key"
        static let latitude = "lat"
        static let longitude = "lon"
        static let limit = "per_page"
        static let extras = "extras"
        static let format = "format"
    }

    struct QueryValues {
        static let method = "flickr.photos.search"
        static let APIKey = "c1c38b6706c66e7c9f9d2538b6509d99"
        static let limit = "24"
        static let url = "url_z"
        static let format = "json"

    }

}
