//
//  Transfer.swift
//  Fetch
//
//  Created by Stephen Radford on 25/05/2015.
//  Copyright (c) 2015 Cocoon Development Ltd. All rights reserved.
//

import UIKit
import Alamofire
import PutioKit

class Transfer: NSObject {
   
    var id: Int?
    var name: String?
    var status: TransferStatus?
    var status_message: String?
    var percent_done: Int?
    var size: Int64
    var estimated_time: Int64?
    
    enum TransferStatus {
        case completed
        case queued
        case inProgress
    }
    
    init(id: Int, name: String, status_message: String, status: String, percent_done: Int, size: Int64, estimated_time: Int64?) {
        self.id = id
        self.name = name
        self.status_message = status_message
        
        if(status == "COMPLETED") {
            self.status = .completed
        } else if(status == "IN_QUEUE") {
            self.status = .queued
        } else {
            self.status = .inProgress
        }
        
        self.percent_done = percent_done
        self.size = size
        self.estimated_time = estimated_time
    }
    
    func destroy() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let params = ["oauth_token": "\(Putio.accessToken!)", "transfer_ids": "\(id!)"]
        
        Alamofire.request("\(Putio.api)transfers/cancel", method: .post, parameters: params)
            .responseJSON {response in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                if let error = response.result.error {
                    print(error)
                }
            }

        
    }
    
}
