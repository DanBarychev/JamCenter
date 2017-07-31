//
//  VideosViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/9/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {
    
    // MARK: Properties
    var currentSession: Session?
    
    @IBOutlet weak var noLivestreamLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let session = currentSession {
            
        }

        loadLiveStream()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadLiveStream() {
        
    }
}
