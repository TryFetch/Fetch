//
//  TextViewController.swift
//  Fetch
//
//  Created by Stephen Radford on 24/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import PutioKit

class TextViewController: UIViewController {

    var file: File?
    var overlay: LoaderView?
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set title
        title = file!.name
        
        // Load the loader
        overlay = LoaderView(frame: view.frame)
        view.addSubview(overlay!.view)
        
        // Load the text with Alamofire
        loadText()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        file = nil
    }
    
    // MARK: - Network
        
    func loadText() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        Alamofire.request("\(Putio.api)files/\(file!.id)/download?oauth_token=\(Putio.accessToken!)", method: .get)
            .responseString { response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                if response.result.isFailure {
                    print(response.result.error)
                } else {
                    self.textView.text = response.result.value!
                    self.overlay?.hideWithAnimation()
                }
                
            }
    }
    
}
