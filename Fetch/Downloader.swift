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
    
    func percentageChanged(_ percentage: String)
    
    func downloadCompleted()
    
    func downloadError(_ error: NSError)
    
}

class Downloader {
    
    static let sharedInstance = Downloader()
    
    var isDownloading = false
    
    var delegate: DownloaderDelegate?

    let manager = Alamofire.SessionManager(configuration: URLSessionConfiguration.background(withIdentifier: "uk.co.wearecocoon.background"))
    
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
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryUrls = try  FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions())
            return directoryUrls.filter{ $0.pathExtension == "mp4" }.map{ $0.lastPathComponent }
        } catch {
            return []
        }
    }
    
    /// Where downloaded files will be stored
    let destination = Alamofire.DownloadRequest.suggestedDownloadDestination(for: .documentDirectory, in: .userDomainMask)

    
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
            UIApplication.shared.isNetworkActivityIndicatorVisible = true

            currentRequest = manager.download("\(Putio.api)/files/\(file.id)/\(endpoint)?oauth_token=\(Putio.accessToken!)", method: .get, to: destination)
                
                .downloadProgress { progress in
                    let percent = Int(progress.fractionCompleted * 100)
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        self.delegate?.percentageChanged("\(percent)%")
                    }
                }
                
                .response { response in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if(self.queue.count > 0) { self.queue.removeFirst() }
                    self.isDownloading = false
                    self.downloadNext()
                    self.sendNotification()
                    
                    if let error = response.error {
                        self.delegate?.downloadError(error as NSError)
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
        if self.queue.isEmpty && UIApplication.shared.applicationState == .background {
            let notification = UILocalNotification()
            notification.alertBody = "Your files have finished downloading."
            notification.alertAction = "open"
            notification.soundName = "success.wav"
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
    }
    
    /**
     Delete the file at the index referenced
     
     - parameter index: The index of the file to remove
     */
    func deleteFileAtIndex(_ index: Int) {
        let file = downloadedFiles[index]
        let fm = FileManager.default
        let documentsUrl =  fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            try fm.removeItem(at: documentsUrl.appendingPathComponent(file))
        } catch {
            print("Could not delete file")
        }
    }
    
    /**
     Set the badge icon to be the same value as the queue amount
     */
    func setTabBarIcon() {
        if let tc = UIApplication.shared.keyWindow?.rootViewController as? FilesTabViewController {
            if let item = tc.tabBar.items?[3] {
                item.badgeValue = (queue.isEmpty) ? nil : String(queue.count)
            }
        }
    }
    
}
