//
//  MediaType.swift
//  Fetch
//
//  Created by Stephen Radford on 13/12/2015.
//  Copyright © 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

public protocol MediaType: class {
    
    /// The poster of the media type in question
    var posterURL: String? { get set }
    
    var poster: UIImage? { get set }
    
    /// THe title of the media type in question
    var title: String? { get set }
    
    /**
     Load the poster from the server
     
     - parameter callback: The callback that will return the poster for the media type
     */
    func getPoster(callback: (UIImage) -> Void)
    
}

extension MediaType {
    
    public func getPoster(callback: (UIImage) -> Void) {
        if let url = posterURL {
            Alamofire.request(.GET, "https://image.tmdb.org/t/p/w500\(url)")
                .responseImage { response in
                    if let image = response.result.value {
                        self.poster = image
                        callback(image)
                    } else {
                        self.generatePoster { image in
                            self.poster = image
                            callback(image)
                        }
                    }
                }
            
        } else {
            generatePoster { image in
                self.poster = image
                callback(image)
            }
        }
    }
    
    func generatePoster(callback: (UIImage) -> Void) {
        let noArtworkView = NSBundle(identifier: "uk.co.wearecocoon.PutioKit")!.loadNibNamed("NoArtwork", owner: nil, options: nil)[0] as! NoArtworkView
        noArtworkView.frame = CGRectMake(0, 0, 350, 525)
        noArtworkView.label.text = self.title
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(350, 525), true, 0)
        noArtworkView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        callback(image)
        UIGraphicsEndImageContext()
    }
    
}