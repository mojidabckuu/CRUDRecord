import UIKit
import XCTest
//import CRUDRecord
//import Alamofire

//extension CRUDRecord {
//    typealias RecordResponse = Response<Self, NSError>
//}

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
        
//        User.create([:]).parseJSON { (response: User.RecordResponse) in
//            let user = response.result.value
//        }
//        User.create([:]).responseString { (response) in
//            let string = response.result.value
//        }
//        User.create([:]).responseData { (response) in
//            let data = response.result.value
//        }
//        User.create([:]).parseJSON(completionHandler: { (response: Response<User, NSError>) in
//            let user = response.result.value
//        })
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
