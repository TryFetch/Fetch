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
        toolbar?.barStyle = .black
        
        let deleteBtn = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(toolbarDeleteTapped))
        deleteBtn.isEnabled = false
        
        let moveBtn = UIBarButtonItem(title: "Move", style: .plain, target: self, action: #selector(toolbarMoveTapped))
        moveBtn.isEnabled = false
        
        toolbar?.items = [
            deleteBtn,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            moveBtn
        ]
        
        toolbar?.isHidden = true
        
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
    
    override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        let resultVC = self.selectedViewController?.forUnwindSegueAction(action, from: fromViewController, withSender: sender)
        return resultVC
    }

}
