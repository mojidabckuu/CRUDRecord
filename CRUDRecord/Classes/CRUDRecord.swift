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

public typealias JSONObject = RecordObject
public typealias JSONArray = RecordArray

public enum CRUD {
    
    /* Default HTTP actions commonly used */
    public enum Action: String {
        case Create = "create"
        case Show = "show"
        case Index = "index"
        case Patch = "patch"
        case Update = "update"
        case Delete = "delete"
        
        public var pattern: String {
            switch self {
            case .Show, .Update, .Patch, .Delete: return "/" + Configuration.defaultConfiguration.idPath
            default: return ""
            }
        }
    }
    
    public struct Attachement {
        var data: NSData?
        var url: NSURL?
    }
    
    public struct Configuration {
        public var baseURL: String?
        public var prefix: String?
        
        public var traitRoot: Bool = true
        public var idPath = "\\(id)"
        
        public static var defaultConfiguration = Configuration(baseURL: nil, prefix: nil)
        
        init(baseURL: String?, prefix: String?) {
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
            if result.hasPrefix("/") {
                return (CRUD.Configuration.defaultConfiguration.baseURL ?? "") + "/" + (CRUD.Configuration.defaultConfiguration.prefix ?? "") + result
            } else {
                return (CRUD.Configuration.defaultConfiguration.baseURL ?? "") + "/" + (CRUD.Configuration.defaultConfiguration.prefix ?? "") + "/" + result
            }
        }
    }
    
}

public protocol CRUDRecord: Record {
    
    associatedtype Entity = Self
    associatedtype RecordResponse = Response<Self, NSError>
    associatedtype RecordsResponse = Response<[Self], NSError>
    
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

extension CRUD.Action {
    var method: Alamofire.Method {
        switch self {
        case .Show, .Index: return Method.GET
        case .Create: return Method.POST
        case .Delete: return Method.DELETE
        case .Patch: return Method.PATCH
        case .Update: return Method.PUT
        }
    }
}

public extension CRUDRecord {
    
    // MARK: - Base
    
    public func request(action: CRUD.Action, attributes: [String: AnyObject] = [:], options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + action.pattern)
        let request = Alamofire.request(action.method, URLString, parameters: [:], encoding: .URL, headers: nil)
        let proxy = CRUD.Request.Proxy(request: request, model: self)
        return proxy
    }
    
    public static func request(action: CRUD.Action, attributes: [String: AnyObject] = [:], options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        let URLString = CRUD.URLBuilder().build(nil, path: self.pathName + action.pattern)
        let request = Alamofire.request(action.method, URLString, parameters: attributes, encoding: .URL, headers: nil)
        let proxy = CRUD.Request.Proxy(request: request)
        return proxy
    }
    
    // MARK: - Predefined
    
    public static func create(attributes: JSONObject, options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Create, attributes: attributes, options: options)
    }
    public func create(options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Create, attributes: self.getAttributes(CRUD.Action.Create.rawValue), options: options)
    }
    public func show(options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Show, attributes: self.getAttributes(CRUD.Action.Create.rawValue), options: options)
    }
    public static func index(attributes: JSONObject = [:], options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Index, attributes: [:], options: options)
    }
    public func patch(attributes: JSONObject, options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Patch, attributes: attributes, options: options)
    }
    public func update(options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Update, attributes: self.getAttributes(CRUD.Action.Update.rawValue), options: options)
    }
    public func delete(options: [String: Any] = [:]) -> CRUD.Request.Proxy {
        return self.request(.Delete, attributes: self.getAttributes(CRUD.Action.Delete.rawValue), options: options)
    }
}