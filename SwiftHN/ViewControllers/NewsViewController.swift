//
//  NewsViewController.swift
//  SwiftHN
//

import UIKit
import SwiftHNShared
import HackerSwifter

class NewsViewController: HNTableViewController, NewsCellDelegate, CategoriesViewControllerDelegate {
    
    var filter: Post.PostFilter = .Top
    var loadMoreEnabled = false
    var infiniteScrollingView:UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "HN:News"
        
        self.setupInfiniteScrollingView()
        self.setupNavigationItems()
    }
    
    private func setupInfiniteScrollingView() {
        self.infiniteScrollingView = UIView(frame: CGRectMake(0, self.tableView.contentSize.height, self.tableView.bounds.size.width, 60))
        self.infiniteScrollingView!.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        self.infiniteScrollingView!.backgroundColor = UIColor.LoadMoreLightGrayColor()
        var activityViewIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityViewIndicator.color = UIColor.darkGrayColor()
        activityViewIndicator.frame = CGRectMake(self.infiniteScrollingView!.frame.size.width/2-activityViewIndicator.frame.width/2, self.infiniteScrollingView!.frame.size.height/2-activityViewIndicator.frame.height/2, activityViewIndicator.frame.width, activityViewIndicator.frame.height)
        activityViewIndicator.startAnimating()
        self.infiniteScrollingView!.addSubview(activityViewIndicator)
    }
    
    func onPullToFresh() {
        
        self.refreshing = true
        
        Post.fetch(self.filter, completion: {(posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) in
            if let realDatasource = posts {
                self.datasource = realDatasource
                if (self.datasource.count % 30 == 0) {
                    self.loadMoreEnabled = true
                } else {
                    self.loadMoreEnabled = false
                }
            }
            if (!local) {
                self.refreshing = false
            }
        })
    }
    
    func loadMore() {
        let fetchPage = Int(ceil(Double(self.datasource.count)/30))+1
        Post.fetch(self.filter, page:fetchPage, completion: {(posts: [Post]!, error: Fetcher.ResponseError!, local: Bool) in
            if let realDatasource = posts {
                var tempDatasource:NSMutableArray = NSMutableArray(array: self.datasource, copyItems: false)
                let postsNotFromNewPageCount = ((fetchPage-1)*30)
                if (tempDatasource.count - postsNotFromNewPageCount > 0) {
                    tempDatasource.removeObjectsInRange(NSMakeRange(postsNotFromNewPageCount, tempDatasource.count-postsNotFromNewPageCount))
                }
                tempDatasource.addObjectsFromArray(realDatasource)
                self.datasource = tempDatasource
                if (self.datasource.count % 30 == 0) {
                    self.loadMoreEnabled = true
                } else {
                    self.loadMoreEnabled = false
                }
            }
            if (!local) {
                self.refreshing = false
                self.tableView.tableFooterView = nil
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.onPullToFresh()
        self.showFirstTimeEditingCellAlert()
    }
    
    func setupNavigationItems() {
        var rightButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Organize, target: self, action: "onRightButton")
        self.navigationItem.rightBarButtonItem = rightButton
    }
    
    func onRightButton() {
        var navCategories = self.storyboard?.instantiateViewControllerWithIdentifier("categoriesNavigationController") as UINavigationController
        var categoriesVC = navCategories.visibleViewController as CategoriesViewController
        categoriesVC.delegate = self
        var popController = UIPopoverController(contentViewController: navCategories)
        popController.presentPopoverFromBarButtonItem(self.navigationItem.rightBarButtonItem!,
            permittedArrowDirections: UIPopoverArrowDirection.Any,
            animated: true)
        
    }
    
    //MARK: Alert management
    func showFirstTimeEditingCellAlert() {
        if (!Preferences.sharedInstance.firstTimeLaunch) {
            var alert = UIAlertController(title: "Quick actions",
                message: "By swipping a cell you can quickly send post to the Safari reding list, or use the more button to share it and access other functionalities",
                preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: {(action: UIAlertAction?) in
                Preferences.sharedInstance.firstTimeLaunch = true
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func showActionSheetForPost(post: Post) {
        var titles = ["Share", "Open", "Open in Safari", "Cancel"]
        
        var sheet = UIAlertController(title: post.title, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var handler = {(action: UIAlertAction?) -> () in
            self.tableView.setEditing(false, animated: true)
            if let realAction = action {
                if (action!.title == titles[0]) {
                    Helper.showShareSheet(post, controller: self, barbutton: nil)
                }
                else if (action!.title == titles[1]) {
                    var webview = self.storyboard?.instantiateViewControllerWithIdentifier("WebviewController") as WebviewController
                    webview.post = post
                    self.showDetailViewController(webview, sender: nil)
                }
                else if (action!.title == titles[2]) {
                    UIApplication.sharedApplication().openURL(post.url!)
                }
            }
        }
        
        for title in titles {
            var type = UIAlertActionStyle.Default
            if (title == "Cancel") {
                type = UIAlertActionStyle.Cancel
            }
            sheet.addAction(UIAlertAction(title: title, style: type, handler: handler))
        }
        
        self.presentViewController(sheet, animated: true, completion: nil)
    }
    
    //MARK: TableView Management
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int  {
        return 1
    }
    
    override func tableView(tableView: UITableView,numberOfRowsInSection section: Int) -> Int {
        if (self.datasource != nil) {
            return self.datasource.count
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        var title: NSString = (self.datasource[indexPath.row] as Post).title!
        return NewsCell.heightForText(title, bounds: self.tableView.bounds)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(NewsCellsId) as? NewsCell
        cell!.post = self.datasource[indexPath.row] as Post
        cell!.cellDelegate = self
        if (loadMoreEnabled && indexPath.row == self.datasource.count-3) {
            self.tableView.tableFooterView = self.infiniteScrollingView
            loadMore()
        }
        return cell!
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!)  {
        if (segue.identifier == "toWebview") {
            var destination = segue.destinationViewController as WebviewController
            if let selectedRows = self.tableView.indexPathsForSelectedRows() {
                destination.post = self.datasource[selectedRows[0].row] as Post
            }
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]
    {
        var readingList = UITableViewRowAction(style: UITableViewRowActionStyle.Normal,
            title: "Read\nLater",
            handler: {(action: UITableViewRowAction!, indexpath: NSIndexPath!) -> Void in
                if (Helper.addPostToReadingList(self.datasource[indexPath.row] as Post)) {
                }
                var post = self.datasource
                Preferences.sharedInstance.addToReadLater(self.datasource[indexPath.row] as Post)
                var cell = self.tableView.cellForRowAtIndexPath(indexPath) as NewsCell
                cell.readLaterIndicator.hidden = false
                self.tableView.setEditing(false, animated: true)
        })
        readingList.backgroundColor = UIColor.ReadingListColor()
        
        var more = UITableViewRowAction(style: UITableViewRowActionStyle.Normal,
            title: "More",
            handler: {(action: UITableViewRowAction!, indexpath: NSIndexPath!) -> Void in
                self.showActionSheetForPost(self.datasource[indexPath.row] as Post)
        })
        
        return [readingList, more]
    }
    
    //MARK: NewsCellDelegate
    func newsCellDidSelectButton(cell: NewsCell, actionType: Int, post: Post) {
        
        var indexPath = self.tableView.indexPathForCell(cell)
        if let realIndexPath = indexPath {
            let delay = 0.2 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                self.tableView.selectRowAtIndexPath(realIndexPath, animated: false, scrollPosition: .None)
            }
        }
        if (actionType == NewsCellActionType.Comment.toRaw()) {
            var detailVC = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as DetailViewController
            detailVC.post = post
            self.showDetailViewController(detailVC, sender: self)
        }
        else if (actionType == NewsCellActionType.Username.toRaw()) {
            if let realUsername = post.username {
                var detailVC = self.storyboard?.instantiateViewControllerWithIdentifier("UserViewController") as UserViewController
                detailVC.user = realUsername
                self.showDetailViewController(detailVC, sender: self)
            }
        }
    }
    
    //MARK: CategoriesDelegate
    func categoriesViewControllerDidSelecteFilter(controller: CategoriesViewController, filer: Post.PostFilter, title: String) {
        self.filter = filer
        self.datasource = nil
        self.onPullToFresh()
        self.title = title
    }
    
    func delayedSelection(indexpath: NSIndexPath) {

    }
    
    
}
