//
//  Helper.swift
//  OnTheMap
//
//  Created by Guillermo Diaz on 4/4/17.
//  Copyright © 2017 Guillermo Diaz. All rights reserved.
//


import UIKit

extension UIViewController {
    
    // Alert
    func displayAlert(title:String, message:String?) {
        
        if let message = message {
                let alert = UIAlertController(title: title, message: "\(message)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
        }
    }
}

extension UIImageView {
    
    func downloadImageWithURL(urlString: String, completionHandler: @escaping (_ data: Data?, _ error: NSError?) -> Void) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                completionHandler(nil, error as NSError?)
                return
            }
            
            completionHandler(data, nil)
        }.resume()
        
    }
    
}
