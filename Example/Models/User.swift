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
import ObjectMapper

class User: CRUDRecord.CRRecord {
    public var timeline = ApplicationSupport.Timeline()
    
    var id: String!
    var username: String?
    
    required init() {}
    
    //MARK: -
    
    func setAttributes(_ attributes: JSONObject) {
        self.id = attributes["id"] as! String
        self.username = attributes["username"] as? String
    }
    
    func getAttributes() -> JSONObject {
        return [:]
//        return ["id" : self.id, "username" : self.username ?? NSNull()]
    }
    
    func mapping(_ map: Map) {
        
    }
}

typealias Author = User

extension Author {
    class Comment: CRUDRecord.CRRecord {
        public var timeline = ApplicationSupport.Timeline()
        
        var id: String!
        var text: String!
        
        //MARK: - Lifecycle
        
        required init() {}
        
        //MARK: -
        
        func setAttributes(_ attributes: JSONObject) {
            self.id = attributes["id"] as! String
            self.text = attributes["text"] as! String
        }
        
        func getAttributes() -> JSONObject {
//            return ["id" : self.id, "text" : self.text]
            return [:]
        }
        
        func mapping(_ map: Map) {
            
        }
    }
}
