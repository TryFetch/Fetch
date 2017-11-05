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
    var torrent: URL?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let tabView: FilesTabViewController = self.presentingViewController as! FilesTabViewController
        let splitView: FilesNavViewController = tabView.selectedViewController?.childViewControllers[0] as! FilesNavViewController
        transfersTable = splitView.childViewControllers[0] as? TransfersTableViewController
        
        loadFolderPicker()
        
        if(magnetLink == nil) {
            saveBtn.isEnabled = false
        } else {
        
            if let url = URL(string: magnetLink!) {
                if url.scheme == "file" {
                    torrent = url
                    textView.isEditable = false
                    textView.text = "File: \(url.lastPathComponent)"
                    whichView?.isHidden = true
                    gradView?.isHidden = true
                } else {
                    textView.text = magnetLink
                }
            } else {
                textView.text = magnetLink
            }
            
        }
        
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsetsMake(10, 7, 10, 7)
        textView.autocorrectionType = .no
        textView.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChanged), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        magnetLink = nil
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Actions
    
    @IBAction func closeView(_ sender: AnyObject) {
        
        // Show an alert before we close here
        
        if(textView.text != "") {
            
            let alert = FetchAlertController(title: "Close", message: "Are you sure you don't want to add the transfer?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.textView.resignFirstResponder()
                self.dismiss(animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
            
        } else {
            textView.resignFirstResponder()
            dismiss(animated: true, completion: nil)
        }
    
    }
    
    
    @IBAction func saveFiles(_ sender: AnyObject) {
        addTransfer()
    }

    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        if(textView.text != nil) {
            saveBtn.isEnabled = true
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        whichView?.showWithAnimation()
        gradView?.showWithAnimation()
        folderPickerController?.whichView.label.text = "\(folderPickerController!.title!)"
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        whichView?.hideWithAnimation()
        gradView?.hideWithAnimation()
    }
    
    // MARK: - Network
    
    func addTransfer() {
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.startAnimating()
        let barBtn = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = barBtn
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        folderPickerController?.whichView.label.text = "\(folderPickerController!.title!)"
        whichView?.showWithAnimation()
        gradView?.showWithAnimation()
        
        if let file = torrent {
            
            var parentId = "0"
            let vc = folderPickerController!.visibleViewController as! FolderSelectTableViewController
            if vc.parentFile != nil {
                parentId = "\(vc.parentFile!.id)"
            }

            Alamofire.upload(multipartFormData: { data in
                data.append(file, withName: "file")
                data.append(parentId.data(using: .utf8)!, withName: "parent_id")
            }, to: "https://upload.put.io/v2/files/upload?oauth_token=\(Putio.accessToken!)", method: .post, encodingCompletion: { result in
                switch result {
                case .success(_, _, _):
                    break
                    // TODO
//                    upload.response { _ in
//                        self.textView.resignFirstResponder()
//                        self.dismissViewControllerAnimated(true, completion: {
//                            self.transfersTable?.reload()
//                        })
//                    }
                case .failure:
                    print("error uploading")
                    self.textView.resignFirstResponder()
                    self.dismiss(animated: true) {
                        self.transfersTable?.reload()
                    }
                }
            })

        } else {
            
            let url = textView.text
            var params = ["oauth_token": "\(Putio.accessToken!)", "url": url, "extract": "true"]
            
            // load the save_parent_id from the visible view controller
            let vc = folderPickerController!.visibleViewController as! FolderSelectTableViewController
            if vc.parentFile != nil {
                params["save_parent_id"] = "\(vc.parentFile!.id)"
            }
            
            Alamofire.request("\(Putio.api)transfers/add", method: .post, parameters: params)
                .response { _ in
                    self.textView.resignFirstResponder()
                    self.dismiss(animated: true) {
                        self.transfersTable?.reload()
                    }
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
        folderPickerController!.didMove(toParentViewController: self)
        
        whichView = folderPickerController!.whichView
        whichView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showFolderPicker)))
        
        gradView = folderPickerController!.gradOverlay
        gradView!.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showFolderPicker)))
        
        
    }
    
    func showFolderPicker(_ gesture: UITapGestureRecognizer) {
        textView.resignFirstResponder()
    }

    func keyboardChanged(_ sender: Notification) {
        let height = (sender.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.height
        heightConstraint.constant = height + folderPickerController!.navigationBar.frame.height
    }
    
}
