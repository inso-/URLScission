//
//  MockClient.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public class MockClient {
    let mockStorage: MockStorage

    var deadline: Double = 0.0

    init(mockStorage: MockStorage, deadline: Double = 0.0) {
        self.mockStorage = mockStorage
        self.deadline = deadline
    }
}

extension MockClient: SessionClient {
    public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
        guard let mock = self.mockForRequest(request: request) else {
            return MockSessionTask(mock: .none, completionHandler: { _, _ in
                completionHandler(nil, nil, MockSessionError.noMock)
            })
        }

        guard let requestUrl = request.url?.absoluteString
            else {
                return MockSessionTask(mock: .none, completionHandler: { _, _ in
                    completionHandler(nil, nil, MockSessionError.noQueryName)
                })
        }
        // TODO - manage to get parameter on request and filter mock by matchingParameters
        let mockAction = mock.action(for: requestUrl,
                                     matchedParameters: [])
        if mockAction == MockAction.none {
            return MockSessionTask(mock: .none, completionHandler: { _, _ in
                completionHandler(nil, nil, MockSessionError.noAction)
            })
        }

        let subCompletionHandler: (Data?, Error?) -> Void = { data, error in
            completionHandler(data, nil, error)
        }

        let mockSessionTask = MockSession.shared.dataTask(with: mockAction,
                                                          queue: DispatchQueue.main,
                                                          completionHandler: subCompletionHandler)

        return mockSessionTask
    }
}

public extension MockClient {
    func isMocked(request: URLRequest) -> Bool {
        self.mockForRequest(request: request) != nil
    }
}

private extension MockClient {
    private func mockForRequest(request: URLRequest) -> Mock? {
        guard let requestName = request.url?.absoluteString else {
            return nil
        }

        for mock in self.mockStorage.activeMocks {
            if mock.url?.contains(requestName) ?? false {
                return mock
            }
        }
        return nil
    }
}
