//
//  MoveFilesTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 17/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PutioKit

class MoveFilesTableViewController: UITableViewController {

    /// The file we're moving
    var filesToMove = [File]()
    
    /// Parent file if there is one!
    var parentFile: File?
    
    /// The filtered list of files for the list
    var files: [File] = []
    
    /// The selected file
    var selectedFile: File?
    
    /// The loader view
    var loaderView: LoaderView!
    
    /// No results view
    var noResults: NoResultsView!
    
    /// The table controller
    var tableController: FilesTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = (parentFile != nil) ? parentFile!.name : "All Files"
        
        loaderView = LoaderView(frame: view.frame)
        view.addSubview(loaderView.view)
        
        noResults = NoResultsView(frame: view.frame, text: "No folders available.")
        view.addSubview(noResults)
        
        fetchFolders()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.title = (parentFile != nil) ? parentFile!.name : "All Files"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .Default
    }
    

    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("folderCell", forIndexPath: indexPath) 
        
        cell.textLabel!.text = files[indexPath.row].name
        
        return cell
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! MoveFilesTableViewController
        vc.parentFile = selectedFile
        vc.filesToMove = filesToMove
        vc.tableController = tableController
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedFile = files[indexPath.row]
        performSegueWithIdentifier("nextFolder", sender: self)
    }
    
    
    // MARK: - Network
    
    func setParams() -> [String:String] {
        if parentFile != nil {
            return ["oauth_token": "\(Putio.accessToken!)", "start_from": "1", "parent_id": "\(parentFile!.id)"]
        }
        
        return ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
    }
    
    func fetchFolders() {
        fetchFoldersWithCallback() { }
    }
    
    func fetchFoldersWithCallback(callback: () -> Void) {
        noResults.hidden = true
        let ids = filesToMove.map { $0.id }
        Files.fetchFoldersWithExclusionFromURL("\(Putio.api)files/list", params: setParams(), exclude: ids) { files in
            
            if files.count == 0 {
                self.noResults.hidden = false
            }
            
            self.files = files
            self.loaderView.hideWithAnimation()
            self.tableView.reloadData()
            callback()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func close(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addFolder(sender: AnyObject?) {
        
        let alert = FetchAlertController(title: "Add Folder", message: "Enter the name of the folder you wish to create.", preferredStyle: .Alert)
        
        alert.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "New Folder"
            textField.autocorrectionType = .Yes
            textField.autocapitalizationType = .Sentences
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add Folder", style: .Default, handler: { (action) in
            let input = alert.textFields![0] 
            self.createFolderWithName(input.text!)
        }))
        
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    /// Create a folder with the name passed in
    func createFolderWithName(name: String) {
        
        if name == "" {
            return
        }
        
        loaderView.show()
        
        var params = ["oauth_token": "\(Putio.accessToken!)", "name": name]
        if parentFile != nil {
            params["parent_id"] = "\(parentFile!.id)"
        } else {
            params["parent_id"] = "0"
        }
        
        Alamofire.request(.POST, "\(Putio.api)files/create-folder", parameters: params)
            .responseJSON { response in
                
                if let error = response.result.error {
                    print(error)
                } else {
                    let json = JSON(response.result.value!)
                    let id = json["file"]["id"].int!
                    
                    self.fetchFoldersWithCallback() {
                        self.navigateToId(id)
                    }
                }
                
        }
    }
    
    /// Navigate to a row with a specific ID
    func navigateToId(id: Int) {
        for file in files {
            if file.id == id {
                selectedFile = file
                performSegueWithIdentifier("nextFolder", sender: self)
            }
        }
    }
    
    /// Move the files to the new folder and close
    @IBAction func save(sender: AnyObject?) {
     
        let parentId = (parentFile != nil) ? parentFile!.id : 0
        Files.moveFiles(filesToMove, parent: parentId)
        
        dismissViewControllerAnimated(true) {
            self.tableController.overlay?.show()
            self.tableController.fetchFiles()
        }
        
    }
    
}
