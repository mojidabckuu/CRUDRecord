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

public extension MultipartFormData {
    func append(_ value: String, withName name: String) {
        if let data = value.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            self.append(data, withName: name)
        }
    }
    
    func append<T: RawRepresentable>(_ value: T, withName name: String) {
        if let value = value.rawValue as? String {
            self.append(value, withName: name)
        }
    }
}

extension Alamofire.Request {
    public func debugLog() -> Self {
        #if DEBUG
            debugPrint(self)
        #endif
        return self
    }
}

typealias ModelCompletion = ((DataResponse<Record.Type>) -> Void)
typealias ModelsCompletion = ((DataResponse<Record.Type>) -> Void)

extension Alamofire.Request {
//    public static func JSONParseSerializer<Model: Record>(model: Model? = nil, options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<Model, NSError> {
//        return ResponseSerializer { request, response, data, error in
//            let jsonResponse = JSONResponseSerializer().serializeResponse(request, response, data, error)
//            if CRUD.Configuration.defaultConfiguration.loggingEnabled {
//                print("JSON: \(jsonResponse)")
//            }
//            guard let error = jsonResponse.error else {
//                var model: Model = Model()
//                if var item = jsonResponse.value as? JSONObject {
//                    if CRUD.Configuration.defaultConfiguration.traitRoot {
//                        let key = Model.resourceName.lowercaseString
//                        item = (item[key] as? JSONObject) ?? item
//                    }
//                    model.attributes = item.pure
//                }
//                return .Success(model)
//            }
//            return .Failure(error)
//        }
//    }
//    
//    public static func JSONParseSerializer<Model: Record>(options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<[Model], NSError> {
//        return ResponseSerializer { request, response, data, error in
//            let jsonResponse = JSONResponseSerializer().serializeResponse(request, response, data, error)
//            if CRUD.Configuration.defaultConfiguration.loggingEnabled {
//                print("JSON: \(jsonResponse)")
//            }
//            guard let error = jsonResponse.error else {
//                var models: [Model] = []
//                if let items = jsonResponse.value as? JSONArray {
//                    models = items.map({ (json) -> Model in
//                        var model = Model()
//                        model.attributes = json.pure
//                        return model
//                    })
//                } else if var item = jsonResponse.value as? JSONObject {
//                    let key = Model.resourceName.pluralized.lowercaseString
//                    if let items = item[key] as? JSONArray, CRUD.Configuration.defaultConfiguration.traitRoot {
//                        models = items.map({ (json) -> Model in
//                            var model = Model()
//                            model.attributes = json.pure
//                            return model
//                        })
//                    }
//                }
//                return .Success(models)
//            }
//            return .Failure(error)
//        }
//    }
}

extension Alamofire.Request {
    
//    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<[Model], NSError> -> Void) -> Self {
//        if CRUD.Configuration.defaultConfiguration.loggingEnabled {
//            
//        }
//        return self.response(queue: queue, responseSerializer: Alamofire.Request.JSONParseSerializer(options: options), completionHandler: completionHandler)
//    }
//    
//    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: (Response<Model, NSError> -> Void)) -> Self {
//        return self.response(queue: queue, responseSerializer: Alamofire.Request.JSONParseSerializer(options: options), completionHandler: completionHandler)
//    }
//    
//    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, model: Model, completionHandler: (Response<Model, NSError> -> Void)) -> Self {
//        return self.response(queue: queue, responseSerializer: Alamofire.Request.JSONParseSerializer(model, options: options), completionHandler: completionHandler)
//    }
}

/// A generic `DataResponseSerializerType` used to serialize a request, response, and data into a serialized object.
public struct DataArrayResponseSerializer<Value>: DataResponseSerializerProtocol {
    /// The type of serialized object to be created by this `DataResponseSerializer`.
    public typealias SerializedObject = [Value]
    
