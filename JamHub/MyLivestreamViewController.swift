//
//  MyLivestreamViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/11/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
// Play Icon from https://icons8.com/icon/36067/Circled-Play-Filled
// Stop Icon from https://icons8.com/icon/9984/Stop-Filled
// Code here is taken from Hans Knoechel's facebook-live-ios-sample

import UIKit

class MyLivestreamViewController: UIViewController {

    var blurOverlay: UIVisualEffectView!
    
    var sessionURL: NSURL!
    
    var loader: UIActivityIndicatorView!
    
    var loginButton: FBSDKLoginButton!
    
    var liveVideo: FBSDKLiveVideo!
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        if !self.liveVideo.isStreaming {
            startStreaming()
            recordButton.isSelected = true
        } else {
            stopStreaming()
            recordButton.isSelected = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.liveVideo = FBSDKLiveVideo(
            delegate: self,
            previewSize: self.view.bounds,
            videoSize: CGSize(width: 1280, height: 720)
        )
        
        let myOverlay = UIView(frame: CGRect(x: 5, y: 5, width: self.view.bounds.size.width - 10, height: 30))
        myOverlay.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 1.0, blue: 0.0, alpha: 0.5)
        
        self.liveVideo.privacy = .me
        self.liveVideo.audience = "me" // or your user-id, page-id, event-id, group-id, ...
        
        // Comment in to show a green overlay bar (configure with your own one)
        // self.liveVideo.overlay = myOverlay
        
        initializeUserInterface()
    }
    
    func initializeUserInterface() {
        self.loader = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        self.loader.frame = CGRect(x: 15, y: 15, width: 40, height: 40)
        
        self.blurOverlay = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        self.blurOverlay.frame = self.view.bounds
        
        self.view.insertSubview(self.liveVideo.preview, at: 0)
        
        self.loginButton = FBSDKLoginButton()
        self.loginButton.publishPermissions = ["publish_actions"]
        self.loginButton.loginBehavior = .native
        self.loginButton.center = CGPoint(x: self.view.bounds.size.width / 2, y: 120)
        self.loginButton.delegate = self
        self.view.addSubview(self.loginButton)
        
        self.recordButton.isHidden = true
        
        if FBSDKAccessToken.current() == nil {
            self.view.insertSubview(self.blurOverlay, at: 1)
        } else {
            print(FBSDKAccessToken.current().userID)
            self.recordButton.isHidden = false
        }
    }
    
    func startStreaming() {
        self.liveVideo.start()
        
        self.loader.startAnimating()
        self.recordButton.addSubview(self.loader)
        self.recordButton.isEnabled = false
    }
    
    func stopStreaming() {
        self.liveVideo.stop()
    }
}

extension MyLivestreamViewController : FBSDKLiveVideoDelegate {
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didStartWith session: FBSDKLiveVideoSession) {
        self.loader.stopAnimating()
        self.loader.removeFromSuperview()
        self.recordButton.isEnabled = true
        
        self.recordButton.imageView?.image = UIImage(named: "StopIcon")
    }
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didChange sessionState: FBSDKLiveVideoSessionState) {
        print("Session state changed to: \(sessionState)")
    }
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didStopWith session: FBSDKLiveVideoSession) {
        self.recordButton.imageView?.image = UIImage(named: "PlayIcon")
    }
    
    func liveVideo(_ liveVideo: FBSDKLiveVideo, didErrorWith error: Error) {
        self.recordButton.imageView?.image = UIImage(named: "PlayIcon")
    }
}

extension MyLivestreamViewController : FBSDKLoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        self.recordButton.isHidden = true
        self.view.insertSubview(self.blurOverlay, at: 1)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil {
            print("Error logging in: \(error.localizedDescription)")
            return
        }
        
        self.recordButton.isHidden = false
        self.blurOverlay.removeFromSuperview()
    }
}



