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
    var user: User!
    override func setUp() {
        super.setUp()
        
        self.user = User()
        self.user.setAttributes(["id" : "123", "username" : "vlad"])
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testActions() {
        let builder = CRUD.URLBuilder()
        
        var action: CRUD.Action = .Create
        var path = self.user.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users")
        XCTAssertEqual(builder.build(user, path: path), "/users")
        
        action = .Show
        path = self.user.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/123")
        
        action = .Index
        path = self.user.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users")
        XCTAssertEqual(builder.build(user, path: path), "/users")
        
        action = .Delete
        path = self.user.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/123")
        
        action = .Patch
        path = self.user.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/123")
        
        action = .Update
        path = self.user.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/123")
    }
    
    func testCustomPattern() {
        XCTAssertEqual(user.getAttributes()["id"] as? String, "123")
        XCTAssertEqual(user.id, "123")
        
        let builder = CRUD.URLBuilder()
        
        var path = builder.build(user, path: "/users/\\(id)/favorites")
        XCTAssertEqual(path, "/users/123/favorites")
        
        path = builder.build(user, path: "users/\\(id)/favorites")
        XCTAssertEqual(path, "/users/123/favorites")
    }
    
    func textNestedPattern() {
        
        let comment = User.Comment(attributes: ["id" : "x13", "text" : "This is awesome"], action: "")
        
        let builder = CRUD.URLBuilder()
        
        var action: CRUD.Action = .Create
        var path = comment.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/comments")
        XCTAssertEqual(builder.build(comment, path: path), "/users/comments")
        
        action = .Show
        path = comment.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/comments/\\(id)")
        XCTAssertEqual(builder.build(comment, path: path), "/users/comments/\\(id)")
        
        action = .Index
        path = User.Comment.pathName + action.pattern
        XCTAssertEqual(path, "/users/comments/")
        XCTAssertEqual(builder.build(user, path: path), "/users/comments")
        
        action = .Delete
        path = comment.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/comments/\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/comments/x13")
        
        action = .Patch
        path = comment.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/comments/\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/comments/x13")
        
        action = .Update
        path = comment.`class`.pathName + action.pattern
        XCTAssertEqual(path, "/users/comments\\(id)")
        XCTAssertEqual(builder.build(user, path: path), "/users/comments/x13")
        
    }
}
