//
//  SearchController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 16.06.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher

class SearchController: UITableViewController {
   
   // MARK: - Properties
   var riders = [UserItem]()
   var filteredRiders = [UserItem]()
   var spots = [SpotItem]()
   var filteredSpots = [SpotItem]()
   
   let searchController = UISearchController(searchResultsController: nil)
   var selectedScope = "Riders" // default value is "Riders"
   
   // MARK: - View Setup
   override func viewDidLoad() {
      super.viewDidLoad()
      
      // Setup the Search Controller
      searchController.searchResultsUpdater = self
      searchController.searchBar.delegate = self
      definesPresentationContext = true
      searchController.dimsBackgroundDuringPresentation = false
      
      // Setup the Scope Bar
      searchController.searchBar.scopeButtonTitles = ["Riders", "Spots"]
      tableView.tableHeaderView = searchController.searchBar
   }
   
   // MARK: - Table View
   override func numberOfSections(in tableView: UITableView) -> Int {
      return 1
   }
   
   override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      switch selectedScope {
      case "Riders":
         return riders.count
         
      case "Spots":
         return spots.count
         
      default: return 0
      }
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsCell", for: indexPath) as! SearchResultsCell
      
      let row = indexPath.row
      
      switch selectedScope {
      case "Riders":
         let rider = riders[row]
         
         if rider.photo90ref != nil {
            let riderProfilePhotoURL = URL(string: rider.photo90ref!)
            
            cell.photo.kf.setImage(with: riderProfilePhotoURL)
         }
         
         cell.name!.setTitle(rider.login, for: .normal)
         
      case "Spots":
         let spot = spots[row]
         
         if spot.mainPhotoRef != nil {
            let spotPhotoURL = URL(string: spot.mainPhotoRef)
         
            cell.photo.kf.setImage(with: spotPhotoURL)
         }
         cell.name!.setTitle(spot.name, for: .normal)
         
      default: break
      }
      
      return cell
   }
   
   func filterContentForSearchText(_ searchText: String) {
      switch self.selectedScope {
      case "Riders":
         UserModel.searchUsersWithLogin(startedWith: searchText) { users in
            self.riders = users
            
            self.tableView.reloadData()
         }
         
      case "Spots":
         Spot.searchSpotsWithName(startedWith: searchText) { spots in
            self.spots = spots
            
            self.tableView.reloadData()
         }
         
      default: break
      }
   }
}

extension SearchController: UISearchBarDelegate {
   // MARK: - UISearchBar Delegate
   func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
      if searchController.isActive && searchController.searchBar.text != "" {
         searchBar.text = ""
         
         clearTableData()
         
         self.selectedScope = searchBar.scopeButtonTitles![selectedScope]
      }
   }
   
   fileprivate func clearTableData() {
      riders.removeAll()
      spots.removeAll()
      tableView.reloadData()
   }
}

extension SearchController: UISearchResultsUpdating {
   // MARK: - UISearchResultsUpdating Delegate
   func updateSearchResults(for searchController: UISearchController) {
      if searchController.isActive && searchController.searchBar.text != "" {
         filterContentForSearchText(searchController.searchBar.text!)
      }
      
      if searchController.searchBar.text == "" {
         clearTableData()
      }
   }
}