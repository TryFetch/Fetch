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
        overlay?.view.backgroundColor = UIColor.black
        overlay?.loader.activityIndicatorViewStyle = .white
        view.addSubview(overlay!.view)
        
    }
    
    override var prefersStatusBarHidden : Bool {
        return navigationController?.isNavigationBarHidden == false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        file = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        toggle()
        loadImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageView.image = nil
    }
    
    // MARK: - Network
    
    func loadImage() {
        let params = ["oauth_token": "\(Putio.accessToken!)"]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Alamofire.request("\(Putio.api)files/\(file!.id)/download", method: .get, parameters: params)
            .response { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let error = response.error {
                    print(error)
                } else {
                    self.imageView.contentMode = .scaleAspectFit
                    self.imageView.image = UIImage(data: response.data!)
                    self.overlay?.hideWithAnimation()
                }
            }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // MARK: - Hide/Show Nav Bar
    
    func toggle() {
        let isHidden = navigationController?.isNavigationBarHidden
        navigationController?.setNavigationBarHidden(isHidden == false, animated: true)
    }
    
    @IBAction func toggleNav(_ sender: AnyObject) {
        toggle()
    }
    

}
