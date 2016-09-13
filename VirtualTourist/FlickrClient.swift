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

    var stack: CoreDataStack {

        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate.stack

    }

    

    // ******************************************************
    //   MARK: - Functions
    // ******************************************************

    /// Get Photos from Flickr when a pin is dropped.
    func getPhotosForPin(longitude longitude: String, latitude: String, pin: Pin, completionHandler: (result: AnyObject?, error: String?) -> Void) {

        let url = buildFlickrAPIURL(longitude: longitude, latitude: latitude)

        let request = NSMutableURLRequest(URL: url)

        makeAPIRequest(request) { (result, error) in

            guard let data = result as? NSData else {
                completionHandler(result: nil, error: error?.localizedDescription)
                return
            }

            guard let jsonData = self.parseJSONData(data) else {
                completionHandler(result: nil, error: "Unable to Parse JSON Data")
                return
            }

            guard let photos = jsonData[ResponseKeys.photos] as? [String: AnyObject] else {
                completionHandler(result: nil, error: errors.noData.rawValue)
                return
            }

            guard let totalPhotos = (photos[ResponseKeys.total] as? NSString)?.integerValue else {
                completionHandler(result: nil, error: errors.noData.rawValue)
                return
            }

            guard totalPhotos > 0 else {
                completionHandler(result: nil, error: errors.noPhotos.rawValue)
                return
            }

            guard let photoArray = photos[ResponseKeys.photoArray] as? [[String: AnyObject]] else {
                completionHandler(result: nil, error: errors.noPhotoArray.rawValue)
                return
            }

            completionHandler(result: photoArray, error: nil)
        }


    }

    /// Get Image From URL.
    func getImageFromURL(url: String, completionHandler: (result: AnyObject?, error: String?) -> Void) {

        guard let url = NSURL(string: url) else {
            completionHandler(result: nil, error: "No URL")
            return
        }

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





// ******************************************************
//   MARK: - Constants
// ******************************************************

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

    struct ResponseKeys {
        static let photos = "photos"
        static let photoArray = "photo"
        static let total = "total"
    }

    enum errors: String {
        case noPhotos = "No Photos Returned from Flickr."
        case noData = "No Data Returned."
        case noPhotoArray = "Unable to get the Photo Collection from Data."
    }

}
