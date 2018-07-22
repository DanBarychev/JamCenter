//
//  SelectCountryTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SelectCountryTableViewController: UITableViewController {
    
    var countries = [String]()
    var selectedCountry = String()
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nextButton.isEnabled = false
        countries = getCountryOptions()
    }

    // MARK: Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: "CountryCell") as UITableViewCell?)!
        cell.textLabel?.text = countries[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCountry = countries[indexPath.row]
        
        uploadSelection()
    }
    
    // MARK: Location Data Retrieval
    
    func getCountryOptions() -> [String] {
        var countries = [String]()
        
        if let path = Bundle.main.path(forResource: "countriesToCities", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
                    
                    let countriesArray = (jsonResult as AnyObject).allKeys as! [String]
                    countries = countriesArray.sorted()
                } catch {}
            } catch {}
        }
        
        return countries
    }
    
    // MARK: Upload Data
    
    func uploadSelection() {
        if selectedCountry != "" {
            let ref = Database.database().reference()
            let uid = Auth.auth().currentUser?.uid
            let userRef = ref.child("users").child(uid!)
            let values = ["location": selectedCountry]
            
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
    }
    
    // MARK: Navigation
    
    @IBAction func unwindToSelectCountry(sender: UIStoryboardSegue) {
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoToCitySelector" {
            let nav = segue.destination as! UINavigationController
            let newViewController = nav.topViewController as! SelectCityTableViewController
            
            newViewController.selectedCountry = selectedCountry
        }
    }
}
