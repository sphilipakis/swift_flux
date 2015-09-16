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
        
        class MyStore : BaseStore {
            
        }
        
        let theStore = MyStore()

        theStore.registerOnDispatcher(MainDispatcher) {
            action in
            print("Action : \(action)")
        }
        
        let token = theStore.registrationToken
        
        XCTAssert(token != nil, "Store should be registered with a registration token")
        XCTAssert(MainDispatcher.stores.count == 1, "Dispatcher should have one store")
        XCTAssert((MainDispatcher.stores[token!] === theStore), "Store should be the same in dispatcher")

        MainDispatcher.unregister(theStore)
        XCTAssert(MainDispatcher.stores.count == 0, "Dispatcher should have zero store")
        XCTAssert(theStore.registrationToken == nil, "Store should not have any registration token anymore")
        XCTAssert(MainDispatcher.stores[token!] == nil, "Token should be un assigned in dispatcher")
    }
    
    func testDispatch() {
        class MyStore : BaseStore {
        }
        let expectation = expectationWithDescription("store should run handle")
        let action = Action(name:"test",properties:["theKey":"the value"])
        var testSore = MyStore()
        testSore.registerOnDispatcher(MainDispatcher) {
            action in
            if action.name != "test" {
                XCTFail("action name should be 'test'")
            } else {
                if "the value" == action.properties["theKey"] as? String {
                    expectation.fulfill()
                    return
                }
                XCTFail("action properties[theKey] should be the value")
            }
        }
        
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
    
    
    func testWaitFor() {
        class StoreA : BaseStore {
            var state : String? = nil
        }
        class StoreB : BaseStore {
        }
        
        let expectationB = expectationWithDescription("storeB should handle the action after A")
        let action = Action(name:"test",properties:["theKey":"the value"])
        let storeA = StoreA()
        let storeB = StoreB()
        storeA.registerOnDispatcher(MainDispatcher) {
            action in
            storeA.state = "Done"
        }
        storeB.registerOnDispatcher(MainDispatcher) {
            action in
            MainDispatcher.waitFor([storeA.registrationToken!])
            if storeA.state == "Done" {
                expectationB.fulfill()
            } else {
                XCTFail("storeA should have handled the action first")
            }
        }
        
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
