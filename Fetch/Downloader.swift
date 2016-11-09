//
//  Downloader.swift
//  Fetch
//
//  Created by Stephen Radford on 06/03/2016.
//  Copyright © 2016 Cocoon Development Ltd. All rights reserved.
//

import PutioKit
import Alamofire

protocol DownloaderDelegate {
    
    func percentageChanged(percentage: String)
    
    func downloadCompleted()
    
    func downloadError(error: NSError)
    
}

class Downloader {
    
    static let sharedInstance = Downloader()
    
    var isDownloading = false
    
    var delegate: DownloaderDelegate?
    
    let manager = Alamofire.Manager(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("uk.co.wearecocoon.background"))
    
    var queue = [File]() {
        didSet {
            setTabBarIcon()
            downloadNext()
        }
    }
    
    /// This is the current download request. We store this so we can cancel it if required.
    var currentRequest: Request?
    
    /// MP4s that are in the documents folder.
    var downloadedFiles: [String] {
        do {
            let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            let directoryUrls = try  NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions())
            return directoryUrls.filter{ $0.pathExtension! == "mp4" }.map{ $0.lastPathComponent! }
        } catch {
            return []
        }
    }
    
    /// Where downloaded files will be dtored
    let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)

    
    // MARK: - Methods
    
    /**
     Download the next file in the queue
     */
    func downloadNext() {
        guard !isDownloading else {
            return
        }
        
        if let file = queue.first {
            
            let endpoint = (file.has_mp4) ? "mp4/download" : "download"
            isDownloading = true
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            currentRequest = manager.download(.GET, "\(Putio.api)/files/\(file.id)/\(endpoint)?oauth_token=\(Putio.accessToken!)", destination: destination)
                
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                    let percent = Int(round((Float(totalBytesRead) / Float(totalBytesExpectedToRead))*100))
                    dispatch_async(dispatch_get_main_queue()) {
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                        self.delegate?.percentageChanged("\(percent)%")
                    }
                }
                
                .response { _, _, _, error in
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if(self.queue.count > 0) { self.queue.removeFirst() }
                    self.isDownloading = false
                    self.downloadNext()
                    self.sendNotification()
                    
                    if let e = error {
                        self.delegate?.downloadError(e)
                    } else {
                        self.delegate?.downloadCompleted()
                    }
                }
            
        }
        
    }
    
    /**
     Send a notification when the files finish downloading
     */
    func sendNotification() {
        if self.queue.isEmpty && UIApplication.sharedApplication().applicationState == .Background {
            let notification = UILocalNotification()
            notification.alertBody = "Your files have finished downloading."
            notification.alertAction = "open"
            notification.soundName = "success.wav"
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }
    
    /**
     Delete the file at the index referenced
     
     - parameter index: The index of the file to remove
     */
    func deleteFileAtIndex(index: Int) {
        let file = downloadedFiles[index]
        let fm = NSFileManager.defaultManager()
        let documentsUrl =  fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        do {
            try fm.removeItemAtURL(documentsUrl.URLByAppendingPathComponent(file))
        } catch {
            print("Could not delete file")
        }
    }
    
    /**
     Set the badge icon to be the same value as the queue amount
     */
    func setTabBarIcon() {
        if let tc = UIApplication.sharedApplication().keyWindow?.rootViewController as? FilesTabViewController {
            if let item = tc.tabBar.items?[3] {
                item.badgeValue = (queue.isEmpty) ? nil : String(queue.count)
            }
        }
    }
    
}