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
    @IBOutlet weak var bottomButton: UIButton!
    
    var context = AppDelegate.viewContext
    var pinSelected:Pin!
    var selectedPhotosIndexPath = [IndexPath]()
    var currentPage = 0
    
    var fetchedResultsController: NSFetchedResultsController<Photo> = NSFetchedResultsController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.update()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func photoListFetchedResultsController() -> NSFetchedResultsController<Photo> {
        let fetchedResultController = NSFetchedResultsController(fetchRequest: photoFetchRequest(),
                                                                 managedObjectContext: context,
                                                                 sectionNameKeyPath: nil,
                                                                 cacheName: nil)
        fetchedResultController.delegate = self
        
        performFetchFor(fetchedResultController)
        
        return fetchedResultController
    }
    
    func performFetchFor(_ fetchedResultController: NSFetchedResultsController<Photo>) {
        do {
            try fetchedResultController.performFetch()
        } catch let error as NSError {
            fatalError("Error: \(error.localizedDescription)")
        }
    }
    
    func photoFetchRequest() -> NSFetchRequest<Photo> {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin = %@", self.pinSelected)
        
        return fetchRequest
    }
    
    
    func update() {
        fetchedResultsController = photoListFetchedResultsController()
        updatePhotos()
        
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
        //let lineSpacing = (self.view.frame.size.height - (2 * space)) / 35.0
        // Change the CollectionViewCell dimensions and separecions between cells
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
    }
    
    func updatePhotos() {
        print("Update Photos", currentPage)
        let photos = fetchedResultsController.fetchedObjects
        print(photos!.isEmpty)
        if photos!.isEmpty == true {
            FlickrClient.sharedInstance.getImagesFromFlickr(pinSelected, currentPage, context: context) { success, error in
                if error != nil {
                    print("Error downloading image")
                }
                performUIUpdatesOnMain {
                  self.photoCollection.reloadData()
                }
                
            }
        }
        currentPage += 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let quotes = fetchedResultsController.fetchedObjects else { return 0 }
        print(quotes.count)
        return quotes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoAlbumCell else {
            fatalError("Unexpected Index Path")
        }
        
        let photo = fetchedResultsController.object(at: indexPath)
        
        photoCell.photo = photo
        
        return photoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCell
        
        let index = selectedPhotosIndexPath.index(of: indexPath)
        
        if let index = index {
            selectedPhotosIndexPath.remove(at: index)
            selectedCell.imageView.alpha = 1.0
        } else {
            selectedPhotosIndexPath.append(indexPath)
            selectedCell.imageView.alpha = 0.25
        }
        print(selectedPhotosIndexPath)
        if selectedPhotosIndexPath.count > 0 {
            bottomButton.setTitle("Remove Selected Pictures", for: .normal)
        } else {
            bottomButton.setTitle("New Collection", for: .normal)
        }
        
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .delete:
            if let indexPath = indexPath {
                photoCollection.deleteItems(at: [indexPath])
           }
            break
        default:
            break
        }
    }
    
    @IBAction func bottonButtomSelected(_ sender: UIButton) {
        if selectedPhotosIndexPath.count > 0 {
            var photosToDelete = [Photo]()
            for indexPath in selectedPhotosIndexPath {
                let photo = fetchedResultsController.object(at: indexPath)
                photosToDelete.append(photo)
            }
            for photo in photosToDelete {
                fetchedResultsController.managedObjectContext.delete(photo)
                do {
                    try self.context.save()
                } catch {
                    print("There was a problem while saving to the database")
                }
            }
            selectedPhotosIndexPath = [IndexPath]()
            bottomButton.setTitle("New Collection", for: .normal)
        } else {
            let photos = fetchedResultsController.fetchedObjects
            
            for photo in photos! {
                context.delete(photo)
            }
            performFetchFor(self.fetchedResultsController)
            updatePhotos()
        }
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
