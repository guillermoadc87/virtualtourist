//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Guillermo Diaz on 4/22/17.
//  Copyright © 2017 Guillermo Diaz. All rights reserved.
//

import Foundation

import UIKit
import CoreData

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    var session = URLSession.shared
    
    // MARK: Flickr
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Latitude = "lat"
        static let Longitude = "lon"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "d4b0b6cb1ad5deffec9bf8213ee85fdc"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }
    

    
    // MARK: Flickr API
    
    func getImagesFromFlickr(_ selectedPin: Pin, _ page: Int, context: NSManagedObjectContext, _ completionHandler: @escaping (_ success: Bool?, _ error: NSError?) -> Void) {
        
        let methodParameters: [String:String] = [
            FlickrParameterKeys.Method: FlickrParameterValues.SearchMethod,
            FlickrParameterKeys.APIKey: FlickrParameterValues.APIKey,
            FlickrParameterKeys.BoundingBox: bboxString(longitude:selectedPin.longitude , latitude: selectedPin.latitude),
            FlickrParameterKeys.Latitude: "\(selectedPin.latitude)",
            FlickrParameterKeys.Longitude: "\(selectedPin.longitude)",
            FlickrParameterKeys.PerPage: "21",
            FlickrParameterKeys.Page: "\(page)",
            FlickrParameterKeys.SafeSearch: FlickrParameterValues.UseSafeSearch,
            FlickrParameterKeys.Extras: FlickrParameterValues.MediumURL,
            FlickrParameterKeys.Format: FlickrParameterValues.ResponseFormat,
            FlickrParameterKeys.NoJSONCallback: FlickrParameterValues.DisableJSONCallback
        ]
        // create session and request
        
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        let task = taskForGETMethod(request: request) { (parsedResult, error) in
            
            // display error
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(false, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult?[FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult?[FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            performUIUpdatesOnMain {
                
                //let photo:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context ) as! Photo

                
                for photo in photosArray {
                    guard let urlString = photo[FlickrResponseKeys.MediumURL] as? String else {
                        displayError("Cannot find key '\(FlickrResponseKeys.MediumURL)' in \(photosArray)")
                        return
                    }
                    
                    let photo:Photo = Photo(context: context)
                    
                    //print("\(imageURL)")
                    photo.downloadPath = urlString
                    selectedPin.addToPhotos(photo)
                    //imageUrlStrings.append(photo)
                    do {
                        try context.save()
                    } catch {
                        print("There was a problem while saving to the database")
                    }

                    
                    
                    completionHandler(true, nil)
                }
                
            }
            
        }
        
        // start the task!
        task.resume()
    }
    
    // MARK: Helpers
    
    // MARK: GETMethod
    private func taskForGETMethod(request:URLRequest, _ completionHandlerForGET: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void)-> URLSessionDataTask {
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // display error
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        task.resume()
        return task
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    // given a dictionary of parameters, covert unsafe ASCII characters and correctly formated url string.
    func escapedParameters(_ parameters: [String:AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                // make sure that it is a string value
                let stringValue = "\(value)"
                
                // escape it
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                // append it
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
                
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    func bboxString(longitude:Double, latitude:Double) -> String {
        let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
}
