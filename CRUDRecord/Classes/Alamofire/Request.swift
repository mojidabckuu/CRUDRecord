//
//  Request.swift
//  Pods
//
//  Created by Vlad Gorbenko on 7/27/16.
//
//

import Foundation
import ObjectMapper
import Alamofire

// TODO: It applies only to json based responses
open class Request {
    public private(set) var request: Alamofire.Request
    public private(set) var response: Alamofire.DataResponse<Any>?
    
    public init(_ request: Alamofire.Request) {
        self.request = request
    }
    
    public init(_ urlRequestConvertible: URLRequestConvertible) {
        self.request = SessionManager.current.request(urlRequestConvertible)
    }
    
    // TODO: How to rename it to `then`. It gives a ambiguous function call.
    @discardableResult
    public func next(_ completion: @escaping () -> ()) -> Request {
        guard let response = self.response else {
            completion()
            return self
        }
        completion()
        return self
    }
    
    func ensureResponse(_ completion: @escaping ((DataResponse<Any>) -> (Void))) {
        guard let response = self.response else {
            self.request.JSON(completionHandler: { (response) in
                self.response = response
                completion(response)
            })
            return
        }
        completion(response)
    }
    
    @discardableResult
    public func `catch`(_ completion: @escaping (Error) -> ()) -> Self{
        ensureResponse { response in
            if let error = response.result.error {
                completion(error)
            }
        }
        return self
    }
}

open class _Request<T: Model>: Request {}

struct CRUDContent: MapContext {
    var importantMappingInfo = "Info that I need during mapping"
}

public class ModelsRequest<T: Model>: _Request<T> {
    var _models: [T]?
    
    public var models: [T] { return _models ?? [] }
    
    //Implementation
    @discardableResult
    public func then(_ completion: @escaping ([T]) -> ()) -> Self {
        if let _ = _models {
            completion(models)
            return self
        }
        ensureResponse { response in
            guard let value = response.result.value as? [String: Any] else {
                // TODO: Add empty response error
                return
            }
            
            let name = T.modelName.pluralized.lowercased()
            guard let data = value[name] as? [[String: Any]] else {
                // TODO: Add empty response error
                return
            }
            // TODO: Here it should be optional creation for the object in case when data is wrong
            let models = data
                .map { Map(mappingType: .fromJSON, JSONDictionary: $0, toObject: false, context: CRUDContent()) }
                .map { map -> T in
                    var model = T.init()
                    model.mapping(map)
                    return model
            }
            let unwrapped = Array(models)
            self._models = unwrapped
            completion(unwrapped)
        }
        return self
    }
}

open class ModelRequest<T: Model>: _Request<T> {
    
    public private(set) var model: T?
    
    // MARK: - Lifecycle
    public init(_ request: Alamofire.Request, model: T? = nil) {
        super.init(request)
        self.model = model
    }
    
    public init(_ urlRequestConvertible: URLRequestConvertible, model: T? = nil) {
        super.init(urlRequestConvertible)
        self.model = model
    }
    
    // MARK: - Implementation
    @discardableResult
    public func then(_ completion: @escaping (T) -> ()) -> Self {
        if let model = self.model {
            return flush(completion)
        } else {
            return obtain(completion)
        }
    }
    
    //Flush to existing
    @discardableResult
    public func flush(_ completion: @escaping (T) -> ()) -> Self {
        return _flush(model: self.model!, completion: completion)
    }
    
    //Obtain single object
    @discardableResult
    public func obtain(_ completion: @escaping (T) -> ()) -> Self {
        return _flush(model: T(), completion: completion)
    }
    
    private func _flush(model: T, completion: @escaping (T) -> ()) -> Self {
        ensureResponse { response in
            guard let value = response.result.value as? [String: Any] else {
                // TODO: Add empty response error
                return
            }
            let name = T.modelName.lowercased()
            guard let data = value[name] as? [String: Any] else {
                // TODO: Add empty response error
                return
            }
            let map = Map(mappingType: .fromJSON, JSONDictionary: data, toObject: true, context: CRUDContent())
            var model = model
            model.mapping(map)
            self.model = model
            completion(model)
        }
        return self
    }
}
