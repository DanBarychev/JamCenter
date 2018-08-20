//
//  MySongsTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 8/5/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class MySongsTableViewController: UITableViewController {
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MySongCell", for: indexPath) as! MySongTableViewCell
        
        let song = songs[indexPath.row]
        
        cell.songLabel?.text = song.title
        cell.artistComposerLabel?.text = song.artist
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let songToDelete = songs[indexPath.row]
            
            removeSongFromSession(songToDelete: songToDelete)
            songs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
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
    
    func addSongToSession(songTitle: String, songArtist: String) {
        let ref = Database.database().reference()
        let sessionSongsRef = ref.child("all sessions").child(sessionID).child("songs")
        let sessionSongKey = sessionSongsRef.childByAutoId()
        
        let values = ["songTitle": songTitle, "songArtist": songArtist]
        
        sessionSongKey.updateChildValues(values) { (error, ref) in
            if let error = error {
                print(error)
            } else {
                // Song added to session
            }
        }
    }
    
    func removeSongFromSession(songToDelete: Song) {
        let ref = Database.database().reference()
        let sessionSongsRef = ref.child("all sessions").child(sessionID).child("songs")
        
        sessionSongsRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let songTitle = dictionary["songTitle"] as? String
                
                if songToDelete.title == songTitle {
                    sessionSongsRef.child(snapshot.key).removeValue()
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }, withCancel: nil)
    }
    
    // MARK: Actions
    
    @IBAction func addSong(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add Song", message: "Enter the information below", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Done", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                
                if let songTitle = field.text, let field2 = alertController.textFields?[1],
                    let songArtist = field2.text {
                    
                    self.addSongToSession(songTitle: songTitle, songArtist: songArtist)
                }
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Song Title"
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Artist/Composer"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
