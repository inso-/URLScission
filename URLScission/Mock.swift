//
//  Mock.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public protocol Mock {
    var id: String { get }
    var name: String { get }
    var iconName: String? { get }
    var query: String? { get }
    var mutation: String? { get }
    var url: String? { get }
    var method: String? { get }
    var regex: NSRegularExpression? { get }
    func action(for query: String, matchedParameters: [String?]) -> MockAction
}
