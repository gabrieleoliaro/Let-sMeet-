//
//  GroupTableViewController.swift
//  Let's Meet
//
//  Created by Oliaro, Gabriele on 12/2/17.
//  Copyright © 2019 Gabriele Oliaro. All rights reserved.
//

/*
 
 THIS IS OUR TABLE VIEW CONTROLLER. 
 
 As per the official Apple Developer Guide "Start Developing iOS Apps (Swift)":

 "To display any real data in your table cells, you need to write code to load that data." 
 
 We've created our data model for a group: the Group class in the Group.swift file. Now we also need to keep a list of those groups. The natural place to track this is in a custom view controller subclass that’s connected to the group list scene (the app page that shows all the groups in a table view). This view controller will manage the view that displays the list of meals, and have a reference to the data model behind what’s shown in the user interface.
 
 */


import UIKit
import os.log
import Foundation

struct GroupInfo: Codable {
    var name: String
    var description: String
    var owner: String
}



class GroupTableViewController: UITableViewController {
    
    //MARK: Properties
    var groups = [GroupInfo]() // This creates the array of objects Groups
    var images = [UIImage]()
    let unwind_mutex = Mutex()
    
    func showAlertView(error_message: String)
    {
        // Show an alert message
        let alertController = UIAlertController(title: "Alert", message: error_message, preferredStyle: .alert)
        let OK_button = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            //print("You've pressed OK");
        }
        alertController.addAction(OK_button)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func downloadGroups() -> Bool
    {
        
        // this mutex will be used to make sure that we don't return a value until the datatask is actually done
        let local_mutex = Mutex()
        local_mutex.lock() // lock so that the function cannot return until the dataTask releases the lock upon finishing
        
        var toreturn = false
        
        restoreCookies()
        
        // dowload the data
        let webservice_URL = URL(string: "https://www.gabrieleoliaro.it/db/get_groups.php")
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "Accept": "application/json"
        ]
        
        let session = URLSession(configuration: config)
        var request = URLRequest(url: webservice_URL!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { data, response, error in
            
            print(response)
            
            guard let dataResponse = data, error == nil else {
                print(error?.localizedDescription ?? "Response Error")
                
                local_mutex.unlock()
                return
            }
            
            print(dataResponse)
            
            do {
                //here dataResponse received from a network request
                let decoder = JSONDecoder()
                self.groups = try decoder.decode([GroupInfo].self, from:
                    dataResponse) //Decode JSON Response Data
                print(self.groups)
                toreturn = true
                
            } catch let parsingError {
                print("Error", parsingError)
                return
            }
            
            local_mutex.unlock()
            
        }
        task.resume()
        
        local_mutex.lock()
        return toreturn
    }
    
    func downloadGroupImage(groupname: String) -> UIImage
    {
        //restoreCookies() // actually not needed since the images are not protected yet
        
        let local_mutex = Mutex()
        local_mutex.lock()
        
        // by default, if we can't download a profile picture from the network, this function returns the default image
        var returnimage = UIImage(named: "defaultPhoto")!
        
        // download the profile picture
        let groupname_safe = groupname.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let imageLocation = "https://www.gabrieleoliaro.it/db/uploads/groups_pictures/" + groupname_safe + ".jpg"
        print("imagelocation:" + imageLocation)
        guard let imageUrl = URL(string: imageLocation) else {
            print("Cannot create URL")
            local_mutex.unlock()
            return returnimage
        }
        
        let image_task = URLSession.shared.downloadTask(with: imageUrl) {(location, response, error) in
            
            guard let location = location else {
                print("location is nil")
                local_mutex.unlock()
                return
            }
            
            print(location)
            
            let imageData = try! Data(contentsOf: location)
            let image = UIImage(data: imageData)
            
            if (image != nil)
            {
                returnimage = image!
            }
            local_mutex.unlock()
        }
        image_task.resume()
        
        local_mutex.lock()
        return returnimage
    }
    
    func getUpdatedInfo()
    {
        if (!downloadGroups())
        {
            showAlertView(error_message: "Could not download the user's groups")
        }
        unwind_mutex.unlock()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.getUpdatedInfo()
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    // MARK: - Table view data source

    // This functions defines the number of sections of the table view. In our case, the table is pretty simple, and so one section is enough
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    // This function determines the number of rows that the table will need by counting the number of groups in the groups array.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("group count: "); print(groups.count); print("\n")
        return groups.count
    }

    // this function configures and displays the table's visible cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "GroupTableViewCell"
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GroupTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MealTableViewCell.")
        }
        
        // Fetches the appropriate meal for the data source layout.
        let group = groups[indexPath.row]
        
        cell.groupNameLabel.text = group.name
        let currentImage = downloadGroupImage(groupname: group.name)
        cell.groupPhotoImageView.image = currentImage
        self.images.append(currentImage)
        cell.groupDescriptionLabel.text = group.description
        
        return cell
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Just call superclass implementation
        super.prepare(for: segue, sender: sender)
        
        
        switch(segue.identifier ?? "") {
            
        case "showProfile":
            os_log("Viewing or editing the members of the activity.", log: OSLog.default, type: .debug)
            
            
        case "showGroup":
            guard let current_groupViewController = segue.destination as? GroupViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedGroupCell = sender as? GroupTableViewCell else {
                fatalError("Unexpected sender: \(sender)")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedGroupCell) else {
                fatalError("The selected cell is not being displayed by the table")
            }
            
            let selectedGroup = groups[indexPath.row]
            current_groupViewController.group = selectedGroup
            current_groupViewController.image = images[indexPath.row]
        
        case "newGroup":
            os_log("Adding a new group.", log: OSLog.default, type: .debug)
        default:
            fatalError("Weird")
        }
        
    }
    
    @IBAction func unwindToGroupTableView(segue:UIStoryboardSegue) {
        unwind_mutex.lock()
        self.getUpdatedInfo()
        unwind_mutex.lock()
        self.tableView.reloadData()
        unwind_mutex.unlock()
    }


}
