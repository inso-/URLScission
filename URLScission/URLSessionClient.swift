//
//  URLSessionClient.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public protocol SessionClient {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask
}

public protocol SessionDataTask {
    func suspend()

    func resume()

    func resumeAfter(deadline: DispatchTime)
}

extension SessionDataTask {
    public func resumeAfter(deadline: DispatchTime) {
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.resume()
        }
    }
}

extension URLSession: SessionClient {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        let res: URLSessionDataTask = self.dataTask(with: request, completionHandler: completionHandler)
        return res as SessionDataTask
    }
}

let swizzleDefaultSessionConfiguration: Bool = {
    if let defaultSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.default)),
        let URLScissionDefaultSessionConfiguration = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.URLScissionDefaultSessionConfiguration)) {
        method_exchangeImplementations(defaultSessionConfiguration, URLScissionDefaultSessionConfiguration)
        return true
    } else {
        return false
    }
}()

extension URLSession {
    @objc public class func URLScissionSwizzleDefault() {
        if swizzleDefaultSessionConfiguration == false {
            debugPrint("Fail to swizzle URLSessionConfiguration")
        }
    }
}

extension URLSessionConfiguration {
    @objc class func URLScissionDefaultSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLScissionDefaultSessionConfiguration()
        configuration.protocolClasses = [URLScissionProtocol.self] as [AnyClass] + configuration.protocolClasses!
        return configuration
    }
}

extension URLSessionTask: SessionDataTask {}

public class URLScissionProtocol: URLProtocol {
    private var _task: SessionDataTask?

    override public var task: URLSessionTask? {
        _task as? URLSessionTask
    }

    override public class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override open class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override open func startLoading() {
        _task = URLScissionDefault.shared.currentRouter?.dataTask(with: self.request) { data, urlResponse, error in
            if let urlResponse = urlResponse {
                self.client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            }
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
            self.client?.urlProtocolDidFinishLoading(self)
        }
        _task?.resume()
    }

    override open func stopLoading() {
        _task?.suspend()
    }
}
