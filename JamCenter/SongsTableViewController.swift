//
//  SongsTableViewController.swift
//  JamCenter
//
//  Created by Daniel Barychev on 7/9/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SongsTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var mySession: Session?
    var songs = [Song]()
    var sessionID = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let session = mySession, let unwrappedSessionID = session.ID {
            sessionID = unwrappedSessionID
        }
        
        getData()
    }
    
    // MARK: Table View Data Source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as! SongTableViewCell
        
        let song = songs[indexPath.row]
        
        cell.songLabel?.text = song.title
        cell.artistComposerLabel?.text = song.artist
        
        return cell
    }
    
    // MARK: Firebase Functions
    
    func getData() {
        let ref = Database.database().reference()
        let sessionSongsRef = ref.child("all sessions").child(sessionID).child("songs")
        
        sessionSongsRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let currentSong = Song()
                
                let songTitle = dictionary["songTitle"] as? String
                let songArtist = dictionary["songArtist"] as? String
                
                currentSong.title = songTitle
                currentSong.artist = songArtist
                
                self.songs.append(currentSong)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }, withCancel: nil)
    }
}
