//
//  Flux.swift
//  Flux
//
//  Created by spsadmin on 9/13/15.
//  Copyright © 2015 Friendly App Studio. All rights reserved.
//


import Foundation

public struct Action {
    public let name : String
    public let properties : [String:Any]
    
    public init(name:String,properties:[String:Any]) {
        self.name = name
        self.properties = properties
    }
}

protocol Store : class {
    var registrationToken:String? {get set}
    
    func handleAction(action:Action)

    func addObserver(observer:AnyObject,callback:Selector)
    func removeObserver(observer:AnyObject)
    
    func emmitChange()
}

public class BaseStore:Store {

    static let StoreChangeNotificationName = "StoreChangeNotificationName"
    
    var registrationToken : String?
    
    var handler:((action:Action)->())?
    
    public init() {
        
    }
       
    public func register(dispatcher:Dispatcher, handler:((action:Action) -> ())) {
        self.handler = handler
        dispatcher.register(self);
    }
    
    func handleAction(action: Action) {
        if let theHandler = handler {
            theHandler(action: action)
        }
    }

    public func addObserver(observer: AnyObject, callback: Selector) {
        NSNotificationCenter.defaultCenter().addObserver(observer, selector: callback, name: BaseStore.StoreChangeNotificationName, object: self)
    }
    public func removeObserver(observer: AnyObject) {
        NSNotificationCenter.defaultCenter().removeObserver(observer, name: BaseStore.StoreChangeNotificationName, object: self)
    }
    
    public func emmitChange() {
        NSNotificationCenter.defaultCenter().postNotificationName(BaseStore.StoreChangeNotificationName, object:self, userInfo:nil)
    }
}

public class Dispatcher {

    var dispatchedAction: Action?
    var stores : [String:Store] = [String:Store]()
    var tokensOfStoresWhoAreHandlingTheAction : [String:Bool] = [String:Bool]()
    var tokensOfStoresWhoHandledTheAction : [String:Bool] = [String:Bool]()
    
    var tokensCounter = 0
    
    public init () {
        
    }
    
    
    private func newToken() -> String {
        tokensCounter++
        return "\(tokensCounter)"
    }
    
    func register(store:Store) -> String? {
        if let token = store.registrationToken {
            print("Trying to register \(store) while it already has a registration token \(token)")
            return nil
        } else {
            let token = newToken()
            stores[token] = store
            store.registrationToken = token
            return token
        }
    }
    
    func unregister(store:Store) {
        if let token = store.registrationToken {
            stores.removeValueForKey(token)
            store.registrationToken = nil;
        }
    }

    func willDispatch(action:Action) {
        dispatchedAction = action
        tokensOfStoresWhoAreHandlingTheAction = [String:Bool]()
        tokensOfStoresWhoHandledTheAction = [String:Bool]()
    }
    func didDispatch(action:Action) {
        dispatchedAction = nil
        tokensOfStoresWhoAreHandlingTheAction = [String:Bool]()
        tokensOfStoresWhoHandledTheAction = [String:Bool]()
    }
    
    func dispatch(action:Action, store:Store) {
        if let token = store.registrationToken {
            tokensOfStoresWhoAreHandlingTheAction[token] = true
            store.handleAction(action)
            tokensOfStoresWhoAreHandlingTheAction.removeValueForKey(token)
            tokensOfStoresWhoHandledTheAction[token] = true
        }
    }
    
    public func dispatch(action:Action) {
        assert(dispatchedAction == nil)
        assert(NSThread.currentThread().isMainThread)
        willDispatch(action)
        for (token,store) in stores {
            if let _ = tokensOfStoresWhoHandledTheAction[token] {
                print("store \(token) already handled this action")
            } else {
                dispatch(action, store: store)
            }
        }
        didDispatch(action)
    }
    
    func waitFor(tokens:[String]) {
        if let action = dispatchedAction {
            for token in tokens {
                if let store = stores[token] {
                    if let _ = tokensOfStoresWhoHandledTheAction[token] {
                        print("Store \(token) already handled this action")
                    } else {
                        if let _ = tokensOfStoresWhoAreHandlingTheAction[token] {
                            print("Store \(token) is currently handling this action... this is a cycle!")
                            assertionFailure("dispatch Cycle")
                        } else {
                            dispatch(action, store: store)
                        }
                    }
                }
            }
        }
    }
}


