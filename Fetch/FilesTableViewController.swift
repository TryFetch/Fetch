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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
        refreshControl?.addTarget(self, action: #selector(refresh), for: UIControlEvents.valueChanged)
        refreshControl?.isEnabled = false
        
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
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleTableEditing)),
            castHandler!.button!
        ]
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "fileReuse", for: indexPath)
        
        let file = files[indexPath.row]
        
        
        // Cell the label to the file name
        cell.textLabel?.text = file.name
        
        // Hide the accesory if it's NOT a directory
        if( types.contains(file.content_type!) || file.has_mp4 ) {
            cell.accessoryType = .detailButton
        } else if(file.content_type == "application/x-directory") {
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.accessoryType = .none
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !files[indexPath.row].is_shared
    }
    
    /// This is needed to enable the editing for some reason...
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    /// Add the actions to the row
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let moreAction = UITableViewRowAction(style: .normal, title: "More", handler: moreHandler)
        moreAction.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.25, alpha: 1)
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: deleteFile)
        
        return [deleteAction, moreAction]
    }
    
    /// Handler for the more action
    func moreHandler(_ action: UITableViewRowAction!, indexPath: IndexPath!) {
        let alert = FetchAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Move File", style: .default) { alertAction in
            self.moveFile(action, indexPath: indexPath)
        })
        
        alert.addAction(UIAlertAction(title: "Rename File", style: .default) { alertAction in
            self.renameFile(action, indexPath: indexPath)
        })
        
        let file = self.files[indexPath.row]
        if file.content_type == "video/mp4" || file.has_mp4 {
            alert.addAction(UIAlertAction(title: "Download File", style: .default) { alertAction in
                self.addFileToQueue(file)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel){ action in
            self.tableView.setEditing(false, animated: true)
        })
        
        let cell = tableView.cellForRow(at: indexPath)!
        
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.width-5, y: 0, width: 80, height: cell.frame.height)
        
        present(alert, animated: true, completion: nil)
    }
    
    /**
     Add the file to the download queue
     
     - parameter file: The file to add to the queue
     */
    func addFileToQueue(_ file: File) {
        if !Downloader.sharedInstance.queue.contains { $0 == file } {
            Downloader.sharedInstance.queue.append(file)
        }
        tableView.setEditing(false, animated: true)
    }
    
    /// Handler for the move action
    func moveFile(_ action: UITableViewRowAction!, indexPath: IndexPath!) {
        
        tableView.setEditing(false, animated: true)
        
        let vc: UINavigationController = UIStoryboard(name: "MoveFiles", bundle: nil).instantiateInitialViewController() as! UINavigationController

        vc.modalPresentationStyle = .formSheet
        
        let child = vc.childViewControllers[0] as! MoveFilesTableViewController
        child.filesToMove = [files[indexPath.row]]
        child.tableController = self
        
        
        present(vc, animated: true, completion: nil)
        
    }
    
    /// Handler for the rename action
    func renameFile(_ action: UITableViewRowAction!, indexPath: IndexPath!) {
        
        tableView.setEditing(false, animated: true)
        
        let alert = FetchAlertController(title: "Rename File", message: "Enter the new name of the file below", preferredStyle: .alert)
        
        let file = files[indexPath.row]
        
        alert.addTextField { (textField) -> Void in
            textField.placeholder = "New Name"
            textField.text = file.name
            textField.autocorrectionType = .yes
            textField.autocapitalizationType = .sentences
        }
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { action in
            file.renameWithAlert(alert)
            self.tableView.reloadData()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true) {
//            let textField = alert.textFields![0] as! UITextField
//            textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
        }
        
        
    }
    
    /// Handler for the delete action
    func deleteFile(_ action: UITableViewRowAction!, indexPath: IndexPath!) {
        
        let alert = FetchAlertController(title: "Delete File", message: "Are you sure you want to delete: '\(files[indexPath.row].name!)'?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Delete File", style: .destructive) { action in
            
            let file = self.files[indexPath.row]
            file.destroy()
            self.files.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            if self.files.count == 0 {
                self.noFiles!.isHidden = false
            } else {
                self.noFiles!.isHidden = true
            }
            
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
            self.tableView.setEditing(false, animated: true)
        })
        
        let cell = tableView.cellForRow(at: indexPath)!
        
        alert.popoverPresentationController?.sourceView = cell
        alert.popoverPresentationController?.sourceRect = CGRect(x: cell.frame.width+65, y: 0, width: 80, height: cell.frame.height)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        
        if(segue.destination.isKind(of: DetailViewController.self)) {
            
            // Show the detail view
            let detailController: DetailViewController = segue.destination as! DetailViewController
            detailController.file = selectedFile
            
        } else if (sender == nil) {
            
            if(selectedFile?.content_type == "application/x-directory") {
                
                // Show the directory view
                let directoryController: DirectoryTableViewController = segue.destination as! DirectoryTableViewController
                directoryController.file = selectedFile
                
            } else if(selectedFile!.has_mp4 || selectedFile!.content_type == "video/mp4" || audio_types.contains(selectedFile!.content_type!)) {

                let fType = (audio_types.contains(selectedFile!.content_type!)) ? "audio" : "video"
                setupMediaHandler(segue, type: fType)
            
            } else if(selectedFile!.content_type == "text/plain") {
                
                let vc: TextViewController = segue.destination as! TextViewController
                vc.file = selectedFile
            
            } else if(image_types.contains(selectedFile!.content_type!)) {
                
                let vc: ImageHandlerViewController = segue.destination as! ImageHandlerViewController
                vc.file = selectedFile
                
            } else {
                
                // Show the detail view for the time being
                let detailController: DetailViewController = segue.destination as! DetailViewController
                detailController.file = selectedFile
                
            }
            
        }
        
    
    }
    
    /// Setup the media player
    func setupMediaHandler(_ segue: UIStoryboardSegue, type: String) {

        let videoController: MediaPlayerViewController = segue.destination as! MediaPlayerViewController
        videoController.file = selectedFile
            
        var urlString: String!
            
        if(type == "audio") {
            urlString = "\(Putio.api)files/\(selectedFile!.id)/stream?oauth_token=\(Putio.accessToken!)"
        } else {
            urlString = "\(Putio.api)files/\(selectedFile!.id)/hls/media.m3u8?oauth_token=\(Putio.accessToken!)&subtitle_key=all"
        }
        
        
        let url = URL(string: urlString)
        videoController.player = AVPlayer(url: url!)
        videoController.delegate = PlayerDelegate.sharedInstance

    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard tableView.isEditing else {
           return indexPath
        }
        
        let file = files[indexPath.row]
        if file.is_shared {
            return nil
        }
        
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let tc = tabBarController as? FilesTabViewController {
            for item in (tc.toolbar!.items)! {
                item.isEnabled = (tableView.indexPathsForSelectedRows?.count > 0)
            }
        }
        
        guard !tableView.isEditing else {
            return
        }
        
        selectedFile = files[indexPath.row]
        selectedFile?.accessed = true
        tableView.reloadData()
        
        if(selectedFile?.content_type == "application/x-directory") {
            
            performSegue(withIdentifier: "showDirectoryView", sender: nil)
            
        } else if(audio_types.contains(selectedFile!.content_type!)) {
            
            performSegue(withIdentifier: "videoPlayer", sender: nil)
            
        } else if(selectedFile!.has_mp4 || selectedFile?.content_type == "video/mp4" || audio_types.contains(selectedFile!.content_type!)) {
            
            if castHandler?.device != nil {
                castHandler?.sendFile(selectedFile!) {
                    self.castHandler?.showRemote(self)
                }
            } else {
                performSegue(withIdentifier: "videoPlayer", sender: nil)
            }
            
        } else if(selectedFile?.content_type == "text/plain") {
            
            performSegue(withIdentifier: "textView", sender: nil)
            
        } else if(image_types.contains(selectedFile!.content_type!)) {
            
            performSegue(withIdentifier: "imageView", sender: nil)
            
        } else {
            
            performSegue(withIdentifier: "showDetailView", sender: nil)
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let tc = tabBarController as? FilesTabViewController {
            for item in (tc.toolbar!.items)! {
                item.isEnabled = (tableView.indexPathsForSelectedRows?.count > 0)
            }
        }
    }
    
    /// Show the detail view when the (i) is clicked
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        selectedFile = files[indexPath.row]
        performSegue(withIdentifier: "showDetailView", sender: nil)
    }
    
    
    // MARK: - Networking

    // CALL ON REFRESH
    func refresh(_ sender: UIRefreshControl) {
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
                self.noFiles!.isHidden = false
            } else {
                self.noFiles!.isHidden = true
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
            if tableView.isEditing {
                navigationItem.rightBarButtonItems?[0].style = .plain
                navigationItem.rightBarButtonItems?[0].title = "Edit"
                navigationItem.setHidesBackButton(false, animated: true)
                tableView.setEditing(false, animated: true)
                tc.toolbar?.isHidden = true
                for item in (tc.toolbar!.items)! {
                    item.isEnabled = false
                }
            } else {
                navigationItem.rightBarButtonItems?[0].style = .done
                navigationItem.rightBarButtonItems?[0].title = "Cancel"
                navigationItem.setHidesBackButton(true, animated: true)
                tableView.setEditing(true, animated: true)
                tc.toolbar?.isHidden = false
            }
        }
    }
    
    func toolbarMoveAction() {
        
        if let indexPaths = tableView.indexPathsForSelectedRows {
            
            let filesToMove: [File] = indexPaths.map { files[$0.row] }
            
            let vc: UINavigationController = UIStoryboard(name: "MoveFiles", bundle: nil).instantiateInitialViewController() as! UINavigationController

            vc.modalPresentationStyle = .formSheet
            
            let child = vc.childViewControllers[0] as! MoveFilesTableViewController
            child.filesToMove = filesToMove
            child.tableController = self
            
            toggleTableEditing()
            present(vc, animated: true, completion: nil)
            
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
            
            let alert = FetchAlertController(title: (indexPaths.count > 1) ? "Delete Files" : "Delete File", message: message, preferredStyle: .actionSheet)
            
            if let tc = tabBarController as? FilesTabViewController {
                alert.popoverPresentationController?.barButtonItem = tc.toolbar?.items?[0]
            }
            
            alert.addAction(UIAlertAction(title: (indexPaths.count > 1) ? "Delete Files" : "Delete File", style: .destructive) { action in
                
                let ids: [Int] = indexPaths.map { indexPath in
                    return self.files[indexPath.row].id
                }
                
                for indexPath in indexPaths.sorted(by: { $0.row > $1.row }) {
                    self.files.remove(at: indexPath.row)
                }
                
                self.tableView.deleteRows(at: indexPaths, with: .automatic)
                
                if self.files.count == 0 {
                    self.noFiles!.isHidden = false
                } else {
                    self.noFiles!.isHidden = true
                }
                
                File.destroyIds(ids)
                self.toggleTableEditing()
                
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    
    
    // MARK: - UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        
        guard let directory = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "directoryView") as? DirectoryTableViewController  else { return nil }
        
        let file = files[indexPath.row]
        if file.content_type == Optional("application/x-directory") {
            directory.file = file
            previewingContext.sourceRect = cell.frame
            return directory
        }
        
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
}