    /// A closure used by response handlers that takes a request, response, data and error and returns a result.
    public var serializeResponse: (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<[Value]>
    
    /// Initializes the `ResponseSerializer` instance with the given serialize response closure.
    ///
    /// - parameter serializeResponse: The closure used to serialize the response.
    ///
    /// - returns: The new generic response serializer instance.
    public init(serializeResponse: @escaping (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Result<[Value]>) {
        self.serializeResponse = serializeResponse
    }
}


extension Alamofire.DataRequest {
    
    static func handleErrors(data: Data?) -> Error? {
        if let data = data, let string = String(data: data, encoding: .utf8) {
            var json = JSONParser(string).parse() as? [String: Any]
            if let errors = json?["errors"] as? [String: Any], !errors.isEmpty {
                if let key = errors.keys.first, let errorInfo = errors[key] as? [[String: Any]], let message = errorInfo.first?["message"] as? String {
                    let info = [NSLocalizedDescriptionKey: message]
                    let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
                    return error
                }
            }
        }
        return nil
    }
    
    public static func ObjectMapperSerializer<T: Record>(keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil, mapper: MapOf<T>? = nil) -> DataResponseSerializer<T> {
        return DataResponseSerializer { request, response, data, error in
            if let error = error {
                return .failure(error)
            }
            
            if let error = Alamofire.DataRequest.handleErrors(data: data) {
                return .failure(error)
            }
            
            guard let _ = data else {
                let info = [NSLocalizedDescriptionKey: "Data could not be serialized. Input data was nil."]
                let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
                return .failure(error)
            }
            
            var OriginalJSONToMap: [String: Any]?
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    OriginalJSONToMap = JSONParser(string).parse() as? [String: Any]
                }
            }
            CRUDLog.warning("Response: \(response?.statusCode) : \n" + "\(OriginalJSONToMap)")
            
            let JSONToMap: Any?
            if var keyPath = keyPath {
                if keyPath.isEmpty {
                    keyPath = T.resourceName.pluralized.lowercased()
                }
                JSONToMap = OriginalJSONToMap?[keyPath]
            } else {
                let resourceName = T.resourceName
                JSONToMap = OriginalJSONToMap?[resourceName] ?? OriginalJSONToMap
            }
            
            if let object = object {
                Mapper<T>(context: context).map(JSONToMap, toObject: object)
                return .success(object)
            } else if let parsedObject = Mapper<T>(context: context).map(JSONToMap){
                return .success(parsedObject)
            }
            
            let info = [NSLocalizedDescriptionKey: "ObjectMapper failed to serialize response."]
            let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
            return .failure(error)
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
    
    public static func ObjectMapperArraySerializer<T: Record>(keyPath: String?, context: MapContext? = nil, mapper: MapOf<T>? = nil) -> DataResponseSerializer<[T]> {
        return DataResponseSerializer(serializeResponse: { (request, response, data, error) -> Result<[T]> in
            if let error = error {
                return .failure(error)
            }
            
            if let error = Alamofire.DataRequest.handleErrors(data: data) {
                return .failure(error)
            }
            
            guard let _ = data else {
                let info = [NSLocalizedDescriptionKey: "Data could not be serialized. Input data was nil."]
                let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
                return .failure(error)
            }
            
            var OriginalJSONToMap: [[String: Any]] = []
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    let json = JSONParser(string).parse()
                    if let object = json as? [String: Any] {
                        if var keyPath = keyPath {
                            if keyPath.isEmpty {
                                keyPath = T.resourceName.pluralized.lowercased()
                            }
                            OriginalJSONToMap = (object[keyPath] as? [[String: Any]]) ?? []
                        } else {
                            let resourceName = T.resourceName.pluralized.lowercased()
                            OriginalJSONToMap = (object[resourceName] as? [[String: Any]]) ?? object as? [[String: Any]] ?? []
                        }
                    } else {
                        OriginalJSONToMap = (json as? [[String: Any]]) ?? []
                    }
                }
            }
            CRUDLog.warning("Response: \(response?.statusCode) : \n" + "\(OriginalJSONToMap)")
            
            if let parsedObject = Mapper<T>(context: context).mapArray(OriginalJSONToMap){
                return .success(parsedObject)
            }
            
            let info = [NSLocalizedDescriptionKey: "ObjectMapper failed to serialize response."]
            let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
            return .failure(error)
        })
        return DataResponseSerializer { request, response, data, error in
            if let error = error {
                return .failure(error)
            }
            
            if let error = Alamofire.DataRequest.handleErrors(data: data) {
                return .failure(error)
            }
            
            guard let _ = data else {
                let info = [NSLocalizedDescriptionKey: "Data could not be serialized. Input data was nil."]
                let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
                return .failure(error)
            }
            
            var OriginalJSONToMap: [[String: Any]] = []
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    let json = JSONParser(string).parse()
                    if let object = json as? [String: Any] {
                        if var keyPath = keyPath {
                            if keyPath.isEmpty {
                                keyPath = T.resourceName.pluralized.lowercased()
                            }
                            OriginalJSONToMap = (object[keyPath] as? [[String: Any]]) ?? []
                        } else {
                            let resourceName = T.resourceName.pluralized.lowercased()
                            OriginalJSONToMap = (object[resourceName] as? [[String: Any]]) ?? object as? [[String: Any]] ?? []
                        }
                    } else {
                        OriginalJSONToMap = (json as? [[String: Any]]) ?? []
                    }
                }
            }
            CRUDLog.warning("Response: \(response?.statusCode) : \n" + "\(OriginalJSONToMap)")
            
