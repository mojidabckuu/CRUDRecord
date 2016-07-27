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

public extension CRUD {
    public class Request {
        public class Proxy {
            var model: Record?
            
            init(request: Alamofire.Request, model: Record? = nil) {
                self.ALRequest = request
                self.model = model
            }
            
            var ALRequest: Alamofire.Request
            /// The delegate for the underlying task.
            public var delegate: Alamofire.Request.TaskDelegate { return ALRequest.delegate }
            
            /// The underlying task.
            public var task: NSURLSessionTask { return self.ALRequest.task }
            
            /// The session belonging to the underlying task.
            public var session: NSURLSession { return self.ALRequest.session }
            
            /// The request sent or to be sent to the server.
            public var request: NSURLRequest? { return task.originalRequest }
            
            /// The response received from the server, if any.
            public var response: NSHTTPURLResponse? { return task.response as? NSHTTPURLResponse }
            
            /// The progress of the request lifecycle.
            public var progress: NSProgress { return self.ALRequest.progress }
            
            public func authenticate(user user: String, password: String, persistence: NSURLCredentialPersistence = .ForSession) -> Self {
                self.ALRequest.authenticate(user: user, password: password, persistence: persistence)
                return self
            }
            
            /**
             Associates a specified credential with the request.
             
             - parameter credential: The credential.
             
             - returns: The request.
             */
            public func authenticate(usingCredential credential: NSURLCredential) -> Self {
                self.ALRequest.authenticate(usingCredential: credential)
                return self
            }
            
            /**
             Returns a base64 encoded basic authentication credential as an authorization header dictionary.
             
             - parameter user:     The user.
             - parameter password: The password.
             
             - returns: A dictionary with Authorization key and credential value or empty dictionary if encoding fails.
             */
            public static func authorizationHeader(user user: String, password: String) -> [String: String] {
                return Alamofire.Request.authorizationHeader(user: user, password: password)
            }
            
            // MARK: - Progress
            
            /**
             Sets a closure to be called periodically during the lifecycle of the request as data is written to or read
             from the server.
             
             - For uploads, the progress closure returns the bytes written, total bytes written, and total bytes expected
             to write.
             - For downloads and data tasks, the progress closure returns the bytes read, total bytes read, and total bytes
             expected to read.
             
             - parameter closure: The code to be executed periodically during the lifecycle of the request.
             
             - returns: The request.
             */
            public func progress(closure: ((Int64, Int64, Int64) -> Void)? = nil) -> Self {
                self.ALRequest.progress(closure)
                return self
            }
            
            /**
             Sets a closure to be called periodically during the lifecycle of the request as data is read from the server.
             
             This closure returns the bytes most recently received from the server, not including data from previous calls.
             If this closure is set, data will only be available within this closure, and will not be saved elsewhere. It is
             also important to note that the `response` closure will be called with nil `responseData`.
             
             - parameter closure: The code to be executed periodically during the lifecycle of the request.
             
             - returns: The request.
             */
            public func stream(closure: (NSData -> Void)? = nil) -> Self {
                self.ALRequest.stream(closure)
                return self
            }
            
            // MARK: - State
            
            /**
             Resumes the request.
             */
            public func resume() {
                self.ALRequest.resume()
            }
            
            /**
             Suspends the request.
             */
            public func suspend() {
                self.ALRequest.suspend()
            }
            
            /**
             Cancels the request.
             */
            public func cancel() {
                self.ALRequest.cancel()
            }
        }
        struct Options {
            var path: String?
            var baseURL: String
            var method: String?
            var prefix: String?
            var query: [String: Any] = [:]
            
