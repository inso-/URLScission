//
//  DataMock.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public class DataMock: Mock {
    public let id: String
    public let name: String
    public let iconName: String?
    public let regex: NSRegularExpression?
    public var query: String?
    public var mutation: String?
    public var url: String?
    public var method: String?
    private let dataFile: URL
    public let dataRange: Range<Data.Index>?
    private let statusCode: Int?

    public init(id: String, name: String, iconName: String? = nil, query: String?, mutation: String?, url: String?, method: String?, regex: NSRegularExpression?, dataFile: URL, dataRange: Range<Data.Index>?, statusCode: Int? = nil) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.query = query
        self.mutation = mutation
        self.regex = regex
        self.dataFile = dataFile
        self.dataRange = dataRange
        self.statusCode = statusCode
        self.url = url
        self.method = method
    }

    public func action(for query: String, matchedParameters: [String?]) -> MockAction {
        do {
            let fileData = try Data(contentsOf: dataFile)
            let data: Data
            if let range = dataRange {
                data = fileData[range]
            } else {
                data = Data()
            }
            if let statusCode = statusCode, !(200..<300).contains(statusCode) {
                return .returnError(MockSessionError.networkError("Network error: \(statusCode)"))
            }
            return .returnData(data)
        } catch {
            Logger.log("Could not open mock file %@: %@", log: .mock, type: .error, dataFile as CVarArg, error as CVarArg)
            return .none
        }
    }
}
