//
//  Model.swift
//  Pods
//
//  Created by Vlad Gorbenko on 31/03/2017.
//
//

import Foundation
import ObjectMapper
import ApplicationSupport

public extension MetaRecord {
    public final static var modelsName: String {
        return self.modelName.pluralized.lowercased()
    }
}

public protocol _LocalModel {
    // Local update to refresh the model
    //    func update(with attributes: [String: Any])
}

public protocol Initiable {
    init()
}

public protocol _Model: _LocalModel, Initiable, MetaRecord {}

public protocol Model: _Model, Mappable {
    // TODO: How to validate expected response?
    static func validate(map: Map) -> Bool
    
    func create() -> ModelRequest<Self>
    func show() -> ModelRequest<Self>
    func patch(attributes: [String: Any]) -> ModelRequest<Self>
    func update(attributes: [String: Any]) -> ModelRequest<Self>
    func delete() -> ModelRequest<Self>
    
    static func index(attributes: [String: Any]) -> ModelsRequest<Self>
    static func create(attributes: [String: Any]) -> ModelRequest<Self>
}

public extension Model {
    // TODO: How to validate expected response?
    static func validate(map: Map) -> Bool { return true }
    
    func create() -> ModelRequest<Self> { fatalError("Not implemented") }
    func show() -> ModelRequest<Self> { fatalError("Not implemented") }
    func patch(attributes: [String: Any]) -> ModelRequest<Self> { fatalError("Not implemented") }
    func update(attributes: [String: Any]) -> ModelRequest<Self> { fatalError("Not implemented") }
    func delete() -> ModelRequest<Self> { fatalError("Not implemented") }
    
    static func index(attributes: [String: Any]) -> ModelsRequest<Self> { fatalError("Not implemented") }
    static func create(attributes: [String: Any]) -> ModelRequest<Self> { fatalError("Not implemented") }
}
