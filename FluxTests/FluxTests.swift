//
//  FluxTests.swift
//  FluxTests
//
//  Created by spsadmin on 9/13/15.
//  Copyright © 2015 Friendly App Studio. All rights reserved.
//

import XCTest
@testable import Flux

var MainDispatcher:Dispatcher!

class TestStore : BaseStore {
    var expectation : XCTestExpectation!
    override init() {
        super.init()
        register(MainDispatcher) {
            action in
            print("Action : \(action)")
            self.expectation.fulfill()
        }
    }
}

class FluxTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        MainDispatcher = Dispatcher()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        MainDispatcher = nil
    }
    
    func testStoreRegister() {
        let testStore = TestStore()
        let token = testStore.registrationToken
        
        XCTAssert(token != nil, "Store should be registered with a registration token")
        XCTAssert(MainDispatcher.stores.count == 1, "Dispatcher should have one store")
        XCTAssert((MainDispatcher.stores[token!] === testStore), "Store should be the same in dispatcher")

        MainDispatcher.unregister(testStore)
        XCTAssert(MainDispatcher.stores.count == 0, "Dispatcher should have zero store")
        XCTAssert(testStore.registrationToken == nil, "Store should not have any registration token anymore")
        XCTAssert(MainDispatcher.stores[token!] == nil, "Token should be un assigned in dispatcher")
    }
    
    func testExample() {
        let expectation = expectationWithDescription("testStore should run handle")
        let action = Action(name:"test",properties:["aaa":"bbb"])
        var testSore = TestStore()
        testSore.expectation = expectation
        dispatch_async(dispatch_get_main_queue()) {
            MainDispatcher.dispatch(action)
        }
        waitForExpectationsWithTimeout(10) {
            error in
            if let error = error {
                print("Error \(error)")
            }
        }
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
