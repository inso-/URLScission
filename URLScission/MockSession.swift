//
//  MockSession.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation
import os.log

class URLScissionDefault {
    static let shared = URLScissionDefault()

    var currentRouter: URLScissionRouter?
}

class URLScissionRouter {
    private let mockClient: MockClient?

    let urlSessionRedirect: Bool

    init(mockStorage: MockStorage?, urlSessionRedirect: Bool = true) {
        if let mockStorage = mockStorage {
            self.mockClient = MockClient(mockStorage: mockStorage)
        } else {
            self.mockClient = nil
        }
        self.urlSessionRedirect = urlSessionRedirect
        URLScissionDefault.shared.currentRouter = self
        if self.urlSessionRedirect {
            URLSession.URLScissionSwizzleDefault()
        }
    }
}

extension URLScissionRouter: SessionClient {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        let isMocked = (self.mockClient?.isMocked(request: request) ?? false)
        let client: SessionClient = isMocked ? self.mockClient! : URLSession.shared

        self.logRequest(request: request)
        return client.dataTask(with: request, completionHandler: { data, urlResponse, error in
            self.logRequestResponse(request: request, data: data, urlResponse: urlResponse, error: error)
            guard isMocked else {
                completionHandler(data, urlResponse, error)
                return
            }

            let URLresponse: HTTPURLResponse!

            if error == nil {
                URLresponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "4.4.12", headerFields: nil)
            } else if let error = error, let mockError: MockSessionError = error as? MockSessionError {
                switch mockError {
                case .networkError(let statusCode):
                    URLresponse = HTTPURLResponse(url: request.url!, statusCode: Int(statusCode) ?? 1_337, httpVersion: "4.4.12", headerFields: nil)

                default:
                    URLresponse = HTTPURLResponse(url: request.url!, statusCode: 1_337, httpVersion: "4.4.12", headerFields: nil)
                }
            } else {
                 URLresponse = HTTPURLResponse(url: request.url!, statusCode: 1_337, httpVersion: "4.4.12", headerFields: nil)
            }
            completionHandler(data, URLresponse, error)
        })
    }
}

// LOG Extension
// Lot of repetition but Swift still not have splatting so call the loger is quite complicated :(
// Watch resolution of https://bugs.swift.org/browse/SR-128 to plan future improvement

extension URLScissionRouter {
    private func logRequest(request: URLRequest) {
        let isMocked = (self.mockClient?.isMocked(request: request) ?? false)
        let logger = isMocked ? OSLog.mock : OSLog.network

        Logger.log("[URLScission] Call 🚀 %@ : %@", log: logger, type: .debug, request.httpMethod ?? "unknow method", request.url?.absoluteString ?? "unkown" as String)
        if isMocked {
            Logger.log("[URLScission] On Mock 🌔 %@: %@ header: %@ parameter:%@", log: logger,
                       type: .debug,
                       (request.url?.absoluteString ?? "unknow") as CVarArg,
                       request.httpMethod ?? "unknow method" as CVarArg,
                       (request.allHTTPHeaderFields?.description ?? "Empty") as CVarArg,
                       (request.httpBody?.base64EncodedString() ?? "No body") as CVarArg)
        } else {
            Logger.log("[URLScission] On Server ☀️ %@: %@ header: %@  parameter: %@", log: logger,
                       type: .debug,
                       (request.url?.absoluteString ?? "unknow"),
                       request.httpMethod ?? "unknow method",
                       (request.allHTTPHeaderFields?.description ?? "Empty") as CVarArg,
                       (request.httpBody?.base64EncodedString() as CVarArg? ?? "No body"))
        }
    }

    private func logRequestResponse(request: URLRequest, data: Data?, urlResponse: URLResponse?, error: Error?) {
        let isMocked = (self.mockClient?.isMocked(request: request) ?? false)
        let logger = isMocked ? OSLog.mock : OSLog.network

        if let error = error, isMocked {
            Logger.log("[URLScission] Error On Mock ❌🌔 %@ :\n%@",
                       log: logger,
                       type: .debug,
                       (request.url?.absoluteString ?? "") as CVarArg,
                       error.localizedDescription as CVarArg)
        } else if let error = error {
            Logger.log("[URLScission] Error On Server ❌☀️ %@ :\n%@", log: logger,
                       type: .debug,
                       (request.url?.absoluteString ?? "") as CVarArg,
                       error.localizedDescription as CVarArg )
        }
        if let data = data, isMocked {
            let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])?.jsonPrintable) ?? String(decoding: data, as: UTF8.self) as NSString
            Logger.log("[URLScission] Success On Mock ✅🌔 %@:\n", log: logger,
                       type: .debug, data: json,
                       (request.url?.absoluteString ?? "") as CVarArg)
        } else if let data = data {
            let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])?.jsonPrintable) ?? String(decoding: data, as: UTF8.self) as NSString
            Logger.log("[URLScission] Success On Server ✅☀️ %@:\n", log: logger,
                       type: .debug, data: json,
                       (request.url?.absoluteString ?? "") as CVarArg)
        } else if isMocked {
            Logger.log("[URLScission] Success %@ On Mock ✅🌔 :\n%@", log: logger,
                       type: .debug,
                       (request.url?.absoluteString ?? "") as CVarArg,
                       "No Data" as CVarArg)
        } else {
            Logger.log("[URLScission] Success On Server ✅☀️ %@ :\n%@", log: logger,
                       type: .debug,
                       (request.url?.absoluteString ?? "") as CVarArg,
                       "No Data" as CVarArg)
        }
    }
}

@objc public final class MockSession: NSObject, SessionClient {
    @objc static let shared = MockSession()

    public func dataTask(with mock: MockAction,
                         queue: DispatchQueue = DispatchQueue.main,
                         completionHandler: @escaping (Data?, Error?) -> Void) -> SessionDataTask {
        MockSessionTask(mock: mock, queue: queue, completionHandler: completionHandler)
    }

    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        MockSessionTask(mock: .none, queue: DispatchQueue.main, completionHandler: { data, error in
            completionHandler(data, nil, error)
        })
    }

    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
         MockSessionTask(mock: .none, queue: DispatchQueue.main, completionHandler: { data, error in
            completionHandler(data, nil, error)
        })
    }
}

fileprivate extension Dictionary {
    var jsonStringRepresentation: String? {
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: self,
                                                            options: [.prettyPrinted]) else {
                                                                return nil
        }
        return String(data: theJSONData, encoding: .utf8)
    }

    var jsonPrintable: NSString? {
        if let json = self.jsonStringRepresentation {
            return NSString(string: json)
        }
        return nil
    }
}
