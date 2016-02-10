//
//  ViewController.swift
//  NSURLSession
//
//  Created by Waleed Alware on 2/10/16.
//  Copyright © 2016 Waleed Alware. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSURLSessionDelegate,UIDocumentInteractionControllerDelegate
{
	// Managedobjectcontext
	let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
	// An array to hold fetchrequest of all files
	var fileArray = NSArray()
	// An array for selected files to download
	var downloadArray = NSMutableArray()
	// An array for selected Buttons to maintain button selected states
	var selectedButtonsArray = NSMutableArray()
	// NSURLSession variable
	var session = NSURLSession()
	// Document Directory URL variable to save the downloaded file
	var docDirectoryURL = NSURL()
	// Button to add to navigation bar when at least one file selected
	var downloadButton = UIBarButtonItem()
	
	@IBOutlet weak var fileTableView: UITableView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Initialize document directory
		docDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last! as NSURL
		// Initialize background session
		let sessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.kFiles")
		session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
		// Fetch all files from core data
		let fetchRequest = NSFetchRequest(entityName: "File")
		
		do {
			self.fileArray = try self.context.executeFetchRequest(fetchRequest) as! [File]
			
		} catch let error as NSError {
			// failure
			print("Fetch failed: \(error.localizedDescription)")
		}
	}
	
	// MARK: TableView
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.fileArray.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! CustomCell
		
		let file = fileArray[indexPath.row] as! File
        
        file.tag = indexPath.row
        
		cell.fileTitleLabel.text = file.fileName
		
		if (file.isDownloaded != NSNumber(bool: false))
		{
			// File is downloaded and can be read
			// Hide the select button and progress view and show the read button
			cell.selectButton.hidden = true
			cell.progressView.hidden = true
			cell.readButton.hidden = false
		}
		else
		{
			// File is not downloaded show the select button to download
			// Show the select button and progress view and hide the read button
			cell.readButton.hidden = true
		}
		
        //Check button state if selected or not
        if selectedButtonsArray.containsObject(indexPath.row)
        {
            cell.selectButton.selected = true
        }
        else
        {
            cell.selectButton.selected = false
        }
        
		// Set select button tag and read button tag equal to index of the file managedobject
		cell.selectButton.tag = indexPath.row
        cell.selectButton.setImage(UIImage(named: "selected"), forState: .Selected)
		cell.selectButton.addTarget(self, action: "downLoadFiles:", forControlEvents: .TouchUpInside)
		cell.readButton.tag = indexPath.row
		cell.readButton.addTarget(self, action: "openPDF:", forControlEvents: .TouchUpInside)
		
		// setup the progress view images
		cell.progressView.trackImage = UIImage(named: "track")
		cell.progressView.progressImage = UIImage(named: "progress")
		
		return cell
	}
	
    // MARK: Select And Open Buttons Actions
    @IBAction func downLoadFiles(sender: UIButton)
    {
        let updateFile = self.fileArray.objectAtIndex(sender.tag) as! File
        
        var dict = NSMutableDictionary()
        
        let cell = self.fileTableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0))
        
        let predicate = NSPredicate(format: "tag == %d", sender.tag)
        let tempArray = downloadArray.filteredArrayUsingPredicate(predicate)
        
        if tempArray.count == 0
        {
            let cellIndexPath = NSIndexPath(forRow: sender.tag, inSection: 0)
            dict.setValue(updateFile, forKey: "object")
            dict.setValue(cellIndexPath, forKey: "indexPath")
            dict.setValue(sender.tag, forKey: "tag")
            downloadArray.addObject(dict)
            sender.selected = true
            updateFile.selected = true
            selectedButtonsArray.addObject(sender.tag)
        }
        else
        {
            dict = tempArray[0] as! NSMutableDictionary
            downloadArray.removeObject(dict)
            sender.selected = false
            cell?.selected = false
            updateFile.selected = false
            selectedButtonsArray.removeObject(sender.tag)
        }
        
        //Add download button to navigation bar
        downloadButton = UIBarButtonItem(title: "Download (\(downloadArray.count))", style: UIBarButtonItemStyle.Done, target: self, action: "startDownloads")
        
        self.navigationItem.leftBarButtonItem = downloadButton
        
    }
    
    // MARK: Action for opening PDF file
    @IBAction func openPDF(sender: UIButton)
    {
        let pdfFile = self.fileArray.objectAtIndex(sender.tag) as! File
        print(pdfFile)
        let pdfPath = pdfFile.filePath
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        let documentDirectory:NSURL = urls.first!
        let fileURL = documentDirectory.URLByAppendingPathComponent(pdfPath!)
        
        print("FileURL: \(fileURL)")
        
        let documentInteractionController = UIDocumentInteractionController(URL: fileURL)
        documentInteractionController.delegate = self
        documentInteractionController.presentPreviewAnimated(true)
    }
    
    func documentInteractionControllerViewControllerForPreview(controller: UIDocumentInteractionController) -> UIViewController
    {
        return self.navigationController!
    }

    // MARK: Start download session for selected files
    func startDownloads()
    {
        var i = 0
        for (i = 0; i < downloadArray.count; i++)
        {
            let updateFile = downloadArray.objectAtIndex(i) ["object"] as! File
            let dict = downloadArray.objectAtIndex(i) as! NSMutableDictionary
            let fileURL = NSURL(string: updateFile.fileURL!)
            updateFile.downloadTask = self.session.downloadTaskWithURL(fileURL!)
            updateFile.taskIdentifier = updateFile.downloadTask.taskIdentifier
            dict.setValue(updateFile.taskIdentifier, forKey: "ident")
            dict.setObject(updateFile.downloadTask, forKey: "downloadtask")
            do
            {
                try self.context.save()
                // print("Updateing Identifier: \(updateFile.taskIdentifier)")
            }
            catch
            {
                print("Unable to save")
            }
            
            updateFile.downloadTask.resume()
            dispatch_async(dispatch_get_main_queue(), {() -> Void in
                self.downloadButton.title = ""
            })
        }
        
    }

    // MARK: NSURLSession Delegates
    // Delegate for any encountered error during download
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("session error: \(error?.localizedDescription).")
    }
    
    // Delegate after the file finish downloading
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
        let predicate = NSPredicate(format: "ident == %d", downloadTask.taskIdentifier)
        
        let arr = self.downloadArray.filteredArrayUsingPredicate(predicate)
        let downloadedFile = arr[0] ["object"] as! File
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentDirectoryPath: String = path[0]
        let downloadedFileName = downloadTask.response?.suggestedFilename
        let fileManager = NSFileManager()
        let destinationURLForFile = NSURL(fileURLWithPath: documentDirectoryPath.stringByAppendingString("/\(downloadedFileName!)"))
        
        if (fileManager.fileExistsAtPath(destinationURLForFile.path!))
        {
            print("File exist")
            
        }
        else
        {
            // Move from temp to document
            do
            {
                try fileManager.moveItemAtURL(location, toURL: destinationURLForFile)
                // we saved the file, now lets update core data with filename and set isdownloaded to 1
                downloadedFile.isDownloaded = NSNumber(bool: true)
                downloadedFile.filePath = downloadedFileName
                
                do
                {
                    try context.save()
                    
                    dispatch_async(dispatch_get_main_queue(), {() -> Void in
                        let index = arr[0] ["tag"] as! Int
                        let indexpath = NSIndexPath(forRow: index, inSection: 0)
                        self.fileTableView.reloadRowsAtIndexPaths([indexpath], withRowAnimation: .Fade)
                    })
                    
                }
                catch
                {
                    print(error)
                }
                
            }
            catch
            {
                print(error)
            }
        }
    }
    
    // Delegate progress of download
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let predicate = NSPredicate(format: "ident == %d", downloadTask.taskIdentifier)
        let arr = self.downloadArray.filteredArrayUsingPredicate(predicate)
        print("Written: \(totalBytesWritten)  Out Of: \(totalBytesExpectedToWrite)")
        let progress = Float(totalBytesWritten / totalBytesExpectedToWrite)
        let row = arr[0] ["tag"] as! Int
        let indexpath : NSIndexPath = NSIndexPath(forRow: row, inSection: 0)
        print("ROW: \(row)  PROGRESS: \(progress)")
        
        dispatch_async(dispatch_get_main_queue(), {() -> Void in
            if let cell = self.fileTableView.cellForRowAtIndexPath(indexpath) as? CustomCell
            {
                cell.progressView.hidden = false
                cell.progressView.progress = progress
            }
        })
    }
    
	// MARK: Initial Core Data Setup
	@IBAction func setupCoreData()
	{
		let plistFilePath = NSBundle.mainBundle().pathForResource("FileList", ofType: "plist")
		let fileListArray = NSArray(contentsOfFile: plistFilePath!)
		
		for dict in fileListArray!
		{
			let title = dict["fileName"] as! String
			let fileURL = dict["fileURL"] as! String
			
			let fileEntity = NSEntityDescription.insertNewObjectForEntityForName("File", inManagedObjectContext: context) as! File
			fileEntity.fileName = title
			fileEntity.fileURL = fileURL
			fileEntity.isDownloaded = 0
			fileEntity.taskIdentifier = -1
			
			do
			{
				try context.save()
				// print("Saving")
			}
			catch
			{
				print("Unable to save")
			}
		}
		
        
		refreshTableview()
	}
	
	// MARK: Function to refresh Tableview with fetch request
	func refreshTableview()
	{
		let fetchRequest = NSFetchRequest(entityName: "File")
		do {
			self.fileArray = try self.context.executeFetchRequest(fetchRequest) as! [File]
			self.fileTableView.reloadData()
		} catch let error as NSError {
			// failure
			print("Fetch failed: \(error.localizedDescription)")
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
}

