//
//  FASFlux.swift
//  Friendly
//
//  Created by spsadmin on 6/10/16.
//  Copyright © 2016 Friendly App Studio. All rights reserved.
//

import Foundation

public typealias FASFluxCallback = (Any) -> Void


enum FASFluxCallbackType {
    case Func(FASFluxCallback)
}

// CHANGED: new log delegate
enum FASLogLevel {
  case debug, warn, error
}

protocol FASFluxDispatcherLogDelegate: class {
  func dispatcherLog(_ dispatcher: FASFluxDispatcher, level: FASLogLevel, message: String, error: Error?)
}

public class FASFluxDispatcher {
    var lastID : Int = 0

    let dispatchQueue : DispatchQueue
    var callbacks : [String : FASFluxCallbackType] = [String : FASFluxCallbackType]()
    var isPending : [String : Bool] = [String : Bool]()
    var isHandled : [String : Bool] = [String : Bool]()

    var pendingAction : Any?
    var isDispatching : Bool = false
  
    weak var logDelegate: FASFluxDispatcherLogDelegate?
    
    init() {
        dispatchQueue = DispatchQueue.main
    }
    
    func nextRegistrationToken() -> String {
        lastID = lastID + 1
        let token = "token_\(lastID)"
        return token
    }
    
    private func register(callback : FASFluxCallbackType) -> String {
        let token = nextRegistrationToken()
        callbacks[token] = callback
        return token
    }

    fileprivate func register(fn : @escaping FASFluxCallback, storeName: String?) -> String {
        let token = register(callback: .Func(fn))
        log(level: .debug, message: "registration token '\(token)' assigned to store '\(storeName ?? "unnamed store")' (see store.name property)")
        return token
    }
    
    fileprivate func unregister(token : String) {
        if let _ = callbacks[token] {
            callbacks.removeValue(forKey: token)
            isPending.removeValue(forKey: token)
            isHandled.removeValue(forKey: token)
        }
    }
    
    func waitFor(stores:[FASFluxStore]) {
        guard isDispatching else { return }
        
        for store in stores {
          var storeIdentifier = store.name ?? "unnamed store"
          if let token = store.dispatchToken {
              storeIdentifier = store.name ?? "unnamed store (\(token))"
              let pending = isPending[token] ?? false
              let handled = isHandled[token] ?? false
              if pending {
                  if handled {
                      log(level: .debug, message: "Dispatcher waitFor : the callback for '\(storeIdentifier)' has handled the action already")
                      continue
                  } else {
                      log(level: .warn, message: "⚠️ Dispatcher waitFor : circular dependency detected while waiting for  '\(storeIdentifier)'")
                      continue
                  }
              }
          
              if let _ = callbacks[token] {
                  invokeCallback(token: token)
              } else {
                  log(level: .warn, message: "⚠️ Dispatcher waitFor '\(storeIdentifier)' does not map to a registered Callback")
              }
          } else {
            log(level: .warn, message: "⚠️ Can't wait for store '\(storeIdentifier)' because it's not registered")
          }
        }
    }
    
    func invokeCallback(token : String) {
        if let callback = callbacks[token] {
            isPending[token] = true
            switch callback {
            case .Func(let c) :
                if let pendingAction = pendingAction {
                    c(pendingAction)
                }
            }
            isHandled[token] = true
        } else {
            log(level: .warn, message: "⚠️ Can't invoke token (\(token)) as it was unregistered")
        }
    }
    
    func startDispatching(action : Any) {
        isPending.removeAll()
        isHandled.removeAll()
        pendingAction = action
        isDispatching = true
    }
    
    func stopDispatching() {
        pendingAction = nil
        isDispatching = false
    }
    
    func doDispatch(action:Any) {
        guard !isDispatching else {
            log(level: .error, message: "🛑 Dispatch.dispatchAction cannot dispatch in the middle of a dispatch!")
            return
        }
        autoreleasepool {
            startDispatching(action: action)
            for (token, _) in callbacks {
                if !(isPending[token] ?? false) {
                    invokeCallback(token: token)
                }
            }
            stopDispatching()
        }
    }
    
