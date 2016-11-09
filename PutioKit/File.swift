//
//  File.swift
//  Fetch
//
//  Created by Stephen Radford on 17/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON

public class File: Object {
   
    public dynamic var id: Int = 0
    public dynamic var name: String?
    public dynamic var size: Int64 = 0
    public dynamic var icon: String?
    public dynamic var content_type: String?
    public dynamic var has_mp4 = false
    public dynamic var parent_id: Int = 0
    public dynamic var subtitles: String?
    public dynamic var accessed = false
    public dynamic var screenshot: String?
    public dynamic var is_shared = false
    public dynamic var start_from: Float64 = 0
    public dynamic var parent: File?
    public dynamic var type: String?
    public dynamic var created_at: String?
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    // MARK: - Delete File
    
    public func destroy() {
        Putio.networkActivityIndicatorVisible(true)
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "file_ids": "\(id)"]
        
        Alamofire.request(.POST, "\(Putio.api)files/delete", parameters: params)
            .responseJSON { response in
                Putio.networkActivityIndicatorVisible(false)
                if response.result.isFailure {
                    print(response.result.error)
                }
        }
    }
    
    
    public class func destroyIds(ids: [Int]) {
        Putio.networkActivityIndicatorVisible(true)
        
        let stringIds: [String] = ids.map { String($0) }
        
        let params: [String:AnyObject] = ["oauth_token": Putio.accessToken!, "file_ids": stringIds.joinWithSeparator(",")]
        
        Alamofire.request(.POST, "\(Putio.api)files/delete", parameters: params)
            .responseJSON { response in
                Putio.networkActivityIndicatorVisible(false)
                if response.result.isFailure {
                    print(response.result.error)
                }
        }
    }
    
    // MARK: - Convert to MP4
    
    public func convertToMp4() {
        Putio.networkActivityIndicatorVisible(true)
        
        let params = ["oauth_token": "\(Putio.accessToken!)"]
        
        Alamofire.request(.POST, "\(Putio.api)files/\(id)/mp4", parameters: params)
            .responseJSON { response in
                Putio.networkActivityIndicatorVisible(false)
                if response.result.isFailure {
                    print(response.result.error)
                }
        }
    }
    
    // MARK: - Save the time
    
    public func saveTime() {
        Putio.networkActivityIndicatorVisible(true)
        
        let params: [String:AnyObject] = ["oauth_token": "\(Putio.accessToken!)", "time": start_from]
        
        Alamofire.request(.POST, "\(Putio.api)files/\(id)/start-from/set", parameters: params)
            .responseJSON { _ in
                print("time saved")
                Putio.networkActivityIndicatorVisible(false)
            }
    }
    
    // MARK: - Rename
    
    public func renameWithAlert(alert: UIAlertController) {
        Putio.networkActivityIndicatorVisible(true)
        
        let textField = alert.textFields![0] 
        name = textField.text!
        
        let params: [String:AnyObject] = ["oauth_token": "\(Putio.accessToken!)", "file_id": id, "name": name!]
        
        Alamofire.request(.POST, "\(Putio.api)files/rename", parameters: params)
            .response { _, _, _, _ in
                Putio.networkActivityIndicatorVisible(false)
            }
    }
    
    // MARK: - Move
    
    public func moveTo(parentId: Int) {
        Putio.networkActivityIndicatorVisible(true)
        
        let params: [String:AnyObject] = ["oauth_token": "\(Putio.accessToken!)", "file_ids": id, "parent_id": parentId]
        
        Alamofire.request(.POST, "\(Putio.api)files/move", parameters: params)
            .responseJSON { _ in
                Putio.networkActivityIndicatorVisible(false)
            }
    }
    
    public func getTime(callback: () -> Void) {
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
        
        Alamofire.request(.GET, "\(Putio.api)files/\(id)", parameters: params)
            .responseJSON { response in
                if response.result.isSuccess {
                    let json = JSON(response.result.value!)
                    if let time = json["file"]["start_from"].double {
                        self.start_from = time
                    }
                }
                
                callback()
            }
    }
    
    public class func getFileById(id: String, callback: (File) -> Void) {
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
        
        Alamofire.request(.GET, "\(Putio.api)files/\(id)", parameters: params)
            .responseJSON { response in
                if response.result.isSuccess {
                    let json = JSON(response.result.value!)
                    
                    let subtitles = ""
                    let accessed = ( json["file"]["first_accessed_at"].null != nil ) ? false : true
                    let start_from = ( json["file"]["start_from"].null != nil ) ? 0 : json["file"]["start_from"].double!
                    let has_mp4 = (json["file"]["is_mp4_available"].bool != nil) ? json["file"]["is_mp4_available"].bool! : false
                    
                    let file = File()
                    file.id = json["file"]["id"].int!
                    file.name = json["file"]["name"].string!
                    file.size = json["file"]["size"].int64!
                    file.icon = json["file"]["icon"].string!
                    file.content_type =  json["file"]["content_type"].string!
                    file.has_mp4 = has_mp4
                    file.parent_id = json["file"]["parent_id"].int!
                    file.subtitles = subtitles
                    file.accessed = accessed
                    file.screenshot = json["file"]["screenshot"].string
                    file.is_shared = json["file"]["is_shared"].bool!
                    file.start_from = start_from
                    file.created_at = json["file"]["created_at"].string
                    callback(file)
                    
                }
            }
    }
    
}
