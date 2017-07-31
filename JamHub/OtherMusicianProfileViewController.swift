//
//  OtherMusicianProfileViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/8/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit

class OtherMusicianProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let cellReuseIdentifier = "ProfileTableViewCell"
    
    var properties = ["Genres: ", "Instruments: ", "Last Session: ", "Number of Sessions: "]
    
    var selectedMusician: Musician?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
        self.profileImageView.clipsToBounds = true
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        
        if let musician = selectedMusician {
            nameLabel.text = musician.name
            if let profileImageURL = musician.profileImageURL {
                profileImageView.loadImageUsingCacheWithURLString(urlString: profileImageURL)
            }
            
            properties[0] += musician.genres ?? ""
            properties[1] += musician.instruments ?? ""
            properties[2] += musician.lastSession ?? ""
            properties[3] += String(musician.numSessions ?? 0)
        }
    }

    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.properties.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell!
        print(properties)
        // set the text from the data model
        cell.textLabel?.text = self.properties[indexPath.row]
        
        return cell
    }
    
    

}
