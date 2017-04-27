//
//  EditPatientViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/19/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class EditPatientViewController: UIViewController {
    
    var patient: Patient?
    let userId = FIRAuth.auth()?.currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBAction func removePatient(_ sender: Any) {
        
        let alert = UIAlertController(title: "Are you sure?", message: "You can always add them back, but your location boundary will be lost.", preferredStyle: UIAlertControllerStyle.alert)
        let yes = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { action in
            // remove value
            let ref = FIRDatabase.database().reference().child("users").child(self.userId!).child("patients")
            ref.queryEqual(toValue: (self.patient?.UID)!).observeSingleEvent(of: .childChanged, with: { snapshot in
                snapshot.ref.removeValue()
                
            })
            
            
        })
        let no = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(yes)
        alert.addAction(no)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    // MARK: - Navigation
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        
    }
    
}
