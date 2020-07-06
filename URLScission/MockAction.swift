//
//  MockAction.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public enum MockAction {
    case none
    case returnData(Data)
    case returnObject(AnyEncodable)
    case returnError(Error)
}

@propertyWrapper
public class AnyEncodable: Encodable {

    private let _encode: (Encoder) throws -> Void

    public var wrappedValue: Any

    public init<T: Encodable>(_ wrapped: T) {
        wrappedValue = wrapped
        _encode = wrapped.encode
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

extension MockAction: Equatable {
    public static func == (lhs: MockAction, rhs: MockAction) -> Bool {
        switch (rhs, lhs) {
            case (.none, .none):
                return true
        default:
            return false
        }
    }
}

public extension MockAction {
    func execute() -> (Data?, Error?) {
        switch self {
        case MockAction.returnData(let data):
            return (data, nil)
        case MockAction.returnError(let error):
            return (nil, error)
        case MockAction.returnObject(let object):
            do {
                let data = try JSONEncoder().encode(object)
                return (data, nil)
            }
            catch {
                return (nil, MockSessionError.dataInvalid)
            }
        case .none:
            return (nil, MockSessionError.noAction)
        }
    }
}
