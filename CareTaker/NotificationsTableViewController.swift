//
//  NotificationsTableViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase

class BasicNotificationCell: UITableViewCell {
    
    @IBOutlet weak var patientNameLabel: UILabel!
    @IBOutlet weak var notificationTextLabel: UILabel!
    
}

class NotificationsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
    
    }

    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Notifications.number
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicNotificationCell", for: indexPath) as! BasicNotificationCell
        
        // Configure the cell...
        //let row : Int = indexPath.row
        
        cell.patientNameLabel.text = "Patient: " + "name"
        cell.notificationTextLabel.text = "Left area"
        
        return cell

    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // TODO update model
            Notifications.number = Notifications.number - 1
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if (Notifications.number == 0) {
                let parentVC = parent as! NotificationsViewController
                parentVC.navigationItem.leftBarButtonItem = nil
                parentVC.noNotificationsView.isHidden = false
                parentVC.notificationsTableView.isHidden = true
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    

}
