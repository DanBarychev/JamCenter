//
//  SongsTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/9/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SongsTableViewController: UITableViewController {
    
    var mySession: Session?
    var songs = [String]()
    var sessionID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let session = mySession {
            sessionID = session.ID ?? ""
            
            if let sessionSongs = session.songs {
                songs = sessionSongs
            }
        }
        
        getData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        
        let song = songs[indexPath.row]
        
        cell.songLabel?.text = song
        
        return cell
    }
    
    // MARK: Firebase Operations
    
    func getData() {
        let ref = Database.database().reference()
        let sessionSongsRef = ref.child("all sessions").child(sessionID).child("songs")
        
        sessionSongsRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let song = dictionary["song"] as? String
                
                if let song = song {
                    self.songs.append(song)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }, withCancel: nil)
    }
}
