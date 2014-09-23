//
//  HNTableViewController.swift
//  SwiftHN
//

import UIKit

public class HNTableViewController: UITableViewController {

    public var refreshing: Bool = false {
    didSet {
        if (self.refreshing) {
            self.refreshControl?.beginRefreshing()
            self.refreshControl?.attributedTitle = NSAttributedString(string: "Loading...")
        }
        else {
            self.refreshControl?.endRefreshing()
            self.refreshControl?.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        }
    }
    }
    
    public var datasource: NSArray! {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "onPullToFresh", forControlEvents: UIControlEvents.ValueChanged)
    }
}
