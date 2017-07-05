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

        let session = sessions[indexPath.row]
        
        cell.nameLabel?.text = session.name
        cell.genreLabel?.text = session.genre
        cell.hostLabel?.text = session.host
        
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
                
                let sessionRef = snapshot.ref
                let musiciansRef = sessionRef.child("musicians")
                
                newSession.musicians = self.getMusicians(musiciansRef: musiciansRef)
                
                if newSession.musicians == nil {
                    print("No musicians added")
                } else {
                    print(newSession.musicians!)
                }
                
                self.sessions.append(newSession)
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
            
        }, withCancel: nil)
    }
    
    func getMusicians(musiciansRef: DatabaseReference) -> [Musician] {
        var musicians = [Musician]()
        
        musiciansRef.observe(.childAdded, with: {(musicianSnapshot) in
            print("Trying to add a musician")
            if let musicianDictionary = musicianSnapshot.value as? [String: AnyObject] {
                let sessionMusician = Musician()
                
                sessionMusician.name = musicianDictionary["name"] as? String
                sessionMusician.genres = musicianDictionary["genres"] as? String
                sessionMusician.instruments = musicianDictionary["instruments"] as? String
                sessionMusician.profileImageURL = musicianDictionary["profileImageURL"] as? String
                
                print("Adding \(sessionMusician.name!)")
                
                musicians.append(sessionMusician)
                print(musicians.count)
            }
        }, withCancel: nil)
        print(musicians.count)
        
        return musicians
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "GoToCurrentSession" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! CurrentJamViewController
            
            if let selectedJamCell = sender as? JamTableViewCell
            {
                let indexPath = tableView.indexPath(for: selectedJamCell)!
                let selectedJam = sessions[indexPath.row]
                newViewController.currentSession = selectedJam
            }
        }
    }
    
    @IBAction func unwindToCurrentJams(sender: UIStoryboardSegue) {
    }

}
