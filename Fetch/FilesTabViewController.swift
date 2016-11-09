//
//  FilesTabViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 24/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit

protocol FilesToolbarDelegate: class {
    
    func toolbarMoveAction()
    
    func toolbarDeleteAction()
    
}

class FilesTabViewController: UITabBarController {

    var toolbar: UIToolbar?
    
    weak var toolbarDelegate: FilesToolbarDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolbar = UIToolbar(frame: CGRect(x: 0, y: view.bounds.height-49, width: view.bounds.width, height: 49))
        toolbar?.barStyle = .Black
        
        let deleteBtn = UIBarButtonItem(title: "Delete", style: .Plain, target: self, action: #selector(toolbarDeleteTapped))
        deleteBtn.enabled = false
        
        let moveBtn = UIBarButtonItem(title: "Move", style: .Plain, target: self, action: #selector(toolbarMoveTapped))
        moveBtn.enabled = false
        
        toolbar?.items = [
            deleteBtn,
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            moveBtn
        ]
        
        toolbar?.hidden = true
        
        view.addSubview(toolbar!)
    }
    
    func toolbarDeleteTapped() {
        toolbarDelegate?.toolbarDeleteAction()
    }
    
    func toolbarMoveTapped() {
        toolbarDelegate?.toolbarMoveAction()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toolbar?.frame = CGRect(x: 0, y: view.bounds.height-49, width: view.bounds.width, height: 49)
    }
    
    override func viewControllerForUnwindSegueAction(action: Selector, fromViewController: UIViewController, withSender sender: AnyObject?) -> UIViewController? {
        let resultVC = self.selectedViewController?.viewControllerForUnwindSegueAction(action, fromViewController: fromViewController, withSender: sender)
        return resultVC
    }

}
