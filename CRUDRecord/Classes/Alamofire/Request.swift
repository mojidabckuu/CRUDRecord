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
    // Map utils
    @discardableResult
    public func map<T: Record>(with queue: DispatchQueue? = nil, keyPath: String? = T.modelsName, context: MapContext? = nil, _ completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return self.responseArray(queue: queue, keyPath: keyPath, context: context, completionHandler: completionHandler)
    }
    @discardableResult
    public func map<T: Record>(with queue: DispatchQueue? = nil, keyPath: String? = T.modelName, context: MapContext? = nil, _ completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return self.responseObject(queue: queue, keyPath: keyPath, context: context, completionHandler: completionHandler)
    }
    @discardableResult
    public func map<T: Record>(object: T, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return self.responseObject(queue: nil, keyPath: T.modelName, mapToObject: object, context: nil, completionHandler: completionHandler)
    }
}

import Foundation
import Alamofire
import ObjectMapper

extension DataRequest {
    
    enum ErrorCode: Int {
        case noData = 1
        case dataSerializationFailed = 2
    }
    
    internal static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
        let errorDomain = "com.alamofireobjectmapper.error"
        
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
        
        return returnError
    }
    
    /// Utility function for checking for errors in response
    internal static func checkResponseForError(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) -> Error? {
        if let error = error {
            return error
        }
        guard let _ = data else {
            let failureReason = "Data could not be serialized. Input data was nil."
            let error = newError(.noData, failureReason: failureReason)
            return error
        }
        return nil
    }
    
    /// Utility function for extracting JSON from response
    internal static func processResponse(request: URLRequest?, response: HTTPURLResponse?, data: Data?, keyPath: String?) -> Any? {
        let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
        let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
        
        let JSON: Any?
        if let keyPath = keyPath , keyPath.isEmpty == false {
            JSON = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
        } else {
            JSON = result.value
        }
        
        return JSON
    }
    
    /// BaseMappable Object Serializer
    public static func ObjectMapperSerializer<T: Mappable>(_ keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil) -> DataResponseSerializer<T> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .failure(error!)
            }
            
            guard let _ = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = newError(.noData, failureReason: failureReason)
                return .failure(error)
            }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, error)
            
            let JSONToMap: Any?
            if let keyPath = keyPath , keyPath.isEmpty == false {
                JSONToMap = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
            } else {
                JSONToMap = result.value
            }
            
            if let object = object {
                _ = Mapper<T>().map(JSONObject: JSONToMap, toObject: object)
                return .success(object)
            } else if let parsedObject = Mapper<T>(context: context).map(JSONObject: JSONToMap){
                return .success(parsedObject)
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.dataSerializationFailed, failureReason: failureReason)
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
    @discardableResult
    public func responseObject<T: Mappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapToObject object: T? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperSerializer(keyPath, mapToObject: object, context: context), completionHandler: completionHandler)
    }
    
    /// BaseMappable Array Serializer
    public static func ObjectMapperArraySerializer<T: Mappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<[T]> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else {
                return .failure(error!)
            }
            
            guard let _ = data else {
                let failureReason = "Data could not be serialized. Input data was nil."
                let error = newError(.dataSerializationFailed, failureReason: failureReason)
                return .failure(error)
            }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, error)
            
            let JSONToMap: Any?
            if let keyPath = keyPath, keyPath.isEmpty == false {
                JSONToMap = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
            } else {
                JSONToMap = result.value
            }
            
            if let parsedObject = Mapper<T>(context: context).mapArray(JSONObject: JSONToMap){
                return .success(parsedObject)
            }
            
            let failureReason = "ObjectMapper failed to serialize response."
            let error = newError(.dataSerializationFailed, failureReason: failureReason)
            return .failure(error)
        }
    }
    
    /**
     Adds a handler to be called once the request has finished. T: BaseMappable
     
     - parameter queue: The queue on which the completion handler is dispatched.
     - parameter keyPath: The key path where object mapping should be performed
     - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
     
     - returns: The request.
     */
    @discardableResult
    public func responseArray<T: Mappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
        return response(queue: queue, responseSerializer: DataRequest.ObjectMapperArraySerializer(keyPath, context: context), completionHandler: completionHandler)
    }
}
