//
//  ViewController.swift
//  FluxSample
//
//  Created by spsadmin on 9/13/15.
//  Copyright © 2015 Friendly App Studio. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var fetchButton: UIButton!
    
    func appStateStoreDidChange(_:NSNotification) {
        switch appStateStore.networkState {
        case .Loading:
            fetchButton.enabled = false
            activityIndicator.startAnimating()
        case .Ready:
            fetchButton.enabled = true
            activityIndicator.stopAnimating()
        }
    }
    
    func postsStoreDidChange(_:NSNotification) {
        print("new posts : \(postsStore.posts)")
        tableView.reloadData()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        appStateStore.addObserver(self, callback: "appStateStoreDidChange:")
        postsStore.addObserver(self, callback: "postsStoreDidChange:")
    }
    
    deinit {
        appStateStore.removeObserver(self)
        postsStore.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func fetchButtonAction(sender: AnyObject) {
        postsActionCreator.fetchPosts()
    }
}

extension ViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let posts = postsStore.posts {
            return posts.count
        } else {
            return 0
        }
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell",forIndexPath:indexPath) as UITableViewCell
        if let posts = postsStore.posts {
            cell.textLabel?.text = posts[indexPath.row].title
        } else {
            cell.textLabel?.text = "Nothing!"
        }
        return cell
    }
}