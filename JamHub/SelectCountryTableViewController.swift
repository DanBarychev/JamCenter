//
//  SelectCountryTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//

import UIKit
import Firebase

class SelectCountryTableViewController: UITableViewController, UISearchBarDelegate {
    
    var countries = [String]()
    var countriesFiltered = [String]()
    var selectedCountry = String()
    var searchActive = false
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self

        nextButton.isEnabled = false
        countries = getCountryOptions()
        countriesFiltered = countries
    }
    
    // MARK: Search bar data source
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        /*countriesFiltered = countries.filter({ (country) -> Bool in
            let isMatch = country.lowercased().contains(searchText.lowercased())
            
            return isMatch
        })
        if(countriesFiltered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()*/
        if searchText.count == 0 {
            searchActive = false;
            self.tableView.reloadData()
        } else {
            countriesFiltered = countries.filter({ (text) -> Bool in
                let tmp: NSString = text as NSString
                let range = tmp.range(of: searchText, options: NSString.CompareOptions.caseInsensitive)
                return range.location != NSNotFound
            })
            if(countriesFiltered.count == 0){
                searchActive = false;
            } else {
                searchActive = true;
            }
            self.tableView.reloadData()
        }
    }

    // MARK: Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return countriesFiltered.count
        } else {
            return countries.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: "CountryCell") as UITableViewCell?)!
        
        if searchActive {
            cell.textLabel?.text = countriesFiltered[indexPath.row]
        } else {
            cell.textLabel?.text = countries[indexPath.row]
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchActive {
            selectedCountry = countriesFiltered[indexPath.row]
        } else {
            selectedCountry = countries[indexPath.row]
        }
        
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
