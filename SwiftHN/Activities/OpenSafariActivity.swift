//
//  OpenSafariActivity.swift
//  SwiftHN
//

import UIKit

class OpenSafariActivity: UIActivity {
    override func activityType() -> String {
        return "Open in Safari"
    }
    
    override func activityTitle() -> String  {
        return "Open in Safari"
    }
    
    override func activityImage() -> UIImage {
        return UIImage(named: "Safari")
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        var urlToOpen = activityItems[1] as NSURL
        UIApplication.sharedApplication().openURL(urlToOpen)
    }
}
