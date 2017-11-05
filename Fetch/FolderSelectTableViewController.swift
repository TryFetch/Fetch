//
//  FolderSelectTableViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 15/08/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import PutioKit

class FolderSelectTableViewController: UITableViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = (parentFile != nil) ? parentFile!.name : "All Files"
        
        loaderView = LoaderView(frame: view.frame)
        view.addSubview(loaderView.view)
        
        noResults = NoResultsView(frame: view.frame, text: "No folders available.")
        view.addSubview(noResults)
        
        fetchFolders()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.title = (parentFile != nil) ? parentFile!.name : "All Files"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) 
        
        cell.textLabel!.text = files[indexPath.row].name

        return cell
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! FolderSelectTableViewController
        vc.parentFile = selectedFile
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedFile = files[indexPath.row]
        performSegue(withIdentifier: "nextFolder", sender: self)
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
    
    func fetchFoldersWithCallback(_ callback: @escaping () -> Void) {
        noResults.isHidden = true
        Files.fetchFoldersFromURL("\(Putio.api)files/list", params: setParams()) { files in
            
            if files.count == 0 {
                self.noResults.isHidden = false
            }
            
            self.files = files
            self.loaderView.hideWithAnimation()
            self.tableView.reloadData()
            callback()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func addFolder(_ sender: AnyObject?) {
        
        let alert = FetchAlertController(title: "Add Folder", message: "Enter the name of the folder you wish to create.", preferredStyle: .alert)

        alert.addTextField { (textField) -> Void in
            textField.placeholder = "New Folder"
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add Folder", style: .default, handler: { (action) in
            let input = alert.textFields![0] 
            self.createFolderWithName(input.text!)
        }))
        
        present(alert, animated: true, completion: nil)
        
    }
    
    /// Create a folder with the name passed in
    func createFolderWithName(_ name: String) {
        
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
        
        Alamofire.request("\(Putio.api)files/create-folder", method: .post, parameters: params)
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
    func navigateToId(_ id: Int) {
        for file in files {
            if file.id == id {
                selectedFile = file
                performSegue(withIdentifier: "nextFolder", sender: self)
            }
        }
    }
    
    
}
