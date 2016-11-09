//
//  FilesTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 17/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import AVKit
import AVFoundation
import MZFormSheetPresentationController
import PutioKit

class FilesTableViewController: UITableViewController, AVPlayerViewControllerDelegate, FilesToolbarDelegate, UIViewControllerPreviewingDelegate {
    
    
    // MARK: - Variables
    
    let types = ["video/mp4", "text/plain", "image/jpeg", "image/png", "image/jpg", "audio/mp3", "audio/mpeg"]
    let image_types = ["image/jpeg", "image/png", "image/jpg"]
    let audio_types = ["audio/mp3", "audio/mpeg"]
    
    lazy var files: [File] = []
    var selectedFile: File?
    var params: [String:String]!
    var overlay: LoaderView?
    var noFiles: UIView?
    var castHandler: CastHandler?
    var navController: FilesNavViewController?
    
    
    // MARK: - Loading and Unloading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the refresh control target
        refreshControl?.addTarget(self, action: #selector(refresh), forControlEvents: UIControlEvents.ValueChanged)
        refreshControl?.enabled = false
        
        // Add the loader overlay
        overlay = LoaderView(frame: view.frame)
        tableView.addSubview(overlay!.view)
        
        // Setup No Files View
        setupNoFiles()
        
        // Parameters
        params = setParams()
        
        // Fetch the files
        fetchFiles()
        
        // Casting
        castHandler = CastHandler.sharedInstance
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Edit", style: .Plain, target: self, action: #selector(toggleTableEditing)),
            castHandler!.button!
        ]
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        if(traitCollection.forceTouchCapability == .Available){
            registerForPreviewingWithDelegate(self, sourceView: view)
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let tc = tabBarController as? FilesTabViewController {
            tc.toolbarDelegate = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        selectedFile = nil
    }
    
    
    
    // MARK: - Parameter
    
    /// Set the default parameters for Alamofire
    func setParams() -> [String:String] {
        return ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
    }
    
    

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("fileReuse", forIndexPath: indexPath)
        
        let file = files[indexPath.row]
        
        
        // Cell the label to the file name
        cell.textLabel?.text = file.name
        
        // Hide the accesory if it's NOT a directory
        if( types.contains(file.content_type!) || file.has_mp4 ) {
            cell.accessoryType = .DetailButton
        } else if(file.content_type == "application/x-directory") {
            cell.accessoryType = .DisclosureIndicator
        } else {
            cell.accessoryType = .None
        }
        
        // Show images
        
        var imageName: String = (file.accessed) ? "document" : "document-new"
        
        if(file.content_type == "video/mp4" || file.has_mp4) {
            imageName = (file.accessed) ? "video" : "video-new"
        } else if(file.content_type == "application/x-directory") {
            imageName = "folder"
        } else if(image_types.contains(file.content_type!)) {
            imageName = (file.accessed) ? "image" : "image-new"
        } else if(audio_types.contains(file.content_type!)) {
            imageName = (file.accessed) ? "audio" : "audio-new"
        }
        
        cell.imageView?.image = UIImage(named: imageName)
        
        return cell
    }
    
    
    
    
    // MARK: - Editing Files
    
