//
//  MockParser.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public class MockParser {
    enum Value {
        case string(String)
        case data(Range<Data.Index>)
    }

    private let data: Data
    private var location: Data.Index
    private var mappings: [String: Value] = [:]

    private var literalKey: String?
    private var literalIndentation: Data?
    private var literalValueStart: Data.Index?
    private var literalValueEnd: Data.Index?

    init(fileURL: URL) throws {
        data = try Data(contentsOf: fileURL)
        location = data.startIndex
    }

    func parse() -> [String: Value] {
        location = data.startIndex
        mappings.removeAll()
        literalKey = nil
        literalValueStart = nil
        literalValueEnd = nil
        literalIndentation = nil

        while location < data.endIndex {
            let ranges = parseLine()
            if literalKey != nil {
                if literalValueStart == nil {
                    literalValueStart = ranges.indentationRange.endIndex
                }
                let indentation = data[ranges.indentationRange]
                if indentation.count > literalIndentation!.count, indentation.starts(with: literalIndentation!) {
                    literalValueEnd = ranges.lineRange.endIndex
                    if location < data.endIndex {
                        continue
                    }
                }
                if literalValueEnd == nil {
                    literalValueEnd = literalValueStart
                }
                let literalRange = literalValueStart!..<literalValueEnd!
                mappings[literalKey!] = .data(literalRange)
                literalKey = nil
                literalValueStart = nil
                literalValueEnd = nil
                literalIndentation = nil
                if location >= data.endIndex {
                    continue
                }
            }
            if let keyRange = ranges.keyRange, let key = String(data: data[keyRange], encoding: .utf8), let valueRange = ranges.valueRange, let value = String(data: data[valueRange], encoding: .utf8) {
                if value == "|" {
                    // This is a workaround to get the right range for the data. TODO: Figure out the real cause of the issue.
                    mappings[key] = .data(location..<data.endIndex)
                    print(mappings)
                    return mappings

                    //literalKey = key
                    //literalIndentation = data[ranges.indentationRange]
                } else {
                    mappings[key] = .string(value)
                }
            }
        }
        return mappings
    }
}

fileprivate extension UInt8 {
    var isCariageReturn: Bool { self == .carriageReturn }
    var isLineFeed: Bool { self == .lineFeed }
    var isSpace: Bool { self == .space }
    var isColon: Bool { self == .colon }
    var isBackslash: Bool { self == .backslash }
}

private extension MockParser {
    
    func parseLine() -> (lineRange: Range<Data.Index>, indentationRange: Range<Data.Index>, keyRange: Range<Data.Index>?, valueRange: Range<Data.Index>?) {
        var lineDelimiterStart: Data.Index?
        var lineDelimiterEnd: Data.Index?
        var indentationEnd: Data.Index?
        var mappingDelimiterStart: Data.Index?
        var mappingDelimiterEnd: Data.Index?

        for index in location..<data.endIndex {
            if indentationEnd == nil {
                if data[index] != .horizontalTab && data[index] != .space {
                    indentationEnd = index
                }
            }
            if mappingDelimiterStart != nil && mappingDelimiterEnd == nil {
                mappingDelimiterEnd = data[index].isSpace ? index : nil
            }
            if lineDelimiterStart != nil {
               mappingDelimiterEnd = data[index].isLineFeed ? index : mappingDelimiterStart
                break
            }
            if data[index].isLineFeed {
                lineDelimiterStart = index
                lineDelimiterEnd = index
                break
            }
            if data[index].isCariageReturn {
                lineDelimiterStart = index
            } else if data[index].isColon && !data[index - 1].isBackslash {
                mappingDelimiterStart = index
            }
        }
        if lineDelimiterStart == nil {
            lineDelimiterStart = data.endIndex
        }
        if lineDelimiterEnd == nil {
            lineDelimiterEnd = lineDelimiterStart
        }
        if indentationEnd == nil {
            indentationEnd = lineDelimiterStart
        }
        defer { location = min(lineDelimiterEnd! + 1, data.endIndex) }
        let lineRange = location..<lineDelimiterEnd!
        let indentationRange = location..<indentationEnd!
        let keyRange: Range<Data.Index>?
        let valueRange: Range<Data.Index>?
        if let mappingDelimiterStart = mappingDelimiterStart, let mappingDelimiterEnd = mappingDelimiterEnd {
            keyRange = indentationRange.endIndex..<mappingDelimiterStart
            valueRange = min(mappingDelimiterEnd + 1, lineRange.endIndex)..<lineRange.endIndex
        } else {
            keyRange = nil
            valueRange = nil
        }
        return (lineRange, indentationRange, keyRange, valueRange)
    }
}

private extension UInt8 {
    static let horizontalTab: UInt8 = 9
    static let lineFeed: UInt8 = 10
    static let carriageReturn: UInt8 = 13
    static let space: UInt8 = 32
    static let quote: UInt8 = 34
    static let colon: UInt8 = 58
    static let backslash: UInt8 = 92
}

public extension Sequence where Element: Equatable & Hashable {
    var uniqued: [Element] {
        var existing = Set<Element>()
        var uniqued = Array<Element>()
        for element in self where !existing.contains(element) {
            existing.insert(element)
            uniqued.append(element)
        }
        return uniqued
    }
}
