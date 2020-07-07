//
//  Logger.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation
import os.log

public class Logger {
    static let serialQueue = DispatchQueue(label: "logQueue")

    public static func log(_ message: StaticString, log: OSLog = .default, type: OSLogType = .default, data: NSString? = nil, _ args: CVarArg...) {
        serialQueue.sync {
            os_log(message, dso: #dsohandle, log: log, type: type, args)
            if let data = data {
                os_log("[URLScission] Data:\n%@", dso: #dsohandle, log: log, type: type, data)
            }
        }
    }
}

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    private static var networkIdentifer = "network"
    private static var mockIdentier = "mock"

    /// Logs the network call.
    static let network: OSLog = OSLog(subsystem: subsystem, category: networkIdentifer)

    /// Logs the mock call.
    static var mock: OSLog = OSLog(subsystem: subsystem, category: mockIdentier)

}
