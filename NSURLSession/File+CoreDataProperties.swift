//
//  File+CoreDataProperties.swift
//  NSURLSession
//
//  Created by Waleed Alware on 2/10/16.
//  Copyright © 2016 Waleed Alware. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension File {

    @NSManaged var fileName: String?
    @NSManaged var fileURL: String?
    @NSManaged var filePath: String?
    @NSManaged var isDownloaded: NSNumber?

}
