//
//  CurrentJamsViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 5/18/17.
//  Copyright © 2017 Daniel Barychev. All rights reserved.
//
//  Globe icon from https://icons8.com/icon/2963/Globe-Filled

import UIKit
import Firebase

class CurrentJamsViewController: UITableViewController {
    
    var sessions = [Session]()
    typealias MusicianArrayClosure = ([Musician]?) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        getData()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JamTableViewCell", for: indexPath) as! JamTableViewCell

        let session = sessions.reversed()[indexPath.row]
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre
        if let hostImageURL = session.hostImageURL {
            cell.hostImageView.loadImageUsingCacheWithURLString(urlString: hostImageURL)
        }
        cell.hostImageView.layer.cornerRadius = cell.hostImageView.frame.size.width / 2
        cell.hostImageView.clipsToBounds = true
        
        return cell
    }
    
    func getData() {
        Database.database().reference().child("all sessions").observe(.childAdded, with: {(snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let newSession = Session()
                
                newSession.name = dictionary["name"] as? String
                newSession.genre = dictionary["genre"] as? String
                newSession.location = dictionary["location"] as? String
                newSession.host = dictionary["host"] as? String
                newSession.hostImageURL = dictionary["hostImageURL"] as? String
                newSession.audioRecordingURL = dictionary["audioRecordingURL"] as? String
                newSession.code = dictionary["code"] as? String
                newSession.ID = dictionary["ID"] as? String
                newSession.hostUID = dictionary["hostUID"] as? String
                newSession.isActive = Bool((dictionary["isActive"] as? String) ?? "false")
                
                let sessionRef = snapshot.ref
                let musiciansRef = sessionRef.child("musicians")
                
                self.getMusicians(musiciansRef: musiciansRef) { (musicians) in
                    newSession.musicians = musicians
                }
                
                if newSession.isActive ?? false {
                  self.sessions.append(newSession)
                }
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
            
        }, withCancel: nil)
    }
    
    func getMusicians(musiciansRef: DatabaseReference, completionHandler: @escaping MusicianArrayClosure) {
        var musicians = [Musician]()
        
        musiciansRef.observe(.childAdded, with: {(musicianSnapshot) in
            if let musicianDictionary = musicianSnapshot.value as? [String: AnyObject] {
                let sessionMusician = Musician()
                
                sessionMusician.name = musicianDictionary["name"] as? String
                sessionMusician.genres = musicianDictionary["genres"] as? String
                sessionMusician.instruments = musicianDictionary["instruments"] as? String
                sessionMusician.profileImageURL = musicianDictionary["profileImageURL"] as? String
                sessionMusician.numSessions = Int((musicianDictionary["numSessions"] as? String) ?? "0")
                sessionMusician.lastSession = musicianDictionary["lastSession"] as? String
                
                musicians.append(sessionMusician)
                print(musicians.count)
            }
            if musicians.isEmpty {
                completionHandler(nil)
            } else {
                completionHandler(musicians)
            }
        })
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCurrentJam" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? JamTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = sessions.reversed()[indexPath.row]
                newViewController.currentSession = selectedJam
            }
        }
    }
    
    @IBAction func unwindToCurrentJams(sender: UIStoryboardSegue) {
    }

}
