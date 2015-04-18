//
//  TogglOverlayself.swift
//  TogglOverlay
//
//  Created by Fravic Fernando on 4/13/15.
//  Copyright (c) 2015 Fravic Fernando. All rights reserved.
//

import Cocoa

class TogglOverlayWindow: NSWindow, NSURLConnectionDelegate {
    let shortTimerInterval:NSTimeInterval = 5
    let longTimerInterval:NSTimeInterval = 30
    let url = NSURL(string: "https://www.toggl.com/api/v8/time_entries/current?access_token=YOUR_ACCESS_TOKEN")

    var timer: NSTimer?
    
    override init(contentRect: NSRect, styleMask aStyle: Int, backing bufferingType: NSBackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)
        
        let selfLevel = CGShieldingWindowLevel()
        
        self.releasedWhenClosed = true
        self.level = Int(selfLevel)
        self.backgroundColor = NSColor(calibratedRed:1, green:0, blue:0, alpha:0.3)
        self.alphaValue = 1
        self.opaque = false
        self.ignoresMouseEvents = true

        self.queryToggl()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        let screen = NSScreen.mainScreen()
        
        var frame = screen!.frame;
        self.setFrame(frame, display:true, animate:false);
        
        self.makeKeyAndOrderFront(nil)
    }
    
    func queryToggl() {
        let request = NSMutableURLRequest(URL: url!)
        let authStr = String(format: "%@:%@", "YOUR_USER_NAME", "YOUR_PASSWORD")
        let authData = authStr.dataUsingEncoding(NSUTF8StringEncoding)
        let authVal = String(format: "Basic %@", authData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithLineFeed))
        request.addValue(authVal, forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let conn = NSURLConnection(request: request, delegate: self)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
            var error: NSError?
            var togglOff = true
            
            if (data != nil) {
                let json:AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options:NSJSONReadingOptions.MutableContainers, error:&error)

                if (json != nil) {
                    let jsonDict = json as! NSDictionary
                    NSLog("Received JSON %@", jsonDict)
                    
                    togglOff = jsonDict.objectForKey("data") is NSNull
                    self.animateAlpha(togglOff)
                }
            }
            
            let timerInterval:NSTimeInterval = togglOff ? self.shortTimerInterval : self.longTimerInterval
            if (self.timer?.valid != nil) {
                self.timer?.invalidate()
            }
            self.timer = NSTimer.scheduledTimerWithTimeInterval(
                timerInterval,
                target: self,
                selector: Selector("queryToggl"),
                userInfo: nil,
                repeats: false)
        })
    }
    
    func connection(connection: NSURLConnection, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge) {
        let trustedHosts = ["toggl.com"]
        
        if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust){
            if (contains(trustedHosts, challenge.protectionSpace.host)) {
                challenge.sender.useCredential(NSURLCredential(forTrust: challenge.protectionSpace.serverTrust), forAuthenticationChallenge: challenge)
            }
        }
        challenge.sender.continueWithoutCredentialForAuthenticationChallenge(challenge);
    }
    
    func animateAlpha(fadeIn:Bool) {
        if ((!fadeIn && self.alphaValue == 0) || (fadeIn && self.alphaValue == 1)) {
            return
        }
        
        let fadeAnim = NSViewAnimation(duration: 1, animationCurve: NSAnimationCurve.EaseInOut)
        fadeAnim.viewAnimations = [[
            NSViewAnimationTargetKey: self,
            NSViewAnimationEffectKey: (fadeIn ? NSViewAnimationFadeInEffect : NSViewAnimationFadeOutEffect)
        ]]
        fadeAnim.startAnimation()
    }
}
