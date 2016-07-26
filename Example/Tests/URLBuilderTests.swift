//
//  URLBuilderTests.swift
//  CRUDRecord
//
//  Created by Vlad Gorbenko on 7/26/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import CRUDRecord
import Alamofire

class URLBuilderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPattern() {
        
        let user = User()
        user.setAttributes(["id" : "123", "username" : "vlad"])
        
        XCTAssertEqual(user.getAttributes()["id"] as? String, "123")
        
        XCTAssertEqual(user.id, "123")
        
        let builder = CRUD.URLBuilder()
        let path = builder.build(user, path: "/users/\\(id)/favorites")
        
        XCTAssertEqual(path, "/users/123/favorites")
        
    }
}
