//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Guillermo Diaz on 4/22/17.
//  Copyright © 2017 Guillermo Diaz. All rights reserved.
//

import UIKit

class PhotoAlbumCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var photo: Photo? {
        didSet {
            if let imageData = photo?.path as? Data {
                imageView.image = UIImage(data: imageData)
                imageView.contentMode = .scaleAspectFill
            } else {
                if let imageDownloadPath = photo?.downloadPath {
                    self.showActivityIndicator()
                    imageView.downloadImageWithURL(urlString: imageDownloadPath) { data, error in
                        if error != nil {
                            print(error)
                        }
                        performUIUpdatesOnMain {
                            self.imageView.image = UIImage(data: data!)
                            
                            self.imageView.contentMode = .scaleAspectFill
                            self.photo?.path = data! as NSData?
                            
                            (UIApplication.shared.delegate as! AppDelegate).saveContext()
                            
                            self.hideActivityIndicator()
                            
                            
                        }
                        
                    }
                }
            }
        }
    }
    var activityIndicator = UIActivityIndicatorView()
    
    func showActivityIndicator(){
        activityIndicator.center = CGPoint(x: contentView.frame.size.width/2, y: contentView.frame.size.height/2)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .gray
        addSubview(activityIndicator)
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    
    func hideActivityIndicator(){
        activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
}
