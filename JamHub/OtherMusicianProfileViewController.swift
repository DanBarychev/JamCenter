//
//  OtherMusicianProfileViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/8/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

class OtherMusicianProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var instrumentsLabel: UILabel!
    @IBOutlet weak var genresLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var numSessionsLabel: UILabel!
    
    var origin: String?
    var selectedMusician: Musician?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
        
        if let musician = selectedMusician {
            nameLabel.text = musician.name
            if let profileImageURL = musician.profileImageURL {
                profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
            }
            
            instrumentsLabel.text = musician.instruments
            genresLabel.text = musician.genres
            cityLabel.text = musician.city
            countryLabel.text = musician.country
            numSessionsLabel.text = String(musician.numSessions ?? 0)
        }
    }
    
    // MARK: Actions
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        guard let origin = origin else {
            return
        }
        
        if origin == "NewSession" {
            performSegue(withIdentifier: "UnwindToNewSessionFromOtherMusician", sender: nil)
        } else {
            performSegue(withIdentifier: "UnwindToCurrentJamFromOtherMusician", sender: nil)
        }
    }
    
}