    /// Check if the file was shared with us, if it was we can't delete it
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return !files[indexPath.row].is_shared
    }
    
    /// This is needed to enable the editing for some reason...
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    /// Add the actions to the row
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let moreAction = UITableViewRowAction(style: .Normal, title: "More", handler: moreHandler)
        moreAction.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: deleteFile)
        
        return [deleteAction, moreAction]
    }
    
    /// Handler for the more action
    func moreHandler(action: UITableViewRowAction!, indexPath: NSIndexPath!) {
        let alert = FetchAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        alert.addAction(UIAlertAction(title: "Move File", style: UIAlertActionStyle.Default) { alertAction in
            self.moveFile(action, indexPath: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "Rename File", style: UIAlertActionStyle.Default) { alertAction in
            self.renameFile(action, indexPath: indexPath)
        })
        
        let file = self.files[indexPath.row]
        if file.content_type == "video/mp4" || file.has_mp4 {
            alert.addAction(UIAlertAction(title: "Download File", style: UIAlertActionStyle.Default) { alertAction in
                self.addFileToQueue(file)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ action in
            self.tableView.setEditing(false, animated: true)
        })
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.width-5, y: 0, width: 80, height: cell.frame.height)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    /**
     Add the file to the download queue
     
     - parameter file: The file to add to the queue
     */
    func addFileToQueue(file: File) {
        if !Downloader.sharedInstance.queue.contains({ $0 == file }) {
            Downloader.sharedInstance.queue.append(file)
        }
        tableView.setEditing(false, animated: true)
    }
    
    /// Handler for the move action
    func moveFile(action: UITableViewRowAction!, indexPath: NSIndexPath!) {
        
        tableView.setEditing(false, animated: true)
        
        let vc: UINavigationController = UIStoryboard(name: "MoveFiles", bundle: nil).instantiateInitialViewController() as! UINavigationController

        vc.modalPresentationStyle = .FormSheet
        
        let child = vc.childViewControllers[0] as! MoveFilesTableViewController
        child.filesToMove = [files[indexPath.row]]
        child.tableController = self
        
        
        presentViewController(vc, animated: true, completion: nil)
        
    }
    
    /// Handler for the rename action
    func renameFile(action: UITableViewRowAction!, indexPath: NSIndexPath!) {
        
        tableView.setEditing(false, animated: true)
        
        let alert = FetchAlertController(title: "Rename File", message: "Enter the new name of the file below", preferredStyle: .Alert)
        
        let file = files[indexPath.row]
        
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "New Name"
            textField.text = file.name
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .Default) { action in
            file.renameWithAlert(alert)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(alert, animated: true) {
//            let textField = alert.textFields![0] as! UITextField
//            textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
        }
        
        
    }
    
    /// Handler for the delete action
    func deleteFile(action: UITableViewRowAction!, indexPath: NSIndexPath!) {
        
        let alert = FetchAlertController(title: "Delete File", message: "Are you sure you want to delete: '\(files[indexPath.row].name!)'?", preferredStyle: .ActionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete File", style: .Destructive) { action in
            
            let file = self.files[indexPath.row]
            file.destroy()
            self.files.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            
            if self.files.count == 0 {
                self.noFiles!.hidden = false
            } else {
                self.noFiles!.hidden = true
            }
            
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel){ action in
            self.tableView.setEditing(false, animated: true)
        })
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.width+65, y: 0, width: 80, height: cell.frame.height)
        
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        
        if(segue.destinationViewController.isKindOfClass(DetailViewController)) {
            
            // Show the detail view
            let detailController: DetailViewController = segue.destinationViewController as! DetailViewController
            detailController.file = selectedFile
            
        } else if (sender == nil) {
            
            if(selectedFile?.content_type == "application/x-directory") {
                
                // Show the directory view
                let directoryController: DirectoryTableViewController = segue.destinationViewController as! DirectoryTableViewController
                directoryController.file = selectedFile
                
            } else if(selectedFile!.has_mp4 || selectedFile!.content_type == "video/mp4" || audio_types.contains(selectedFile!.content_type!)) {

                let fType = (audio_types.contains(selectedFile!.content_type!)) ? "audio" : "video"
                setupMediaHandler(segue, type: fType)
            
            } else if(selectedFile!.content_type == "text/plain") {
                
                let vc: TextViewController = segue.destinationViewController as! TextViewController
                vc.file = selectedFile
            
            } else if(image_types.contains(selectedFile!.content_type!)) {
                
                let vc: ImageHandlerViewController = segue.destinationViewController as! ImageHandlerViewController
                vc.file = selectedFile
                
            } else {
                
                // Show the detail view for the time being
                let detailController: DetailViewController = segue.destinationViewController as! DetailViewController
                detailController.file = selectedFile
                
            }
            
        }
        
    
    }
    
    /// Setup the media player
    func setupMediaHandler(segue: UIStoryboardSegue, type: String) {

        let videoController: MediaPlayerViewController = segue.destinationViewController as! MediaPlayerViewController
        videoController.file = selectedFile
            
        var urlString: String!
            
        if(type == "audio") {
            urlString = "\(Putio.api)files/\(selectedFile!.id)/stream?oauth_token=\(Putio.accessToken!)"
        } else {
            urlString = "\(Putio.api)files/\(selectedFile!.id)/hls/media.m3u8?oauth_token=\(Putio.accessToken!)&subtitle_key=all"
        }
        
        
        let url = NSURL(string: urlString)
        videoController.player = AVPlayer(URL: url!)
        videoController.delegate = PlayerDelegate.sharedInstance

    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        guard tableView.editing else {
           return indexPath
        }
        
        let file = files[indexPath.row]
        if file.is_shared {
            return nil
        }
        
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let tc = tabBarController as? FilesTabViewController {
            for item in (tc.toolbar!.items)! {
                item.enabled = (tableView.indexPathsForSelectedRows?.count > 0)
            }
        }
        
        guard !tableView.editing else {
            return
        }
        
        selectedFile = files[indexPath.row]
        selectedFile?.accessed = true
        tableView.reloadData()
        
        if(selectedFile?.content_type == "application/x-directory") {
            
            performSegueWithIdentifier("showDirectoryView", sender: nil)
            
        } else if(audio_types.contains(selectedFile!.content_type!)) {
            
            performSegueWithIdentifier("videoPlayer", sender: nil)
            
        } else if(selectedFile!.has_mp4 || selectedFile?.content_type == "video/mp4" || audio_types.contains(selectedFile!.content_type!)) {
            
            if castHandler?.device != nil {
                castHandler?.sendFile(selectedFile!) {
                    self.castHandler?.showRemote(self)
                }
            } else {
                performSegueWithIdentifier("videoPlayer", sender: nil)
            }
            
        } else if(selectedFile?.content_type == "text/plain") {
            
            performSegueWithIdentifier("textView", sender: nil)
            
        } else if(image_types.contains(selectedFile!.content_type!)) {
            
            performSegueWithIdentifier("imageView", sender: nil)
            
        } else {
            
            performSegueWithIdentifier("showDetailView", sender: nil)
            
        }
        
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let tc = tabBarController as? FilesTabViewController {
            for item in (tc.toolbar!.items)! {
                item.enabled = (tableView.indexPathsForSelectedRows?.count > 0)
            }
        }
    }
    
    /// Show the detail view when the (i) is clicked
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        selectedFile = files[indexPath.row]
        performSegueWithIdentifier("showDetailView", sender: nil)
    }
    
    
    // MARK: - Networking

    // CALL ON REFRESH
    func refresh(sender: UIRefreshControl) {
        refreshControl?.beginRefreshing()
        fetchFiles()
    }
    
    // FETCH LIST OF FILES
    func fetchFiles() {
        
        Files.fetchWithURL("\(Putio.api)files/list", params: setParams(), sender: self) { files in
            self.files = files
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
            self.overlay?.hideWithAnimation()
            
            if files.count == 0 {
                self.noFiles!.hidden = false
            } else {
                self.noFiles!.hidden = true
            }
        }
        
    }
    
    
    // MARK: - No Files
    
    func setupNoFiles() {
        let frame = view.frame
        noFiles = NoResultsView(frame: frame, text: "No files available.")
        view.addSubview(noFiles!)
    }
    
    // MARK: - Table Editing
    
    func toggleTableEditing() {
        if let tc = tabBarController as? FilesTabViewController {
            if tableView.editing {
                navigationItem.rightBarButtonItems?[0].style = .Plain
                navigationItem.rightBarButtonItems?[0].title = "Edit"
                navigationItem.setHidesBackButton(false, animated: true)
                tableView.setEditing(false, animated: true)
                tc.toolbar?.hidden = true
                for item in (tc.toolbar!.items)! {
                    item.enabled = false
                }
            } else {
                navigationItem.rightBarButtonItems?[0].style = .Done
                navigationItem.rightBarButtonItems?[0].title = "Cancel"
                navigationItem.setHidesBackButton(true, animated: true)
                tableView.setEditing(true, animated: true)
                tc.toolbar?.hidden = false
            }
        }
    }
    
    func toolbarMoveAction() {
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            
            let filesToMove: [File] = indexPaths.map { files[$0.row] }
            
            let vc: UINavigationController = UIStoryboard(name: "MoveFiles", bundle: nil).instantiateInitialViewController() as! UINavigationController

            vc.modalPresentationStyle = .FormSheet
            
            let child = vc.childViewControllers[0] as! MoveFilesTableViewController
            child.filesToMove = filesToMove
            child.tableController = self
            
            toggleTableEditing()
            presentViewController(vc, animated: true, completion: nil)
            
        }
    }
    
    /**
     Delete multiple files selected
     */
    func toolbarDeleteAction() {
        if let indexPaths = tableView.indexPathsForSelectedRows {
            
            var message = "Are you sure you want to these \(indexPaths.count) files?"
            if indexPaths.count == 1 {
                message = "Are you sure you want to delete: '\(files[indexPaths[0].row].name!)'?"
            }
            
            let alert = FetchAlertController(title: (indexPaths.count > 1) ? "Delete Files" : "Delete File", message: message, preferredStyle: .ActionSheet)
            
            if let tc = tabBarController as? FilesTabViewController {
                alert.popoverPresentationController?.barButtonItem = tc.toolbar?.items?[0]
            }
            
            alert.addAction(UIAlertAction(title: (indexPaths.count > 1) ? "Delete Files" : "Delete File", style: .Destructive) { action in
                
                let ids: [Int] = indexPaths.map { indexPath in
                    return self.files[indexPath.row].id
                }
                
                for indexPath in indexPaths.sort({ $0.row > $1.row }) {
                    self.files.removeAtIndex(indexPath.row)
                }
                
                self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                
                if self.files.count == 0 {
                    self.noFiles!.hidden = false
                } else {
                    self.noFiles!.hidden = true
                }
                
                File.destroyIds(ids)
                self.toggleTableEditing()
                
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else { return nil }
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        guard let directory = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("directoryView") as? DirectoryTableViewController  else { return nil }
        
        let file = files[indexPath.row]
        if file.content_type == Optional("application/x-directory") {
            directory.file = file
            previewingContext.sourceRect = cell.frame
            return directory
        }
        
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
    
}
