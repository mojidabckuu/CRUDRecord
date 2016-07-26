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

/* Descrives an item that can be canceled or resumed */
public protocol Task {
    func cancel()
    func resume()
}

extension NSURLSessionDataTask: Task {}
extension NSOperation: Task {
    public func resume() {
        self.start()
    }
}

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
    
    //    associatedtype ((CRUDResponse<Entity>) -> Void) = (CRUDResponse<Entity>) -> Void
    
    //        static func create(attributes: JSONObject, completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //
    //    func create(completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //    func show(completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //    static func index(completion: ((CRUDResponse<[Entity]>) -> Void)?) -> Task
    //    func patch(attributes: JSONObject, completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //    func update(completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //    func delete(completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    
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
    //    func request(action: String, attributes: JSONObject, options: [String: Any], completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //    func send(request: CRUDRequest<Entity>) -> Task
    
    //    static func request(action: String, attributes: JSONObject, options: [String: Any], completion: ((CRUDResponse<Entity>) -> Void)?) -> Task
    //    static func send(request: CRUDRequest<Entity>) -> Task
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

extension Request: Task {}

extension Request {
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<[Model], NSError> -> Void) -> Self {
        return response( queue: queue, responseSerializer: Request.JSONResponseSerializer(options: options), completionHandler: { (response) in
            var models: [Model] = []
            if let items = response.result.value as? JSONArray {
                models = items.map({ (json) -> Model in
                    let model = Model()
                    model.setAttributes(json)
                    return model
                })
            }
            let parsedResponse = Response<[Model], NSError>(request: response.request, response: response.response, data: response.data, result: .Success(models), timeline: response.timeline)
            completionHandler(parsedResponse)
        })
    }
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<Model, NSError> -> Void) -> Self {
        return response( queue: queue, responseSerializer: Request.JSONResponseSerializer(options: options), completionHandler: { (response) in
            var model: Model! = nil
            if let item = response.result.value as? JSONObject {
                let model = Model()
                model.setAttributes(item)
            }
            let parsedResponse = Response<Model, NSError>(request: response.request, response: response.response, data: response.data, result: .Success(model), timeline: response.timeline)
            completionHandler(parsedResponse)
        })
    }
    
    func parseJSON<Model: Initiable>(complationHandler: Response<Model, NSError> -> Void) -> Self {
        return self
    }
    
}

typealias ModelCompletion = (Response<Record.Type, NSError> -> Void)
typealias ModelsCompletion = (Response<Record.Type, NSError> -> Void)

extension CRUDRecord {
    
    // MARK: - Predefined
    
    static func create(attributes: JSONObject, completion: (Response<Self, NSError> -> Void)) -> Task {
        let URLString = CRUD.URLBuilder().build(nil, path: self.pathName + CRUD.Action.Create.pattern)
        return request(.POST, URLString, parameters: attributes, encoding: .URL, headers: nil).parseJSON(completionHandler: completion)
    }
    
    func create(completion: (Response<Self, NSError> -> Void)) -> Task {
        return self.generic(.Create, attributes: self.getAttributes(CRUD.Action.Create.rawValue))
    }
    
    func show(completion: (Response<Self, NSError> -> Void)) -> Task {
        let attributes = self.getAttributes(CRUD.Action.Show.rawValue)
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + CRUD.Action.Show.pattern)
        return request(.POST, URLString, parameters: attributes, encoding: .URL, headers: nil).parseJSON(completionHandler: completion)
    }
    
    static func index(completion: (Response<Self, NSError> -> Void)) -> Task {
        let URLString = CRUD.URLBuilder().build(nil, path: self.pathName + CRUD.Action.Index.pattern)
        return request(.POST, URLString, parameters: [:], encoding: .URL, headers: nil).parseJSON(completionHandler: completion)
    }
    
    func patch(attributes: JSONObject, completion: (Response<Self, NSError> -> Void)) -> Task {
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + CRUD.Action.Patch.pattern)
        return request(.POST, URLString, parameters: attributes, encoding: .URL, headers: nil).parseJSON(completionHandler: completion)
    }
    
    func update(completion: (Response<Self, NSError> -> Void)) -> Task {
        let attributes = self.getAttributes(CRUD.Action.Update.rawValue)
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + CRUD.Action.Update.pattern)
        return request(.POST, URLString, parameters: attributes, encoding: .URL, headers: nil).parseJSON(completionHandler: completion)
    }
    
    func delete(completion: (Response<Self, NSError> -> Void)) -> Task {
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + CRUD.Action.Delete.pattern)
        return request(.POST, URLString, parameters: [:], encoding: .URL, headers: nil).parseJSON(completionHandler: completion)
    }
    
    func generic(action: CRUD.Action, attributes: [String: Any] = [:]) -> Request {
        let URLString = CRUD.URLBuilder().build(self, path: self.dynamicType.pathName + action.pattern)
        return request(.POST, URLString, parameters: [:], encoding: .URL, headers: nil)
    }
    
    static func generic(action: CRUD.Action, attributes: [String: Any] = [:]) -> Request {
        let URLString = CRUD.URLBuilder().build(nil, path: self.pathName + action.pattern)
        return request(action.method, URLString, parameters: [:], encoding: .URL, headers: nil)
    }
    
}