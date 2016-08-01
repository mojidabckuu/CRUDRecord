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

public typealias JSONObject = [String: AnyObject]
public typealias JSONArray = [JSONObject]

public protocol RecordResponse {
    associatedtype RecordResponse = Alamofire.Response<Self, NSError>
    associatedtype RecordsResponse = Alamofire.Response<[Self], NSError>
}

public extension Dictionary where Key: StringLiteralConvertible, Value: Any {
    var pure: [Key: AnyObject] {
        var pure: [Key: AnyObject] = [:]
        for (k, v) in self {
            if let value = v as? AnyObject {
                pure[k] = value
            } else if let value = v as? RecordObject {
                pure[k] = value.pure
            } else if let value = v as? RecordsArray {
                pure[k] = value.map({ $0.pure })
            }
        }
        return pure
    }
}

public extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    var pure: [Key: Any] {
        var pure: [Key: Any] = [:]
        for (k, v) in self {
            pure[k] = v
        }
        return pure
    }
}

public typealias CRUDRouter = Router
public class Router: URLRequestConvertible {
    
    var options: RecordObject = [:]
    var method: Alamofire.Method = .GET
    var query: RecordObject = [:]
    var parameters: RecordObject = [:]
    var encoding: Alamofire.ParameterEncoding = .URL
    var model: Record?
    var modelType: Record.Type
    
    public init(_ model: Record, options: RecordObject = [:]) {
        self.model = model
        self.modelType = model.dynamicType
        self.options = options
    }
    
    public init(_ modelType: Record.Type, options: RecordObject = [:]) {
        self.modelType = modelType
        self.options = options
    }
    
    public func method(_ method: Alamofire.Method) -> Router {
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
        case .GET, .PUT, .PATCH, .DELETE: return CRUD.Configuration.defaultConfiguration.idPath
        default: return ""
        }
    }
    
    public var path: String {
        return (options["path"] as? String) ?? self.modelType.resourcesName + "/" + self.pattern
    }
    
    public var URLRequest: NSMutableURLRequest {
        let URL = NSURL(string: CRUD.Configuration.defaultConfiguration.baseURL!)!
        let URLString = CRUD.URLBuilder().build(self.model, path: self.path)
        var mutableURLRequest = NSMutableURLRequest(URL: URL.URLByAppendingPathComponent(CRUD.Configuration.defaultConfiguration.prefix).URLByAppendingPathComponent(URLString))
        mutableURLRequest.HTTPMethod = method.rawValue
        mutableURLRequest = Alamofire.ParameterEncoding.URLEncodedInURL.encode(mutableURLRequest, parameters: query.pure).0
        mutableURLRequest = self.encoding.encode(mutableURLRequest, parameters: query.pure).0
        return mutableURLRequest
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
            let regex = try? NSRegularExpression(pattern: self.pattern, options: NSRegularExpressionOptions.CaseInsensitive)
            let range = NSRange(location: 0, length: path.characters.count)
            let attributes = record?.getAttributes() ?? [:]
            var replacedString = String(path)
            if let matches = regex?.matchesInString(path, options: NSMatchingOptions.ReportProgress, range: range) {
                for match in matches {
                    let pat = (path as NSString).substringWithRange(match.range) as NSString
                    let key = pat.stringByReplacingOccurrencesOfString(")", withString: "").stringByReplacingOccurrencesOfString("(", withString: "")
                    if let replacement = attributes[key] {
                        replacedString = replacedString.stringByReplacingOccurrencesOfString("\\\(pat)", withString: "\(replacement)")
                    } else {
                        replacedString = replacedString.stringByReplacingOccurrencesOfString("\\\(pat)", withString: "")
                    }
                }
            }
            result = replacedString
            return result
        }
    }
    
}

public protocol CRUDRecord: Record {
    
    //    associatedtype Entity = Self
    //    associatedtype RecordResponse = Response<Self, NSError>
    //    associatedtype RecordsResponse = Response<[Self], NSError>
    
    /* Base method that handles request.
     It initializes URL task to perform loading.
     @options - way how to configure the flow
     - requestSerializer: CRUD.Serializer. Default is HTTP
     - responseSerializer: CRUD.Serializer. Default is HTTP
     - baseURL
     - prefix - [baseURL]/[prefix]/
     - path - [baseURL]/[prefix]/[path]. Supports templating "\(id)" with take self.id on object
     - query - [:] to add extra to your query. [baseURL]/[prefix]/[path]?[query]
     - method - One of the HTTP methods
     @attributes - values to serialize. To send attachements u can pass CRUD.Attachement
     */
}

public extension CRUDRecord {
    public static var pathName: String {
        let components = self.modelName.componentsSeparatedByString(".").map({ $0.lowercaseString.pluralized })
        return components.dropLast().joinWithSeparator("/") + "/" + components.last!.lowercaseString
    }
    
    public var `class`: Self.Type {
        return self.dynamicType
    }
}

public extension CRUDRecord {
    // MARK: - Predefined
    
    public static func create(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(Self.self, options: options).parameters(attributes.pure).method(.POST))
    }
    public func create(options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(Self.self, options: options).parameters(self.getAttributes().pure).method(.POST))
    }
    public func show(options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(self, options: options).parameters(self.getAttributes().pure).method(.GET))
    }
    public static func index(attributes: JSONObject = [:], options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(Self.self, options: options).query(attributes.pure).method(.GET))
    }
    public func index(options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(self, options: options).method(.GET))
    }
    public func patch(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(self, options: options).parameters(attributes.pure).method(.PATCH))
    }
    public func update(options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(self, options: options).parameters(self.getAttributes().pure).method(.PUT))
    }
    public func delete(options: [String: Any] = [:]) -> Alamofire.Request {
        return Alamofire.request(Router(self, options: options).query(self.getAttributes().pure).method(.DELETE))
    }
}