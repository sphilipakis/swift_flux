//
//  Stores.swift
//  Flux
//
//  Created by spsadmin on 9/15/15.
//  Copyright © 2015 Friendly App Studio. All rights reserved.
//

import Foundation
import Flux


let MainDispatcher = Dispatcher()

class AppStateStore : BaseStore {
    enum NetworkState : String {
        case Ready = "ready"
        case Loading = "loading"
    }
    var networkState : NetworkState = .Ready
    override init() {
        super.init()
        registerOnDispatcher(MainDispatcher) {
            action in
            switch action.name {
                case "updateAppState":
                    self.handleUpdateAppStateAction(action)
            default:
                return
            }
        }
    }
    func handleUpdateAppStateAction(action:Action) {
        if let stateValue = action.properties["state"] as? String {
            if let state = NetworkState(rawValue: stateValue) {
                self.networkState = state
                emmitChange()
            }
        }
    }
}

let appStateStore = AppStateStore()

struct Rate {
    let ticker : String
    let symbol : String
    let last : Float
    init(ticker:String,symbol:String, last:Float){
        self.ticker = ticker
        self.symbol = symbol
        self.last = last
    }
}

class RatesStore : BaseStore {
    private(set) var rates : [Rate]?
    override init() {
        super.init()
        registerOnDispatcher(MainDispatcher) {
            action in
            switch action.name {
            case "updateRates":
                self.handleUpdateRatesAction(action)
            default:
                return
            }
        }
    }
    
    func handleUpdateRatesAction(action:Action) {
        if let theRates = action.properties["rates"] as? [Rate] {
            rates = theRates
            emmitChange()
        }
    }
}
let ratesStore = RatesStore()

struct RatesActionCreator {
    
    func dispatchOnMainThread(action:Action) {
        dispatch_async(dispatch_get_main_queue()) {
            MainDispatcher.dispatch(action)
        }
    }
    
    func fetchRates(){
        dispatchOnMainThread(Action(name:"updateAppState", properties: ["state":AppStateStore.NetworkState.Loading.rawValue]))
        
        let urlPath: String = "https://blockchain.info/ticker"
        let url: NSURL = NSURL(string: urlPath)!
        let request1: NSURLRequest = NSURLRequest(URL: url)

        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let dataTask = session.dataTaskWithRequest(request1) {
            (data:NSData?, response:NSURLResponse?, error:NSError?) in
            self.dispatchOnMainThread(Action(name:"updateAppState", properties: ["state":AppStateStore.NetworkState.Ready.rawValue]))
            
            if let err = error {
                print("error: \(err)")
            } else if let thedata = data {
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(thedata, options: NSJSONReadingOptions.AllowFragments)
                    guard let jsonArray = jsonResult as? [String:[String:AnyObject]] else {
                        print("not an array \(jsonResult)")
                        return
                    }
                    var rates = [Rate]()
                    for (ticker,tickerData) in jsonArray {
                        if let last = tickerData["last"] as? Float, symbol = tickerData["symbol"] as? String {
                            let rate = Rate(ticker: ticker,symbol:symbol, last: last)
                            rates.append(rate)
                        }
                    }
                    self.dispatchOnMainThread(Action(name:"updateRates", properties: ["rates":rates]))
                } catch let err as NSError {
                    print("Parsing error \(err)")
                }
            }
        }
        dataTask.resume()
    }
}

let ratesActionCreator = RatesActionCreator()
