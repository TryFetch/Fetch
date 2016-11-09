//
//  AddFilesViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 21/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import PutioKit

class AddFilesViewController: UIViewController, UITextViewDelegate {

    var transfersTable: TransfersTableViewController?
    var magnetLink: String?
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var magnetLabel: UILabel!
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var folderPicker: UIView!
    var whichView: WhichFolderView?
    var gradView: GradientOverlay?
    var folderPickerController: FolderSelectorNavViewController?
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var border: CALayer!
    var torrent: NSURL?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let tabView: FilesTabViewController = self.presentingViewController as! FilesTabViewController
        let splitView: FilesNavViewController = tabView.selectedViewController?.childViewControllers[0] as! FilesNavViewController
        transfersTable = splitView.childViewControllers[0] as? TransfersTableViewController
        
        loadFolderPicker()
        
        if(magnetLink == nil) {
            saveBtn.enabled = false
        } else {
        
            if let url = NSURL(string: magnetLink!) {
                if url.scheme == "file" {
                    torrent = url
                    textView.editable = false
                    textView.text = "File: \(url.lastPathComponent!)"
                    whichView?.hidden = true
                    gradView?.hidden = true
                } else {
                    textView.text = magnetLink
                }
            } else {
                textView.text = magnetLink
            }
            
        }
        
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsetsMake(10, 7, 10, 7)
        textView.autocorrectionType = .No
        textView.becomeFirstResponder()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardChanged), name: UIKeyboardWillChangeFrameNotification, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        magnetLink = nil
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: - Actions
    
    @IBAction func closeView(sender: AnyObject) {
        
        // Show an alert before we close here
        
        if(textView.text != "") {
            
            let alert = FetchAlertController(title: "Close", message: "Are you sure you don't want to add the transfer?", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                self.textView.resignFirstResponder()
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            presentViewController(alert, animated: true, completion: nil)
            
        } else {
            textView.resignFirstResponder()
            dismissViewControllerAnimated(true, completion: nil)
        }
    
    }
    
    
    @IBAction func saveFiles(sender: AnyObject) {
        addTransfer()
    }

    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        if(textView.text != nil) {
            saveBtn.enabled = true
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        whichView?.showWithAnimation()
        gradView?.showWithAnimation()
        folderPickerController?.whichView.label.text = "\(folderPickerController!.title!)"
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        whichView?.hideWithAnimation()
        gradView?.hideWithAnimation()
    }
    
    // MARK: - Network
    
    func addTransfer() {
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicator.startAnimating()
        let barBtn = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = barBtn
        navigationItem.leftBarButtonItem?.enabled = false
        
        folderPickerController?.whichView.label.text = "\(folderPickerController!.title!)"
        whichView?.showWithAnimation()
        gradView?.showWithAnimation()
        
        if let file = torrent {
            
            var parentId = "0"
            let vc = folderPickerController!.visibleViewController as! FolderSelectTableViewController
            if vc.parentFile != nil {
                parentId = "\(vc.parentFile!.id)"
            }
            
            Alamofire.upload(.POST, "https://upload.put.io/v2/files/upload?oauth_token=\(Putio.accessToken!)", multipartFormData: { data in
                data.appendBodyPart(fileURL: file, name: "file")
                data.appendBodyPart(data: parentId.dataUsingEncoding(NSUTF8StringEncoding)!, name: "parent_id")
            }) { result in
                switch result {
                case .Success(let upload, _, _):
                    upload.response { _ in
                        self.textView.resignFirstResponder()
                        self.dismissViewControllerAnimated(true, completion: {
                            self.transfersTable?.reload()
                        })
                    }
                case .Failure:
                    print("error uploading")
                    self.textView.resignFirstResponder()
                    self.dismissViewControllerAnimated(true, completion: {
                        self.transfersTable?.reload()
                    })
                }
            }
            
        } else {
            
            let url = textView.text
            var params = ["oauth_token": "\(Putio.accessToken!)", "url": url, "extract": "true"]
            
            // load the save_parent_id from the visible view controller
            let vc = folderPickerController!.visibleViewController as! FolderSelectTableViewController
            if vc.parentFile != nil {
                params["save_parent_id"] = "\(vc.parentFile!.id)"
            }
            
            Alamofire.request(.POST, "\(Putio.api)transfers/add", parameters: params)
                .response { _ in
                    self.textView.resignFirstResponder()
                    self.dismissViewControllerAnimated(true, completion: {
                        self.transfersTable?.reload()
                    })
                }
        }
        
    }
    
    // MARK: - Folder Picker
    
    func loadFolderPicker() {
        
        let sb = UIStoryboard(name: "FolderPicker", bundle: nil)
        folderPickerController = sb.instantiateInitialViewController() as? FolderSelectorNavViewController
        
        folderPickerController!.view.frame = CGRect(x: 0, y: 0, width: folderPicker.frame.width, height: folderPicker.frame.height)
        folderPickerController!.view.layoutIfNeeded()
        addChildViewController(folderPickerController!)
        folderPicker.addSubview(folderPickerController!.view)
        folderPickerController!.didMoveToParentViewController(self)
        
        whichView = folderPickerController!.whichView
        whichView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showFolderPicker)))
        
        gradView = folderPickerController!.gradOverlay
        gradView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showFolderPicker)))
        
        
    }
    
    func showFolderPicker(gesture: UITapGestureRecognizer) {
        textView.resignFirstResponder()
    }

    func keyboardChanged(sender: NSNotification) {
        let height = (sender.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue().height
        heightConstraint.constant = height + folderPickerController!.navigationBar.frame.height
    }
    
}
