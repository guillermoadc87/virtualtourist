//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Guillermo Diaz on 4/20/17.
//  Copyright © 2017 Guillermo Diaz. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }
    
    @NSManaged public var downloadPath: String?
    @NSManaged public var path: String?
    @NSManaged public var pin: Pin?

}
