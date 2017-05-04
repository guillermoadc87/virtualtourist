//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Guillermo Diaz on 4/13/17.
//  Copyright © 2017 Guillermo Diaz. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editLabel: UILabel!
    
    var isEditMode = false
    
    let context = AppDelegate.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.editLabel.frame.origin.y = self.editLabel.frame.origin.y + self.editLabel.frame.height
        print(self.editLabel.frame.origin.y + self.editLabel.frame.height, self.editLabel.frame.origin.y)
        // Do any additional setup after loading the view, typically from a nib.
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(handleTap(gestureReconizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        loadAnnotations()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func handleTap(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizerState.ended {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            let pin:Pin = Pin(context: context)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            
            do {
                try context.save()
            } catch {
                print("There was a problem while saving to the database")
            }
            mapView.addAnnotation(annotation)
        }
    }
    
    func loadAnnotations(){
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            let searchResults = try context.fetch(fetchRequest)
            print("number of locations: \(searchResults.count)")
            var annotations = [MKPointAnnotation]()
            for result in searchResults as [Pin]{
                let latitude = CLLocationDegrees(result.latitude)
                let longitude = CLLocationDegrees(result.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
                //pins.append(result)
            }
            performUIUpdatesOnMain {
                self.mapView.addAnnotations(annotations)
                print("annotations added to the map view.")
            }
        }
        catch {
            print("Error: \(error)")
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        let latitude = view.annotation?.coordinate.latitude
        let longitude = view.annotation?.coordinate.longitude
        print("selected pin's lat:\(latitude), lon:\(longitude)")
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        //fetchRequest.predicate = NSPredicate(format: "pin.latitude = %@ AND pin.longitude = %@", latitude!, longitude!)
        do {
            let searchResults = try context.fetch(fetchRequest)
            for pin in searchResults as [Pin] {
                if pin.latitude == latitude!, pin.longitude == longitude! {
                    print("Found pin")
                    if isEditMode {
                        //Delete selectedPin
                        performUIUpdatesOnMain {
                            self.context.delete(pin)
                            do {
                                try self.context.save()
                            } catch {
                                print("There was a problem while saving to the database")
                            }
                            self.mapView.removeAnnotation(view.annotation!)
                            print("Deleted the selected pin.")
                        }
                    } else {
                        //Perform segue to the photo album
                        print("Perform segue to the photo album.")
                        self.performSegue(withIdentifier: "PhotoAlbum", sender: pin)
                        //performUIUpdatesOnMain {
                            
                        //}
                    }
                }
            }
        }catch {
            print("Error: \(error)")
        }
        
    }
    
    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        isEditMode = !isEditMode
        editLabel.isHidden = !isEditMode
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PhotoAlbum" {
            
            let photoAlbumController = segue.destination as! PhotoAlbumViewController
            photoAlbumController.pinSelected = sender as! Pin
            
        }
    }
}


