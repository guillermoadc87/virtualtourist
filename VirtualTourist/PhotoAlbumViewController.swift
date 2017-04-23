//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Guillermo Diaz on 4/22/17.
//  Copyright © 2017 Guillermo Diaz. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    
    var context = AppDelegate.viewContext
    var pinSelected:Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try self.fetchedResultsController.performFetch()
            
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        try! context.execute(request)
        self.updatePhotos()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "path", ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.pinSelected)
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    func updatePhotos() {
        print("Update Photos")
        let photos = fetchedResultsController.fetchedObjects
        if photos!.isEmpty == true {
            FlickrClient.sharedInstance.getImagesFromFlickr(pinSelected) { success, error in
                print("Aqui regrese",success!)
                if error != nil {
                    print("Error downloading image")
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let quotes = fetchedResultsController.fetchedObjects else { return 0 }
        return quotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoAlbumCell else {
            fatalError("Unexpected Index Path")
        }
        
        let photo = fetchedResultsController.object(at: indexPath)
        print(photo.path!)
        photoCell.imageView.image = UIImage(contentsOfFile: photo.path!)
        
        return photoCell
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
