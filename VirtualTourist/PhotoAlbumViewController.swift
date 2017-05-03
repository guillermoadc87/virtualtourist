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
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    var context: NSManagedObjectContext!
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
        
        //let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        //let request = NSBatchDeleteRequest(fetchRequest: fetch)
        //try! context.execute(request)
        self.update()
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
    
    func update() {
        print("Update Photos")
        let photos = fetchedResultsController.fetchedObjects
        if photos!.isEmpty == true {
            FlickrClient.sharedInstance.getImagesFromFlickr(pinSelected, context: context) { success, error in
                if error != nil {
                    print("Error downloading image")
                }
            }
        }
        
        self.mapView.isZoomEnabled = false;
        self.mapView.isScrollEnabled = false;
        self.mapView.isUserInteractionEnabled = false;
        
        if let pin = pinSelected {
            //Add Pin to Map
            var annotations = [MKPointAnnotation]()
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
            mapView.addAnnotation(annotation)
            
            // Zoom the map to the Pin location
            let latDelta: CLLocationDegrees = 0.05
            let lonDelta: CLLocationDegrees = 0.05
            let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
            let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pinSelected.latitude, pinSelected.longitude)
            let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
            mapView.setRegion(region, animated: true)
        }
        
        let space: CGFloat = 3.0
        let dimension = (self.view.frame.size.width - (2 * space)) / 3.0
        let lineSpacing = (self.view.frame.size.height - (2 * space)) / 35.0
        // Change the CollectionViewCell dimensions and separecions between cells
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = lineSpacing
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
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
        print("Aqui estoy")
        if photo.path != nil {
            photoCell.imageView.image = UIImage(data: photo.path as! Data)
        } else {
            FlickrClient.sharedInstance.getDataFromUrl(photo.downloadPath!) { imageData, error in
                guard let imageData = imageData else {
                    self.displayAlert(title: "Image data error", message: error)
                    return
                }
                
                photo.path = imageData as! NSData
                performUIUpdatesOnMain {
                    photoCell.imageView.image = UIImage(data: photo.path as! Data)
                    do {
                        try self.context.save()
                    } catch {
                        print("There was a problem while saving to the database")
                    }
                }
                
            }
        }
        
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
