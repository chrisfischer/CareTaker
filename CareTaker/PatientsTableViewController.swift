//
//  PatientsTableViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class PatientCell: UITableViewCell {
    
    @IBOutlet weak var patientImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var profileImageView: RoundedImage!
    
    var phone: String?
    
    @IBAction func placeCall(_ sender: Any) {
        if let phone = phone {
            guard let number = URL(string: "telprompt://" + phone) else { return }
            UIApplication.shared.open(number, options: [:], completionHandler: nil)
        }
    }
}

class PendingCell: UITableViewCell {
    
    @IBOutlet weak var pendingEmailLabel: UILabel!
    
}

class PatientsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let careTakersPRef = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!).child("patients")
    var refObservers = [(FIRDatabaseReference, UInt)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(toLogOut), name: NSNotification.Name(rawValue: loggedOutPatientKey), object: nil)
        
        // Get patients
        let handle = careTakersPRef.observe(.value, with: { snapshot in
            if (snapshot.value == nil || !snapshot.exists()) {
                // has no patients
                if PatientDatabase.getCount() != 0 {
                    PatientDatabase.removeAllPatients()
                }
                
                self.tableView.reloadData()
                
                // for parent view to check if there are any patients
                NotificationCenter.default.post(name: Notification.Name(rawValue: finishedLoadingPatientKey), object: self)
                
            } else {
                // patients currently listed under caretaker
                let patientDict = snapshot.value as? [String: String]
                
                guard patientDict != nil else { return }
                
                // reset local patient database
                PatientDatabase.removeAllPatients()
                PatientDatabase.removeAllPendingPatients()
                
                for patientId in Array(patientDict!.values) {
                    // get each patient's info
                    let patientCtRef = FIRDatabase.database().reference().child("users").child(patientId).child("careTakers")
                    let ctHandle = patientCtRef.observe(.value, with: { snapshot in
                        let pCareTakers = snapshot.value as? [String: String]
                        let UID = (FIRAuth.auth()?.currentUser?.uid)!
                        if pCareTakers == nil || !Array((pCareTakers?.values)!).contains(UID) {
                            // MARK: - Patient not confirmed yet
                            
                            // remove patient from local database after removed from cloud
                            PatientDatabase.removePatient(uid: patientId)
                            
                            // get email to display in table
                            let patientEmailRef = FIRDatabase.database().reference().child("users").child(patientId).child("info").child("email")
                            patientEmailRef.observeSingleEvent(of: .value, with: { snapshot in
                                let email = snapshot.value as? String
                                if let email = email {
                                    PatientDatabase.pendingPatientArr.append(email)
                                    self.tableView.reloadData()
                                }
                            })
                            
                        } else {
                            // MARK: - Patient confirmed
                            
                            let patientInfoRef = FIRDatabase.database().reference().child("users").child(patientId).child("info")
                            patientInfoRef.observeSingleEvent(of: .value, with: { snapshot in
                                let patientInfoDict = snapshot.value as! [String: Any]
                                
                                let firstName = patientInfoDict["firstName"] as? String
                                let lastName = patientInfoDict["lastName"] as? String
                                let email = patientInfoDict["email"] as? String
                                let phone = patientInfoDict["phone"] as? String
                                
                                if (firstName == nil || lastName == nil || email == nil || phone == nil) {
                                    print("error in database, UID: " + patientId)
                                    return
                                }
                                
                                let imageUrl = patientInfoDict["profilePhoto"] as? String
                                
                                let newPatient = Patient(firstName: firstName!, lastName: lastName!, email: email!, phone: phone!, imageUrl: imageUrl, image: nil, UID: patientId)
                                
                                PatientDatabase.addPatient(patient: newPatient)
                                PatientDatabase.removePending(email: email!)
                                
                                // updating the view appropriately
                                PatientDatabase.getProfilePhotos() {
                                    self.tableView.reloadData()
                                }
                                NotificationCenter.default.post(name: Notification.Name(rawValue: finishedLoadingPatientKey), object: self)
                                self.tableView.reloadData()
                            })
                            let patientStatusRef = FIRDatabase.database().reference().child("users").child(patientId).child("status")
                            let statusHandle = patientStatusRef.observe(.value, with: { snapshot in
                                guard snapshot.exists() && snapshot.value != nil else { return }
                                
                                let status = snapshot.value as! String
                                
                                PatientDatabase.updateStatus(uid: patientId, status: status)
                                self.tableView.reloadData()
                            })
                            self.refObservers.append((patientStatusRef, statusHandle))
                        }
                    })
                    self.refObservers.append((patientCtRef, ctHandle))
                }
            }
        })
        refObservers.append((careTakersPRef,handle))
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let path = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: path, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func toLogOut() {
        //remove observers
        for (ref, handle) in refObservers {
            ref.removeObserver(withHandle: handle)
        }
        refObservers.removeAll()
    }
    
    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PatientDatabase.getCount() + PatientDatabase.getPendingCount()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row : Int = indexPath.row
        
        if row >= PatientDatabase.getCount() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "pendingCell", for: indexPath) as! PendingCell
            
            cell.pendingEmailLabel.text = PatientDatabase.pendingPatientArr[row - PatientDatabase.getCount()]
            cell.selectionStyle = .none
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "patientCell", for: indexPath) as! PatientCell
            
            let patient = PatientDatabase.patientArr[row]
            
            cell.selectionStyle = .default
            cell.nameLabel.text = patient.firstName + " " + patient.lastName
            cell.phone = patient.phone
            cell.patientImageView.image = patient.image ?? #imageLiteral(resourceName: "profile_placeholder")
            
            if let status = patient.status {
                
                switch status {
                case "active" :
                    cell.statusLabel.text = "Active"
                    cell.statusLabel.textColor = Colors.green
                    break
                case "away" :
                    cell.statusLabel.text = "Away from phone"
                    cell.statusLabel.textColor = Colors.red
                    break
                case "loggedOut" :
                    cell.statusLabel.text = "Logged Out"
                    cell.statusLabel.textColor = Colors.red
                    break
                default :
                    break
                }
            } else {
                cell.statusLabel.text = "Unknown"
                cell.statusLabel.textColor = Colors.red
            }
            
            return cell
        }
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        
        if row < PatientDatabase.getCount() {
            parent?.performSegue(withIdentifier: "morePatientInfoSegue", sender: PatientDatabase.patientArr[row])
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row
        
        if row >= PatientDatabase.getCount() {
            return 55
        } else {
            return 96
        }
    }
    
    
    
    
}
