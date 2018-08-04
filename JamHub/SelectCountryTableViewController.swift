//
//  SelectCountryTableViewController.swift
//  JamHub
//
//  Created by Daniel Barychev on 7/4/18.
//  Copyright © 2018 Daniel Barychev. All rights reserved.
//
//  getCountryOptions() adapted from https://github.com/salvonos/CityPicker/blob/master/Pod/Classes/CityPickerClass.swift

import UIKit
import Firebase

class SelectCountryTableViewController: UITableViewController, UISearchBarDelegate {
    
    var countries = [String]()
    var countriesFiltered = [String]()
    var selectedCountry = String()
    var searchActive = false
    var loginType: String?
    
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchBar.returnKeyType = UIReturnKeyType.done

        nextButton.isEnabled = false
        countries = getCountryOptions()
        
        if loginType == "Facebook" {
            backButton.isEnabled = false
        } else {
            backButton.isEnabled = true
        }
    }
    
    // MARK: Search bar data source
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        countriesFiltered = countries.filter({ (country) -> Bool in
            let isMatch = country.lowercased().contains(searchText.lowercased())
            
            return isMatch
        })
        
        if(countriesFiltered.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
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
        let cell = (self.tableView.dequeueReusableCell(withIdentifier: "CountryCell") as UITableViewCell?)!
        
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
        
        self.nextButton.isEnabled = true
    }
    
    // MARK: Location Data Retrieval
    
    func getCountryOptions() -> [String] {
        var allCountries = [String]()
        
        if let path = Bundle.main.path(forResource: "countriesToCities", ofType: "json") {
            do {
                let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                do {
                    let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves)
                    
                    let countriesArray = (jsonResult as AnyObject).allKeys as! [String]
                    allCountries = countriesArray.sorted()
                    // Filter out any duplicates
                    allCountries = Array(Set(allCountries))
                } catch {}
            } catch {}
        }
        
        return allCountries
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
