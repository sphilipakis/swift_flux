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
        register(MainDispatcher) {
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


struct Post {
    let title:String
    init(title:String){
        self.title = title
    }
}

class PostsStore : BaseStore {
    private(set) var posts : [Post]?
    
    override init() {
        super.init()
        register(MainDispatcher) {
            action in
            switch action.name {
            case "updatePosts":
                self.handleUpdatePostsAction(action)
            default:
                return
            }
        }
    }
    
    func handleUpdatePostsAction(action:Action) {
        if let thePosts = action.properties["posts"] as? [Post] {
            posts = thePosts
            emmitChange()
        }
    }
}

let postsStore = PostsStore()

struct PostsActionCreator {
    func fetchPosts(){
        MainDispatcher.dispatch(Action(name:"updateAppState", properties: ["state":AppStateStore.NetworkState.Loading.rawValue]))
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            //let post0 = Post(title: "post 0")
            var posts = [Post]()
            posts.append(Post(title: "post 1"))
            posts.append(Post(title: "post 2"))
            let props : [String:Any] = ["posts":posts]
            MainDispatcher.dispatch(Action(name:"updateAppState", properties: ["state":AppStateStore.NetworkState.Ready.rawValue]))
            MainDispatcher.dispatch(Action(name:"updatePosts", properties: props))
        }
    }
}

let postsActionCreator = PostsActionCreator()