            if let parsedObject = Mapper<T>(context: context).mapArray(OriginalJSONToMap){
                return .success(parsedObject)
            }
            
            let info = [NSLocalizedDescriptionKey: "ObjectMapper failed to serialize response."]
            let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
            return .failure(error)
        }
    }
    
    public func responseObject<T: Record>(queue queue: DispatchQueue? = nil, keyPath: String? = nil, mapToObject object: T? = nil, mapper: MapOf<T>? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        let serializer = Alamofire.DataRequest.ObjectMapperSerializer(keyPath: keyPath, mapToObject: object, context: context)
        return response(queue: queue, responseSerializer: serializer, completionHandler: completionHandler)
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue: The queue on which the completion handler is dispatched.
     - parameter keyPath: The key path where object mapping should be performed
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    
    
    public func responseArray<T: Record>(queue queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        let seri = DataArrayResponseSerializer { (request, response, data, error) -> Result<[T]> in
            if let error = error {
                return .failure(error)
            }
            
            if let error = Alamofire.DataRequest.handleErrors(data: data) {
                return .failure(error)
            }
            
            guard let _ = data else {
                let info = [NSLocalizedDescriptionKey: "Data could not be serialized. Input data was nil."]
                let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
                return .failure(error)
            }
            
            var OriginalJSONToMap: [[String: Any]] = []
            if let data = data {
                if let string = String(data: data, encoding: .utf8) {
                    let json = JSONParser(string).parse()
                    if let object = json as? [String: Any] {
                        if var keyPath = keyPath {
                            if keyPath.isEmpty {
                                keyPath = T.resourceName.pluralized.lowercased()
                            }
                            OriginalJSONToMap = (object[keyPath] as? [[String: Any]]) ?? []
                        } else {
                            let resourceName = T.resourceName.pluralized.lowercased()
                            OriginalJSONToMap = (object[resourceName] as? [[String: Any]]) ?? object as? [[String: Any]] ?? []
                        }
                    } else {
                        OriginalJSONToMap = (json as? [[String: Any]]) ?? []
                    }
                }
            }
            CRUDLog.warning("Response: \(response?.statusCode) : \n" + "\(OriginalJSONToMap)")
            
            if let parsedObject = Mapper<T>(context: context).mapArray(OriginalJSONToMap){
                return .success(parsedObject)
            }
            
            let info = [NSLocalizedDescriptionKey: "ObjectMapper failed to serialize response."]
            let error = NSError(domain: "com.json.ahahah", code: 0, userInfo: info)
            return .failure(error)
        }
        return response(queue: queue, responseSerializer: seri, completionHandler: completionHandler)
    }

    // Map utils
    @discardableResult
    public func map<T: Record>(queue queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, _ completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return self.responseArray(queue: queue, keyPath: keyPath, context: context, completionHandler: completionHandler)
    }
    @discardableResult
    public func map<T: Record>(queue queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, mapper: MapOf<T>? = nil, _ completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return self.responseObject(queue: queue, keyPath: keyPath, context: context, completionHandler: completionHandler)
    }
    @discardableResult
    public func map<T: Record>(object: T, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return self.responseObject(queue: nil, keyPath: nil, mapToObject: object, mapper: nil, context: nil, completionHandler: completionHandler)
    }
}