    func dispatchAction(action : Any) {
        if Thread.isMainThread {
            doDispatch(action: action)
        } else {
            dispatchQueue.sync() {
                [weak self] in
                self?.doDispatch(action: action)
            }
        }
    }
  
    private func log(level: FASLogLevel, message: String, error: Error? = nil) {
      if logDelegate != nil {
        logDelegate!.dispatcherLog(self, level: level, message: message, error: error)
      } else {
        NSLog("%@", message)
      }
    }
}

private let mainDispatcher = FASFluxDispatcher()

extension FASFluxDispatcher {
  public static var main: FASFluxDispatcher {
    return mainDispatcher
  }
}

public protocol FASStoreObserving: class {
    func observeChange(store:FASFluxStore,userInfo:[AnyHashable:Any]?)
}

fileprivate class FASObserverProxy {
  weak var observer: FASStoreObserving?
  init(observer: FASStoreObserving) {
    self.observer = observer
  }
  
  func forwardChange(store: FASFluxStore, userInfo: [AnyHashable : Any]?) -> Bool {
    if let o = observer {
      o.observeChange(store: store, userInfo: userInfo)
      return true
    }
    return false
  }
}

open class FASFluxStore {
    // CHANGED: don't expose the token
    fileprivate var dispatchToken : String?
    private var observerProxies : [FASObserverProxy] = []
  
    var name: String?
  
    public func registerWithDispatcher(_ dispatcher: FASFluxDispatcher, callback: @escaping FASFluxCallback) {
      dispatchToken = dispatcher.register(fn: callback, storeName: name)
    }
  
    func unregisterFromDispatcher(_ dispatcher: FASFluxDispatcher, callback: @escaping FASFluxCallback) {
      if let dt = dispatchToken {
        dispatcher.unregister(token: dt)
      }
      dispatchToken = nil
    }

    public init() {
        
    }

    /*func waitFor(tokens:[String]) {
        FASDefaultDispatcher.waitFor(tokens: tokens)
    }*/
    
    public func add(observer:FASStoreObserving) {
      let weakObserver = FASObserverProxy(observer: observer)
      observerProxies.append(weakObserver)
    }
    public func remove(observer:FASStoreObserving) {
        if let index = observerProxies.index(where: { po in return po.observer === observer }) {
            observerProxies.remove(at: index)
        }
    }
    
    public func emitChange(userInfo: [AnyHashable:Any]?) {
        guard Thread.isMainThread else {
            NSLog("%@", "FATAL : Emit Change on \(self) has to be done from main Thread!!!!!")
            abort()
        }
      
      // CHANGED: calls event handlers + trims deallocated observers from observers list
      observerProxies = observerProxies.filter { $0.forwardChange(store: self, userInfo: userInfo) }
      
    }

    public func emitChange() {
        emitChange(userInfo: nil)
    }
    public func emitChange(asResultOfActionType actionType:String) {
        emitChange(userInfo: ["afterAction":actionType])
    }

}

public protocol FASActionCreator {
}

public extension FASActionCreator {
  static var dispatcher: FASFluxDispatcher {
    return FASFluxDispatcher.main
  }
  static func dispatchAsync(action:Any, completion: (()->Void)? = nil) {
        DispatchQueue.main.async {
          self.dispatcher.dispatchAction(action: action)
          if completion != nil {
            completion!()
          }
        }
    }
  static func dispatch(action:Any) {
      // CHANGED: removed the syncIfOnMainThread, because it's confusing for the client (client needs to know if this will execute synchronously)
      if Thread.isMainThread {
        self.dispatcher.dispatchAction(action: action)
      } else {
        DispatchQueue.main.sync {
          self.dispatcher.dispatchAction(action: action)
        }
      }
    }
}
