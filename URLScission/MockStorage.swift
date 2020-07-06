//
//  MockStorage.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public class MockStorage {
    public private(set) var activeMocks: [Mock] = []

    public var activeMockIdentifiers: [String] = [] {
        didSet {
            activeMockIdentifiers = activeMockIdentifiers.filter({ mocks.keys.contains($0) }).uniqued
            activeMocks = activeMockIdentifiers.compactMap({ mocks[$0] })
        }
    }

    public private(set) var mocks: [String: Mock] = [:]

    public func register(_ mock: Mock) {
        Logger.log("Registered mock “%@”", log: .mock, type: .debug, mock.name)
        mocks[mock.id] = mock
    }
}

extension MockStorage {
    public func loadMockFiles(in directory: URL) {
        guard let directoryEnumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else {
            Logger.log("Could not enumerate mock files in directory %@", log: .mock, type: .error, directory as CVarArg)
            return
        }
        for case let mockFile as URL in directoryEnumerator {
            do {
                let mockParser = try MockParser(fileURL: mockFile)
                let mappings = mockParser.parse()
                if  case let .string(name)? = mappings["name"],
                    case let .string(id)? = mappings["id"] {
                    do {
                        let query: String?
                        if case let .string(string)? = mappings["query"] {
                            query = string
                        } else {
                            query = nil
                        }
                        let mutation: String?
                        if case let .string(string)? = mappings["mutation"] {
                            mutation = string
                        } else {
                            mutation = nil
                        }
                        let url: String?
                        if case let .string(string)? = mappings["url"] {
                            url = string.replacingOccurrences(of: "\\", with: "")
                        } else {
                            url = nil
                        }
                        let method: String?
                        if case let .string(string)? = mappings["method"] {
                            method = string
                        } else {
                            method = nil
                        }
                        let regex: NSRegularExpression?
                        if case let .string(pattern)? = mappings["regex"] {
                            regex = try NSRegularExpression(pattern: pattern, options: [])
                        } else {
                            regex = nil
                        }
                        let iconName: String?
                        if case let .string(string)? = mappings["iconName"] {
                            iconName = string
                        } else {
                            iconName = nil
                        }
                        let statusCode: Int?
                        if case let .string(string)? = mappings["status"] {
                            statusCode = Int(string)
                        } else {
                            statusCode = nil
                        }
                        let range: Range<Data.Index>?
                        if case let .data(dataRange)? = mappings["data"] {
                            range = dataRange
                        } else {
                            range = nil
                        }
                        let mock = DataMock(id: id, name: name, iconName: iconName, query: query, mutation: mutation, url: url, method: method, regex: regex, dataFile: mockFile, dataRange: range, statusCode: statusCode)
                        register(mock)
                    } catch {
                        Logger.log("Could not parse regular expression in mock file %@ : %@", log: .mock, type: .error, mockFile.absoluteString as CVarArg, error.localizedDescription as CVarArg)
                    }
                } else {
                    Logger.log("Could not parse mock file %@", log: .mock, type: .error, mockFile as CVarArg)
                }
            } catch {
                Logger.log("Could not open mock file %@", log: .mock, type: .error, mockFile as CVarArg)
            }
        }
    }
}
