//
//  YourPatientsViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit

class YourPatientsViewController: UIViewController {

    var isStartUp = true
    
    @IBOutlet weak var patientTableView: UIView!
    @IBOutlet weak var noPatientsView: UIView!
    
    var patientTableChildView : PatientsTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Show notifications tab first
        if isStartUp {
            isStartUp = false
            self.tabBarController?.selectedIndex = 1 // 2nd tab
        }
        
        // set back button as "back"
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        // set up nav bar colors
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.backgroundColor = Colors.blue
        navigationController?.navigationBar.barTintColor = Colors.blue
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        navigationController?.navigationBar.isTranslucent = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(shouldDisplayNoPatientView), name: NSNotification.Name(rawValue: finishedLoadingPatientKey), object: nil)
    }
    
    func shouldDisplayNoPatientView() {
        if (PatientDatabase.getCount() + PatientDatabase.getPendingCount() == 0) {
            noPatientsView.isHidden = false
            patientTableView.isHidden = true
        } else {
            noPatientsView.isHidden = true
            patientTableView.isHidden = false
        }
    }
    
    // ibaction for unwind
    @IBAction func newPatientSubitted(_ segue: UIStoryboardSegue) {
        // update table
    }
    
    @IBAction func patientDeleted(_ segue: UIStoryboardSegue) {
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "embededPatientTableSegue" {
            if let dvc = segue.destination as?  PatientsTableViewController {
                patientTableChildView = dvc
            }
        } else if segue.identifier == "morePatientInfoSegue" {
            let destination = segue.destination as! PatientInfoViewController
            destination.patient = sender as? Patient
            
        }

    }

}
