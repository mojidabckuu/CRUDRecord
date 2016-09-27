//
//  CRUDRecord.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/26/16.
//
//

import Foundation
import ApplicationSupport
import Alamofire
import ObjectMapper
import SwiftyBeaver

let CRUDLog = SwiftyBeaver.self

public typealias JSONObject = [String: Any]
public typealias JSONArray = [JSONObject]

public protocol RecordResponse {
    associatedtype RecordResponse = Alamofire.DataResponse<Self>
    associatedtype RecordsResponse = Alamofire.DataResponse<[Self]>
}

public typealias CRUDRouter = Router
public class Router: URLRequestConvertible {
    
    var options: RecordObject = [:]
    var method: Alamofire.HTTPMethod = .get
    var query: RecordObject = [:]
    var parameters: RecordObject = [:]
    var encoding: Alamofire.ParameterEncoding = URLEncoding()
    var model: Record?
    var modelType: Record.Type
    
    public init(_ model: Record, options: RecordObject = [:]) {
        self.model = model
        self.modelType = type(of: model)
        self.options = options
    }
    
    public init(_ modelType: Record.Type, options: RecordObject = [:]) {
        self.modelType = modelType
        self.options = options
    }
    
    public func method(_ method: Alamofire.HTTPMethod) -> Router {
        self.method = method
        return self
    }
    
    public func query(_ parameters: RecordObject) -> Router {
        self.query = parameters
        return self
    }
    
    public func parameters(_ parameters: RecordObject) -> Router {
        self.parameters = parameters
        return self
    }
    
    public func encoding(_ encoding: Alamofire.ParameterEncoding) -> Router {
        self.encoding = encoding
        return self
    }
    
    public var pattern: String {
        switch self.method {
        case .get, .put, .patch, .delete: return CRUD.Configuration.defaultConfiguration.idPath
        default: return ""
        }
    }
    
    public var path: String {
        return (options["path"] as? String) ?? self.modelType.resourcesName + "/" + self.pattern
    }
    
    public func asURLRequest() throws -> URLRequest {
        let URL = NSURL(string: CRUD.Configuration.defaultConfiguration.baseURL!)!
        let URLString = CRUD.URLBuilder().build(record: self.model, path: self.path)
        var request = URLRequest(url: (URL.appendingPathComponent(CRUD.Configuration.defaultConfiguration.prefix)?.appendingPathComponent(URLString))!)
        request.httpMethod = self.method.rawValue
        
//        mutableURLRequest = Alamofire.ParameterEncoding.URLEncodedInURL.encode(mutableURLRequest, parameters: query.pure).0
//        mutableURLRequest = self.encoding.encode(mutableURLRequest, parameters: parameters.pure).0
        return request
    }
    
}

public enum CRUD {
    
    public struct Attachement {
        var data: NSData?
        var url: NSURL?
    }
    
    public struct Configuration {
        public var baseURL: String?
        public var prefix: String = ""
        
        public var traitRoot: Bool = true
        public var idPath = "\\(id)"
        
        public var loggingEnabled = true
        
        public static var defaultConfiguration = Configuration(baseURL: nil)
        
        init(baseURL: String?, prefix: String = "") {
            self.baseURL = baseURL
            self.prefix = prefix
        }
    }
    
    public class URLBuilder {
        
        public var pattern: String
        
        // Default patten that takes Swift interpolation \(propertyName)
        public init(pattern: String = "\\(([0-9a-zA-Z]+\\))") {
            self.pattern = pattern
        }
        
        public func build(record: Record?, path: String) -> String {
            var result = ""
            let regex = try? NSRegularExpression(pattern: self.pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSRange(location: 0, length: path.characters.count)
            let attributes = record?.attributes ?? [:]
            var replacedString = String(path)!
            if let matches = regex?.matches(in: path, options: NSRegularExpression.MatchingOptions.reportProgress, range: range) {
                for match in matches {
                    let pat = (path as NSString).substring(with: match.range) as NSString
                    let key = pat.replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "(", with: "")
                    if let replacement = attributes[key] {
                        replacedString = replacedString.replacingOccurrences(of: "\\\(pat)", with: "\(replacement)")
                    } else {
                        replacedString = replacedString.replacingOccurrences(of: "\\\(pat)", with: "")
                    }
                }
            }
            result = replacedString
            return result
        }
    }
}

public protocol CRUDRecord: Record {}

public extension CRUDRecord {
    public static var pathName: String {
        let components = self.modelName.components(separatedBy: ".").map({ $0.lowercased().pluralized })
        return components.dropLast().joined(separator: "/") + "/" + components.last!.lowercased()
    }
    
    public var `class`: Self.Type {
        return type(of: self)
    }
}

public extension CRUDRecord {
    public static func debug(_ request: Alamofire.Request) -> Alamofire.Request {
        CRUDLog.info(request.debugDescription)
        return request
    }
    // MARK: - Predefined

    public static func create(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(Self.self, options: options).parameters(attributes.pure).method(.post)).validate())
    }
    public func create(options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(Self.self, options: options).parameters(self.attributes).method(.post)).validate())
    }
    public func show(options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(self, options: options).parameters(self.attributes).method(.get)).validate())
    }
    public static func index(attributes: JSONObject = [:], options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(Self.self, options: options).query(attributes.pure).method(.get)).validate())
    }
    public func index(options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(self, options: options).method(.get)).validate())
    }
    public func patch(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(self, options: options).parameters(attributes).method(.patch)).validate())
    }
    public func update(options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(self, options: options).parameters(self.attributes).method(.put)).validate())
    }
    public func delete(options: [String: Any] = [:]) -> Alamofire.Request {
        return Self.debug(Alamofire.request(Router(self, options: options).query(self.attributes).method(.delete)).validate())
    }
    
//    public static func create(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(Self.self, options: options).parameters(attributes.pure).method(.post)))
//    }
//    public func create(options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(Self.self, options: options).parameters(self.attributes.pure).method(.post)))
//    }
//    public func show(options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(self, options: options).parameters(self.attributes.pure).method(.get)))
//    }
//    public static func index(attributes: JSONObject = [:], options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(Self.self, options: options).query(attributes.pure).method(.get)))
//    }
//    public func index(options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(self, options: options).method(.get)))
//    }
//    public func patch(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(self, options: options).parameters(attributes.pure).method(.PATCH)))
//    }
//    public func update(options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(self, options: options).parameters(self.attributes.pure).method(.PUT)))
//    }
//    public func delete(options: [String: Any] = [:]) -> Alamofire.Request {
//        return Self.debug(Alamofire.request(Router(self, options: options).query(self.attributes.pure).method(.DELETE)))
//    }
}
