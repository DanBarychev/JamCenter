//
//  SelectCityTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SelectCityTableViewController: UITableViewController {

    var cities = [String]()
    var countryCityDict = NSDictionary()
    var selectedCountry: String?
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isEnabled = false
        cities = getCityOptions()
    }

    // MARK: Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: "CityCell") as UITableViewCell?)!
        cell.textLabel?.text = cities[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCity = cities[indexPath.row]
        
        uploadSelection(selectedCity: selectedCity)
    }

    // MARK: Location Data Retrieval
    
    func getCityOptions() -> [String] {
        if let path = Bundle.main.path(forResource: "countriesToCities", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
                    
                    countryCityDict = jsonResult as! NSDictionary
                } catch {}
            } catch {}
        }
        
        let cities = countryCityDict[selectedCountry as Any] as! [String]
        
        return cities
    }
    
    // MARK: Upload Data
    
    func uploadSelection(selectedCity: String) {
        let ref = Database.database().reference()
        let uid = Auth.auth().currentUser?.uid
        let userRef = ref.child("users").child(uid!)
        
        guard let selectedCountry = selectedCountry else {
            return
        }
        
        let values = ["location": "\(selectedCity), \(selectedCountry)"]
        
        userRef.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print (error!)
                return
            }
            else {
                self.nextButton.isEnabled = true
            }
        })
    }
    
    // MARK: Navigation
    
    @IBAction func unwindToSelectCity(sender: UIStoryboardSegue) {
    }
}
