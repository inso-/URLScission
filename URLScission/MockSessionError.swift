//
//  MockSessionError.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

enum MockSessionError {
    case canceled
    case noQueryName
    case noMock
    case noGraphQLClient
    case noAction
    case noData
    case dataInvalid
    case notImplemented
    case networkError(String)
}

extension MockSessionError: Error {
    var localizedDescription: String {
        switch self {
        case .canceled:
            return "Canceled"
        case .noMock:
            return "No valid mock for this request"
        case .noData:
            return "No data on the mock"
        case .dataInvalid:
            return "No valid data on the mock"
        case .noAction:
            return "No action for the mock"
        case .noQueryName:
            return "Query have no name"
        case .notImplemented:
            return "Not implemented"
        case .networkError(let errorString):
            return errorString
        case .noGraphQLClient:
            return "No graphQL client"
        }
    }
}
