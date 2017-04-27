//
//  SecondViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit

class NotificationsViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var notificationsTableView: UIView!
    @IBOutlet weak var noNotificationsView: UIView!
    @IBOutlet var editButton: UIBarButtonItem!
    
    var childTableViewController: NotificationsTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up nav bar colors
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barStyle = .black
        navigationBarAppearace.backgroundColor = Colors.blue
        navigationBarAppearace.barTintColor = Colors.blue
        navigationBarAppearace.tintColor = .white
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        navigationBarAppearace.isTranslucent = false
        UIApplication.shared.statusBarStyle = .lightContent
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // check if there are any notifications
        if (Notifications.number == 0) {
            noNotificationsView.isHidden = false
            notificationsTableView.isHidden = true
            navigationItem.leftBarButtonItem = nil
        } else {
            noNotificationsView.isHidden = true
            notificationsTableView.isHidden = false
            navigationItem.leftBarButtonItem = editButton
        }
    }
    
    // MARK: - Editing
    
    @IBAction func toggleEdit(_ sender: Any) {
        if (childTableViewController?.tableView.isEditing)! {
            UIView.animate(withDuration: 0.25) {
                self.childTableViewController?.tableView.isEditing = false
            }
            editButton.title = "Edit"
            editButton.style = .plain
        } else {
            UIView.animate(withDuration: 0.25) {
                self.childTableViewController?.tableView.isEditing = true
            }
            editButton.title = "Done"
            editButton.style = .done
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embededNotifTableSegue" {
            if let dvc = segue.destination as?  NotificationsTableViewController {
                childTableViewController = dvc
            }
        }
    }


}

