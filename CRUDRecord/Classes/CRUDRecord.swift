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

public enum CRUD {
    
    /* Default HTTP actions commonly used */
    public enum Action: String {
        case Create = "create"
        case Show = "show"
        case Index = "index"
        case Patch = "patch"
        case Update = "update"
        case Delete = "delete"
        
        var pattern: String {
            switch self {
            case .Show, .Update, .Patch, .Delete: return "\\(id)"
            default: return ""
            }
        }
    }
    
    public struct Attachement {
        var data: NSData?
        var url: NSURL?
    }
    
    struct Configuration {
        var baseURL: String?
        var prefix: String?
        
        static let defaultConfiguration = Configuration(baseURL: nil, prefix: nil)
        
        init(baseURL: String?, prefix: String?) {
            self.baseURL = baseURL
            self.prefix = prefix
        }
    }
    
    class URLBuilder {
        
        var pattern = "\\(([0-9a-zA-Z]+\\))" // Default patten that takes Swift interpolation \(propertyName)
        
        func build(record: Record?, path: String) -> String {
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
            return (CRUD.Configuration.defaultConfiguration.baseURL ?? "") + "/" + result
        }
    }
    
}

public protocol CRUDRecord: class, Record {
    
    associatedtype Entity = Self
    associatedtype RecordResponse = Response<Self, NSError>
    
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

extension CRUDRecord {
    public static var pathName: String {
        let components = self.modelName.componentsSeparatedByString(".").map({ $0.lowercaseString.pluralized })
        return components.dropLast().joinWithSeparator("/") + "/" + components.last!.lowercaseString
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

// Extension that parses into models.
// Duplicates code from original parse to JSON and initializes models on the save queue.
extension Request {
    public static func JSONParseSerializer<Model: Record>(options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<Model, NSError> {
        return ResponseSerializer { request, response, data, error in
            let jsonResponse = JSONResponseSerializer().serializeResponse(request, response, data, error)
            guard let error = jsonResponse.error else {
                let model: Model = Model()
                if let item = jsonResponse.value as? JSONObject {
                    model.setAttributes(item)
                }
                return .Success(model)
            }
            return .Failure(error)
        }
    }
    
    public static func JSONParseSerializer<Model: Record>(options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<[Model], NSError> {
        return ResponseSerializer { request, response, data, error in
            let jsonResponse = JSONResponseSerializer().serializeResponse(request, response, data, error)
            guard let error = jsonResponse.error else {
                var models: [Model] = []
                if let items = jsonResponse as? JSONArray {
                    models = items.map({ (json) -> Model in
                        let model = Model()
                        model.setAttributes(json)
                        return model
                    })
                }
                return .Success(models)
            }
            return .Failure(error)
        }
    }
}

typealias ModelCompletion = (Response<Record.Type, NSError> -> Void)
typealias ModelsCompletion = (Response<Record.Type, NSError> -> Void)

extension Request {
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<[Model], NSError> -> Void) -> Self {
        return response(queue: queue, responseSerializer: Request.JSONParseSerializer(options: options), completionHandler: completionHandler)
    }
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: (Response<Model, NSError> -> Void)) -> Self {
        return response(queue: queue, responseSerializer: Request.JSONParseSerializer(options: options), completionHandler: completionHandler)
    }
}


extension CRUDRecord {

    // MARK: - Base
    
    public func request(action: CRUD.Action, attributes: [String: AnyObject] = [:], options: [String: Any] = [:]) -> Request {
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + action.pattern)
        return Alamofire.request(action.method, URLString, parameters: [:], encoding: .URL, headers: nil)
    }
    
    public static func request(action: CRUD.Action, attributes: [String: AnyObject] = [:], options: [String: Any] = [:]) -> Request {
        let URLString = CRUD.URLBuilder().build(nil, path: self.pathName + action.pattern)
        return Alamofire.request(action.method, URLString, parameters: [:], encoding: .URL, headers: nil)
    }
    
    // MARK: - Predefined
    
    public static func create(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Create, attributes: attributes, options: options)
    }
    public func create(options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Create, attributes: self.getAttributes(CRUD.Action.Create.rawValue), options: options)
    }
    public func show(options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Show, attributes: self.getAttributes(CRUD.Action.Create.rawValue), options: options)
    }
    public static func index(attributes: JSONObject = [:], options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Index, attributes: [:], options: options)
    }
    public func patch(attributes: JSONObject, options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Patch, attributes: attributes, options: options)
    }
    public func update(options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Update, attributes: self.getAttributes(CRUD.Action.Update.rawValue), options: options)
    }
    public func delete(options: [String: Any] = [:]) -> Alamofire.Request {
        return self.request(.Delete, attributes: self.getAttributes(CRUD.Action.Delete.rawValue), options: options)
    }
}