//
//  Request.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/27/16.
//
//

import Foundation
import Alamofire
import ApplicationSupport
import ObjectMapper

extension Alamofire.Request {
    public func debugLog() -> Self {
        #if DEBUG
            debugPrint(self)
        #endif
        return self
    }
}

typealias ModelCompletion = (Response<Record.Type, NSError> -> Void)
typealias ModelsCompletion = (Response<Record.Type, NSError> -> Void)

extension Alamofire.Request {
    public static func JSONParseSerializer<Model: Record>(model: Model? = nil, options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<Model, NSError> {
        return ResponseSerializer { request, response, data, error in
            let jsonResponse = JSONResponseSerializer().serializeResponse(request, response, data, error)
            if CRUD.Configuration.defaultConfiguration.loggingEnabled {
                print("JSON: \(jsonResponse)")
            }
            guard let error = jsonResponse.error else {
                var model: Model = Model()
                if var item = jsonResponse.value as? JSONObject {
                    if CRUD.Configuration.defaultConfiguration.traitRoot {
                        let key = Model.resourceName.lowercaseString
                        item = (item[key] as? JSONObject) ?? item
                    }
                    model.attributes = item.pure
                }
                return .Success(model)
            }
            return .Failure(error)
        }
    }
    
    public static func JSONParseSerializer<Model: Record>(options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<[Model], NSError> {
        return ResponseSerializer { request, response, data, error in
            let jsonResponse = JSONResponseSerializer().serializeResponse(request, response, data, error)
            if CRUD.Configuration.defaultConfiguration.loggingEnabled {
                print("JSON: \(jsonResponse)")
            }
            guard let error = jsonResponse.error else {
                var models: [Model] = []
                if let items = jsonResponse.value as? JSONArray {
                    models = items.map({ (json) -> Model in
                        var model = Model()
                        model.attributes = json.pure
                        return model
                    })
                } else if var item = jsonResponse.value as? JSONObject {
                    let key = Model.resourceName.pluralized.lowercaseString
                    if let items = (item[key] as? JSONArray) where CRUD.Configuration.defaultConfiguration.traitRoot {
                        models = items.map({ (json) -> Model in
                            var model = Model()
                            model.attributes = json.pure
                            return model
                        })
                    }
                }
                return .Success(models)
            }
            return .Failure(error)
        }
    }
}

extension Alamofire.Request {
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<[Model], NSError> -> Void) -> Self {
        if CRUD.Configuration.defaultConfiguration.loggingEnabled {
            
        }
        return self.response(queue: queue, responseSerializer: Alamofire.Request.JSONParseSerializer(options: options), completionHandler: completionHandler)
    }
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: (Response<Model, NSError> -> Void)) -> Self {
        return self.response(queue: queue, responseSerializer: Alamofire.Request.JSONParseSerializer(options: options), completionHandler: completionHandler)
    }
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, model: Model, completionHandler: (Response<Model, NSError> -> Void)) -> Self {
        return self.response(queue: queue, responseSerializer: Alamofire.Request.JSONParseSerializer(model, options: options), completionHandler: completionHandler)
    }
}

extension Alamofire.Request {
    internal static func newError(code: Error.Code, failureReason: String) -> NSError {
        let errorDomain = "com.alamofireobjectmapper.error"
        
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
        
        return returnError
    }
    
    public static func ObjectMapperSerializer<T: Record>(keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil) -> ResponseSerializer<T, NSError> {
        return ResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .Failure(error!)
            }
            
            guard let _ = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = newError(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            
            var OriginalJSONToMap: [String: Any]?
            if let data = data {
                if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                    OriginalJSONToMap = JSONParser(string).parse() as? [String: Any]
                }
            }
            
            let JSONToMap: Any?
            if var keyPath = keyPath {
                if keyPath.isEmpty {
                    keyPath = T.resourceName.pluralized.lowercaseString
                }
                JSONToMap = OriginalJSONToMap?[keyPath]
            } else {
                let resourceName = T.resourceName
                JSONToMap = OriginalJSONToMap?[resourceName] ?? OriginalJSONToMap
            }
            
            if let object = object {
                Mapper<T>().map(JSONToMap, toObject: object)
                return .Success(object)
            } else if let parsedObject = Mapper<T>(context: context).map(JSONToMap){
                return .Success(parsedObject)
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.DataSerializationFailed, failureReason: failureReason)
            return .Failure(error)
        }
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue:             The queue on which the completion handler is dispatched.
     - parameter keyPath:           The key path where object mapping should be performed
     - parameter object:            An object to perform the mapping on to
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    
    public func responseObject<T: Record>(queue queue: dispatch_queue_t? = nil, keyPath: String? = nil, mapToObject object: T? = nil, context: MapContext? = nil, completionHandler: Response<T, NSError> -> Void) -> Self {
        
        return response(queue: queue, responseSerializer: Alamofire.Request.ObjectMapperSerializer(keyPath, mapToObject: object, context: context), completionHandler: completionHandler)
    }
    
    public static func ObjectMapperArraySerializer<T: Record>(keyPath: String?, context: MapContext? = nil) -> ResponseSerializer<[T], NSError> {
        return ResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .Failure(error!)
            }
            
            guard let _ = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = newError(.DataSerializationFailed, failureReason: failureReason)
                return .Failure(error)
            }
            
            var OriginalJSONToMap: [[String: Any]] = []
            if let data = data {
                if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                    let json = JSONParser(string).parse()
                    if let object = json as? [String: Any] {
                        if var keyPath = keyPath {
                            if keyPath.isEmpty {
                                keyPath = T.resourceName.pluralized.lowercaseString
                            }
                            OriginalJSONToMap = (object[keyPath] as? [[String: Any]]) ?? []
                        } else {
                            let resourceName = T.resourceName.pluralized.lowercaseString
                            OriginalJSONToMap = (object[resourceName] as? [[String: Any]]) ?? object as? [[String: Any]] ?? []
                        }
                    } else {
                        OriginalJSONToMap = (json as? [[String: Any]]) ?? []
                    }
                }
            }
            
            if let parsedObject = Mapper<T>(context: context).mapArray(OriginalJSONToMap){
                return .Success(parsedObject)
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.DataSerializationFailed, failureReason: failureReason)
            return .Failure(error)
        }
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue: The queue on which the completion handler is dispatched.
     - parameter keyPath: The key path where object mapping should be performed
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    public func responseArray<T: Record>(queue queue: dispatch_queue_t? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: Response<[T], NSError> -> Void) -> Self {
        return response(queue: queue, responseSerializer: Request.ObjectMapperArraySerializer(keyPath, context: context), completionHandler: completionHandler)
    }
    
    public func map<T: Record>(queue queue: dispatch_queue_t? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: Response<[T], NSError> -> Void) -> Self {
        return self.responseArray(queue: queue, keyPath: keyPath, context: context, completionHandler: completionHandler)
    }
    public func map<T: Record>(queue queue: dispatch_queue_t? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: Response<T, NSError> -> Void) -> Self {
        return self.responseObject(queue: queue, keyPath: keyPath, context: context, completionHandler: completionHandler)
    }
    public func map<T: Record>(queue queue: dispatch_queue_t? = nil, keyPath: String? = nil, context: MapContext? = nil, object: T, completionHandler: Response<T, NSError> -> Void) -> Self {
        return self.responseObject(queue: queue, keyPath: keyPath, mapToObject: object, context: context, completionHandler: completionHandler)
    }
}