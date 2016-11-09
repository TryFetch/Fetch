//
//  ImageHandlerViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 27/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import PutioKit

class ImageHandlerViewController: UIViewController, UIScrollViewDelegate {

    var file: File?
    var overlay: LoaderView?
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scroll view delegate so we can set the view for scrolling
        scrollView.delegate = self
        
        // Setup the loader
        overlay = LoaderView(frame: view.frame)
        overlay?.view.backgroundColor = UIColor.blackColor()
        overlay?.loader.activityIndicatorViewStyle = .White
        view.addSubview(overlay!.view)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return navigationController?.navigationBarHidden == false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        file = nil
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        toggle()
        loadImage()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        imageView.image = nil
    }
    
    // MARK: - Network
    
    func loadImage() {
        let params = ["oauth_token": "\(Putio.accessToken!)"]
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        Alamofire.request(.GET, "\(Putio.api)files/\(file!.id)/download", parameters: params)
            .response { (req, res, data, error) in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                if(error != nil) {
                    print(error)
                } else {
                    self.imageView.contentMode = .ScaleAspectFit
                    self.imageView.image = UIImage(data: data!)
                    self.overlay?.hideWithAnimation()
                }
            }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // MARK: - Hide/Show Nav Bar
    
    func toggle() {
        let isHidden = navigationController?.navigationBarHidden
        navigationController?.setNavigationBarHidden(isHidden == false, animated: true)
    }
    
    @IBAction func toggleNav(sender: AnyObject) {
        toggle()
    }
    

}
