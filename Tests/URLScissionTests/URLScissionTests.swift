//
//  URLScissionTests.swift
//  URLScissionTests
//
//  Created by Thomas on 05/07/2020.
//  Copyright © 2020 Thomas.moussajee. All rights reserved.
//

import XCTest
@testable import URLScission

class URLScissionTests: XCTestCase {

    static let host = "https://github.com/inso-"
    static let sample = URL(string:"http://dummy.restapiexample.com/api/v1/employees")!

    struct Employees: Codable {
        var data : [Employee]
    }

    struct Employee: Codable {
        var id: String
        var employee_name: String
        var employee_age: String
    }

    lazy private var mockStorage = URLScission.mockStorage

    lazy private var networkConfiguration = RestNetworkConfiguration(host: Self.host, https: true)
    lazy private var networkClient: RestServiceNetwork = RestServiceNetwork(configuration: networkConfiguration)

    override func setUpWithError() throws {
        URLScission.start()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLog() throws {
        let testLog = expectation(description: "testLog")
        let completion: (Employees?, Error?) -> Void = { (result, error) in
            XCTAssert(result?.data.count == 24)
            testLog.fulfill()
        }
        networkClient.makeRequest(URLRequest(url: Self.sample), result: completion)
        waitForExpectations(timeout: 4.0, handler: nil)
    }

    func testMockFile() throws {
        let mockDirectory = Bundle(for: type(of: self))

        mockStorage.loadMockFiles(in: mockDirectory.bundleURL)
        mockStorage.activeMockIdentifiers = ["Test"]
        let testMockFile = expectation(description: "testMockFile")
        let completion: (Employees?, Error?) -> Void = { (result, error) in
            XCTAssert(result?.data.count == 1)
            testMockFile.fulfill()
        }
        networkClient.makeRequest(URLRequest(url: Self.sample), result: completion)
        waitForExpectations(timeout: 4.0, handler: nil)

    }

}
