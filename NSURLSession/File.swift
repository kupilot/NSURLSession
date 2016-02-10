//
//  File.swift
//  NSURLSession
//
//  Created by Waleed Alware on 2/10/16.
//  Copyright © 2016 Waleed Alware. All rights reserved.
//

import Foundation
import CoreData

class File: NSManagedObject
{
	
	// Variables that are not to be saved in core data, but help during download session
	var downloadTask = NSURLSessionDownloadTask()
	var progress = 0.0
	var isDwonloading = false
	var selected = false
	var indexPath = NSIndexPath()
	var tag = 0
	var taskIdentifier = -1
	
}
