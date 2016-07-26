//
//  User.swift
//  CRUDRecord
//
//  Created by Vlad Gorbenko on 7/26/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import CRUDRecord
import Alamofire
import ApplicationSupport

class User: CRUDRecord {
    
    var id: String!
    var username: String?
    
    required init() {}
    
    //MARK: -
    
    func setAttributes(attributes: JSONObject) {
        self.id = attributes["id"] as! String
        self.username = attributes["username"] as? String
    }
    
    func getAttributes() -> JSONObject {
        return ["id" : self.id, "username" : self.username ?? NSNull()]
    }
}