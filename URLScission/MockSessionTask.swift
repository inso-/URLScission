//
//  MockSessionTask.swift
//  URLScission
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import Foundation

public final class MockSessionTask: SessionDataTask {
    public var delegateQueue = OperationQueue()

    var mock: MockAction
    var queue: DispatchQueue
    var completion: (Data?, Error?) -> Void
    var isCanceled: Bool = false
    var isPaused: Bool = false

    public init(mock: MockAction,
                queue: DispatchQueue = DispatchQueue.main,
                completionHandler: @escaping (Data?, Error?) -> Void) {
        self.mock = mock
        self.queue = queue
        self.delegateQueue.underlyingQueue = queue
        self.completion = completionHandler
    }

    public func cancel() {
        self.isCanceled = true
    }

    public func suspend() {
        isPaused = true
    }

    public func resumeAfter(deadline: DispatchTime) {
        self.queue.asyncAfter(deadline: deadline) {
            self.resume()
        }
    }

    public func resume() {
        self.isPaused = false
        if self.isCanceled == true {
            completion(nil, MockSessionError.canceled)
            return
        }
        let result: (data: Data?, error: Error?) = self.mock.execute()
        while self.isPaused == true { }
        completion(result.data, result.error)
    }
}
