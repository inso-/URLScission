//
//  RestServiceNetwork.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

final class RestNetworkConfiguration {
    let https: Bool
    let host: String
    let authorization: String?
    let redirectionForwardAuthorization: Bool

    init(host: String,
         authorization: String? = nil,
         https: Bool = true,
         redirectionForwardAuthorization: Bool = false) {
        self.host = host
        self.authorization = authorization
        self.https = https
        self.redirectionForwardAuthorization = redirectionForwardAuthorization
    }
}

class RestServiceNetwork {
    class RestServiceNetworkDelegate: NSObject, URLSessionTaskDelegate {
        let configuration: RestNetworkConfiguration

        init(configuration: RestNetworkConfiguration) {
            self.configuration = configuration
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            if let authorization = configuration.authorization,
                configuration.redirectionForwardAuthorization {
                var request = request
                request.addValue(authorization, forHTTPHeaderField: HeaderKey.Authorization.rawValue)
                completionHandler(request)
            } else {
                completionHandler(request)
            }
        }
    }

    enum APIError: Error {
        case noURL
        case invalidResponse
        case invalidStatusCode
        case noData
        case decodingError(Error)
        case encodingError(Error)
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    enum URLPrefix: String {
        case http
        case https
    }

    enum HeaderKey: String {
        case Authorization
    }

    let configuration: RestNetworkConfiguration
    let client: URLSession
    var delegate: URLSessionDelegate?

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()

    init(configuration: RestNetworkConfiguration) {
        self.configuration = configuration

        if configuration.redirectionForwardAuthorization {
            self.delegate = RestServiceNetworkDelegate(configuration: configuration)
        }

        if let authorization = configuration.authorization {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = [HeaderKey.Authorization.rawValue: authorization]
            self.client = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        } else {
            self.client = URLSession(configuration: URLSessionConfiguration.default, delegate: delegate, delegateQueue: nil)
        }
    }
}

internal extension RestServiceNetwork {
    func constructURL(path: String) -> URL? {
        var components = URLComponents()
        if configuration.https {
            components.scheme = URLPrefix.https.rawValue
        } else {
            components.scheme = URLPrefix.http.rawValue
        }
        components.host = self.configuration.host
        components.path = path
        return components.url
    }

    func makeRequest<T: Decodable>(_ request: URLRequest,
                                   validateStatusCode: Bool = true,
                                   result: @escaping (T?, Error?) -> Void) {

        self.client.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                let error = APIError.invalidResponse
                result(nil, error)
                return
            }
            if validateStatusCode {
                guard 200...299 ~= httpResponse.statusCode else {
                    result(nil, APIError.invalidStatusCode)
                    return
                }
            }
            guard let data = data else {
                result(nil, APIError.noData)
                return
            }

            do {
                let model = try self.decoder.decode(T.self, from: data)
                result(model, nil)

            } catch let decodingError {
                let error = APIError.decodingError(decodingError)
                result(nil, error)
            }
        }.resume()
    }

    private func printJson(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            print(json)
        } catch {
            print(error)
        }
    }
}
