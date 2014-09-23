//
//  Helpers.swift
//  SwiftHN
//

import UIKit
import SwiftHNShared
import SafariServices
import HackerSwifter

class Helper {
    
    class func addPostToReadingList(post: Post) -> Bool {
        var readingList = SSReadingList.defaultReadingList()
        var error: NSError?
        if let url: String = post.url?.absoluteString {
            readingList.addReadingListItemWithURL(NSURL(string: url), title: post.title, previewText: nil, error: &error)
            return error != nil
        }
        return false
    }
    
    class func showShareSheet(post: Post, controller: UIViewController, barbutton: UIBarButtonItem!) {
        var sheet = UIActivityViewController(activityItems: [NSString(string: post.title!), post.url!], applicationActivities: [OpenSafariActivity()])
        if sheet.popoverPresentationController != nil {
            sheet.modalPresentationStyle = UIModalPresentationStyle.Popover
            sheet.popoverPresentationController?.sourceView = controller.view
            if let barbutton = barbutton {
                sheet.popoverPresentationController?.barButtonItem = barbutton
            }
        }
        controller.presentViewController(sheet, animated: true, completion: nil)
    }
}