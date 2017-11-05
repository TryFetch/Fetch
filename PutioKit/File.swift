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
        
        Alamofire.request("\(Putio.api)files/delete", method: .post, parameters: params)
            .responseJSON { response in
                Putio.networkActivityIndicatorVisible(false)
                if response.result.isFailure {
                    print(response.result.error)
                }
        }
    }
    
    
    public class func destroyIds(_ ids: [Int]) {
        Putio.networkActivityIndicatorVisible(true)
        
        let stringIds: [String] = ids.map { String($0) }
        
        let params: [String: AnyObject] = [
            "oauth_token": Putio.accessToken! as NSString,
            "file_ids": stringIds.joined(separator: ",") as NSString,
        ]
        
        Alamofire.request("\(Putio.api)files/delete", method: .post, parameters: params)
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
        
        Alamofire.request("\(Putio.api)files/\(id)/mp4", method: .post, parameters: params)
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
        
        let params: [String: AnyObject] = [
            "oauth_token": Putio.accessToken! as NSString,
            "time": start_from as NSNumber,
        ]
        
        Alamofire.request("\(Putio.api)files/\(id)/start-from/set", method: .post, parameters: params)
            .responseJSON { _ in
                print("time saved")
                Putio.networkActivityIndicatorVisible(false)
            }
    }
    
    // MARK: - Rename
    
    public func renameWithAlert(_ alert: UIAlertController) {
        Putio.networkActivityIndicatorVisible(true)
        
        let textField = alert.textFields![0] 
        name = textField.text!
        
        let params: [String: AnyObject] = [
            "oauth_token": Putio.accessToken! as NSString,
            "file_id": id as NSNumber,
            "name": name! as NSString,
        ]
        
        Alamofire.request("\(Putio.api)files/rename", method: .post, parameters: params)
            .response { _ in
                Putio.networkActivityIndicatorVisible(false)
            }
    }
    
    // MARK: - Move
    
    public func moveTo(parentId: Int) {
        Putio.networkActivityIndicatorVisible(true)
        
        let params: [String: AnyObject] = [
            "oauth_token": Putio.accessToken! as NSString,
            "file_ids": id as NSNumber,
            "parent_id": parentId as NSNumber,
        ]
        
        Alamofire.request("\(Putio.api)files/move", method: .post, parameters: params)
            .responseJSON { _ in
                Putio.networkActivityIndicatorVisible(false)
            }
    }
    
    public func getTime(callback: @escaping () -> Void) {
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
        
        Alamofire.request("\(Putio.api)files/\(id)", parameters: params)
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
    
    public class func getFileById(_ id: String, callback: @escaping (File) -> Void) {
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "start_from": "1"]
        
        Alamofire.request("\(Putio.api)files/\(id)", parameters: params)
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
