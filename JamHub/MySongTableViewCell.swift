//
//  SongTableViewCell.swift
//  JamHub
//
//  Created by Daniel Barychev on 8/5/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

class MySongTableViewCell: UITableViewCell {

    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistComposerLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    
    @IBAction func searchForSong(_ sender: UIButton) {
        let songTitleFormatted = songLabel.text?.replacingOccurrences(of: " ", with: "+")
        
        let artistComposerTitleFormatted = artistComposerLabel.text?.replacingOccurrences(of: " ", with: "+")
        
        if let songTitleFormatted = songTitleFormatted, let artistComposerTitleFormatted = artistComposerTitleFormatted {
            if let searchURL = URL(string: "http://www.google.com/search?q=\(songTitleFormatted)+\(artistComposerTitleFormatted)") {
                UIApplication.shared.open(searchURL, options: [:], completionHandler: nil)
            }
        }
    }
    
}
