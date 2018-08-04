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
        let cell = tableView.dequeueReusableCell(withIdentifier: "MySongCell", for: indexPath) as! MySongTableViewCell
        
        let song = songs[indexPath.row]
        
        cell.songLabel?.text = song
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let songToDelete = songs[indexPath.row]
            
            removeSongFromSession(songToDelete: songToDelete)
            songs.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
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
    
    func addSongToSession(song: String) {
        let ref = Database.database().reference()
        let sessionSongsRef = ref.child("all sessions").child(sessionID).child("songs")
        let sessionSongKey = sessionSongsRef.childByAutoId()
        
        let values = ["song": song]
        
        sessionSongKey.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
            } else {
                print("\(song) successfully added to session")
            }
        }
    }
    
    func removeSongFromSession(songToDelete: String) {
        let ref = Database.database().reference()
        let sessionSongsRef = ref.child("all sessions").child(sessionID).child("songs")
        
        sessionSongsRef.observe(.childAdded, with: {(snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let song = dictionary["song"] as? String
                
                if let song = song {
                    if songToDelete == song {
                        let songKey = snapshot.key
                        
                        sessionSongsRef.child(songKey).removeValue()
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }, withCancel: nil)
    }
    
    // MARK: Actions
    
    @IBAction func addSong(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add Song", message: "Enter the title below", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Done", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                
                if let songTitle = field.text {
                  self.addSongToSession(song: songTitle)
                }
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Song Title"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