            init(attributes: [String: Any]) {
                self.path = attributes["path"] as? String
                self.method = (attributes["method"] as? String)
                self.baseURL = (attributes["baseURL"] as? String) ?? Configuration.defaultConfiguration.baseURL!
                self.prefix = (attributes["baseURL"] as? String) ?? Configuration.defaultConfiguration.prefix
                self.query = (attributes["query"] as? [String: Any]) ?? self.query
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension CRUD.Request.Proxy: CustomStringConvertible {
    
    /**
     The textual representation used when written to an output stream, which includes the HTTP method and URL, as
     well as the response status code if a response has been received.
     */
    public var description: String { return self.ALRequest.description }
}

// MARK: - CustomDebugStringConvertible

extension CRUD.Request.Proxy: CustomDebugStringConvertible {
    /// The textual representation used when written to an output stream, in the form of a cURL command.
    public var debugDescription: String {
        return self.ALRequest.debugDescription
    }
}

extension CRUD.Request.Proxy {
    /**
     A closure executed once a request has successfully completed in order to determine where to move the temporary
     file written to during the download process. The closure takes two arguments: the temporary file URL and the URL
     response, and returns a single argument: the file URL where the temporary file should be moved.
     */
    public typealias DownloadFileDestination = (NSURL, NSHTTPURLResponse) -> NSURL
    
    /**
     Creates a download file destination closure which uses the default file manager to move the temporary file to a
     file URL in the first available directory with the specified search path directory and search path domain mask.
     
     - parameter directory: The search path directory. `.DocumentDirectory` by default.
     - parameter domain:    The search path domain mask. `.UserDomainMask` by default.
     
     - returns: A download file destination closure.
     */
    public class func suggestedDownloadDestination(directory directory: NSSearchPathDirectory = .DocumentDirectory, domain: NSSearchPathDomainMask = .UserDomainMask) -> DownloadFileDestination {
        return Alamofire.Request.suggestedDownloadDestination(directory: directory, domain: domain)
    }
    
    /// The resume data of the underlying download task if available after a failure.
    public var resumeData: NSData? { return self.ALRequest.resumeData }
}

extension CRUD.Request.Proxy {
    
    /**
     Used to represent whether validation was successful or encountered an error resulting in a failure.
     
     - Success: The validation was successful.
     - Failure: The validation failed encountering the provided error.
     */
    public typealias ValidationResult = Alamofire.Request.ValidationResult
    
    /**
     A closure used to validate a request that takes a URL request and URL response, and returns whether the
     request was valid.
     */
    public typealias Validation = Alamofire.Request.Validation
    
    /**
     Validates the request, using the specified closure.
     
     If validation fails, subsequent calls to response handlers will have an associated error.
     
     - parameter validation: A closure to validate the request.
     
     - returns: The request.
     */
    public func validate(validation: Validation) -> Self {
        self.ALRequest.validate(validation)
        return self
    }
    
    // MARK: - Status Code
    
    /**
     Validates that the response has a status code in the specified range.
     
     If validation fails, subsequent calls to response handlers will have an associated error.
     
     - parameter range: The range of acceptable status codes.
     
     - returns: The request.
     */
    public func validate<S: SequenceType where S.Generator.Element == Int>(statusCode acceptableStatusCode: S) -> Self {
        self.ALRequest.validate(statusCode: acceptableStatusCode)
        return self
    }
    
    /**
     Validates that the response has a content type in the specified array.
     
     If validation fails, subsequent calls to response handlers will have an associated error.
     
     - parameter contentType: The acceptable content types, which may specify wildcard types and/or subtypes.
     
     - returns: The request.
     */
    public func validate<S : SequenceType where S.Generator.Element == String>(contentType acceptableContentTypes: S) -> Self {
        self.ALRequest.validate(contentType: acceptableContentTypes)
        return self
    }
    
    // MARK: - Automatic
    
    /**
     Validates that the response has a status code in the default acceptable range of 200...299, and that the content
     type matches any specified in the Accept HTTP header field.
     
     If validation fails, subsequent calls to response handlers will have an associated error.
     
     - returns: The request.
     */
    public func validate() -> Self {
        self.ALRequest.validate()
        return self
    }
}

// MARK: - Default

extension CRUD.Request.Proxy {
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue:             The queue on which the completion handler is dispatched.
     - parameter completionHandler: The code to be executed once the request has finished.
     
     - returns: The request.
     */
    public func response(queue queue: dispatch_queue_t? = nil, completionHandler: (NSURLRequest?, NSHTTPURLResponse?, NSData?, NSError?) -> Void) -> Self {
        self.ALRequest.response(queue: queue, completionHandler: completionHandler)
        return self
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter queue:              The queue on which the completion handler is dispatched.
     - parameter responseSerializer: The response serializer responsible for serializing the request, response,
     and data.
     - parameter completionHandler:  The code to be executed once the request has finished.
     
     - returns: The request.
     */
    public func response<T: ResponseSerializerType>(queue queue: dispatch_queue_t? = nil, responseSerializer: T, completionHandler: Response<T.SerializedObject, T.ErrorObject> -> Void) -> Self {
        self.ALRequest.response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
        return self
    }
}

// MARK: - Data

extension CRUD.Request.Proxy {
    
    /**
     Creates a response serializer that returns the associated data as-is.
     
     - returns: A data response serializer.
     */
    public static func dataResponseSerializer() -> ResponseSerializer<NSData, NSError> {
        return Alamofire.Request.dataResponseSerializer()
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter completionHandler: The code to be executed once the request has finished.
     
     - returns: The request.
     */
    public func responseData(queue queue: dispatch_queue_t? = nil, completionHandler: Response<NSData, NSError> -> Void) -> Self {
        self.ALRequest.responseData(queue: queue, completionHandler: completionHandler)
        return self
    }
}

// MARK: - String

extension CRUD.Request.Proxy {
    
    /**
     Creates a response serializer that returns a string initialized from the response data with the specified
     string encoding.
     
     - parameter encoding: The string encoding. If `nil`, the string encoding will be determined from the server
     response, falling back to the default HTTP default character set, ISO-8859-1.
     
     - returns: A string response serializer.
     */
    public static func stringResponseSerializer(encoding encoding: NSStringEncoding? = nil) -> ResponseSerializer<String, NSError> {
        return Alamofire.Request.stringResponseSerializer()
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter encoding:          The string encoding. If `nil`, the string encoding will be determined from the
     server response, falling back to the default HTTP default character set,
     ISO-8859-1.
     - parameter completionHandler: A closure to be executed once the request has finished.
     
     - returns: The request.
     */
    public func responseString(queue queue: dispatch_queue_t? = nil, encoding: NSStringEncoding? = nil, completionHandler: Response<String, NSError> -> Void) -> Self {
        self.ALRequest.responseString(queue: queue, encoding: encoding, completionHandler: completionHandler)
        return self
    }
}

// MARK: - JSON

extension CRUD.Request.Proxy {
    
    /**
     Creates a response serializer that returns a JSON object constructed from the response data using
     `NSJSONSerialization` with the specified reading options.
     
     - parameter options: The JSON serialization reading options. `.AllowFragments` by default.
     
     - returns: A JSON object response serializer.
     */
    public static func JSONResponseSerializer(options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<AnyObject, NSError> {
        return Alamofire.Request.JSONResponseSerializer(options: options)
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter options:           The JSON serialization reading options. `.AllowFragments` by default.
     - parameter completionHandler: A closure to be executed once the request has finished.
     
     - returns: The request.
     */
    public func responseJSON(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<AnyObject, NSError> -> Void) -> Self {
        self.ALRequest.responseJSON(queue: queue, options: options, completionHandler: completionHandler)
        return self
    }
}

// MARK: - Property List

extension CRUD.Request.Proxy {
    
    /**
     Creates a response serializer that returns an object constructed from the response data using
     `NSPropertyListSerialization` with the specified reading options.
     
     - parameter options: The property list reading options. `NSPropertyListReadOptions()` by default.
     
     - returns: A property list object response serializer.
     */
    public static func propertyListResponseSerializer(options options: NSPropertyListReadOptions = NSPropertyListReadOptions()) -> ResponseSerializer<AnyObject, NSError> {
        return Alamofire.Request.propertyListResponseSerializer(options: options)
    }
    
    /**
     Adds a handler to be called once the request has finished.
     
     - parameter options:           The property list reading options. `0` by default.
     - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 3
     arguments: the URL request, the URL response, the server data and the result
     produced while creating the property list.
     
     - returns: The request.
     */
    public func responsePropertyList(queue queue: dispatch_queue_t? = nil, options: NSPropertyListReadOptions = NSPropertyListReadOptions(), completionHandler: Response<AnyObject, NSError> -> Void) -> Self {
        self.ALRequest.responsePropertyList(queue: queue, options: options, completionHandler: completionHandler)
        return self
    }
}

// Extension that parses into models.
// Duplicates code from original parse to JSON and initializes models on the save queue.
extension CRUD.Request.Proxy {
    public static func JSONParseSerializer<Model: Record>(model: Model? = nil, options options: NSJSONReadingOptions = .AllowFragments) -> ResponseSerializer<Model, NSError> {
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

extension CRUD.Request.Proxy {
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: Response<[Model], NSError> -> Void) -> Self {
        self.ALRequest.response(queue: queue, responseSerializer: CRUD.Request.Proxy.JSONParseSerializer(options: options), completionHandler: completionHandler)
        return self
    }
    
    public func parseJSON<Model: Record>(queue queue: dispatch_queue_t? = nil, options: NSJSONReadingOptions = .AllowFragments, completionHandler: (Response<Model, NSError> -> Void)) -> Self {
        if let r = self.model as? Model {
            self.ALRequest.response(queue: queue, responseSerializer: CRUD.Request.Proxy.JSONParseSerializer(r, options: options), completionHandler: completionHandler)
        } else {
            self.ALRequest.response(queue: queue, responseSerializer: CRUD.Request.Proxy.JSONParseSerializer(options: options), completionHandler: completionHandler)
        }
        return self
    }
}
