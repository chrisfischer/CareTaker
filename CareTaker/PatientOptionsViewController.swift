//
//  PatientOptionsViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/18/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class PatientOptionsViewController: UIViewController {
    
    let userRef = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!)
    var userHandle: UInt?
    
    var noCareTakerFullContsraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        noCareTakerFullContsraint = NSLayoutConstraint(item: noCareTakerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        
        setUpGesture()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setUpOptionsToShow()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dismissKeyBoard()
        removeObservers()
        userRef.removeObserver(withHandle: userHandle!)
    }
    
    //MARK: - Options to Show
    
    @IBOutlet weak var addCareTakerView: UIView!
    @IBOutlet weak var noCareTakerView: UIView!
    @IBOutlet weak var careTakerInfoView: UIView!
    
    @IBOutlet weak var careTakerEmailField: UITextField!
    
    @IBOutlet weak var careTakerNameLabel: UILabel!
    @IBOutlet weak var careTakerPhoneLabel: UILabel!
    @IBOutlet weak var careTakerEmailLabel: UILabel!
    
    @IBOutlet weak var noCTTopLabel: UILabel!
    @IBOutlet weak var noCTBottomLabel: UILabel!
    @IBOutlet weak var noCTSubtitleLabel: UILabel!
    @IBOutlet weak var noCTSubtitleBottomLabel: UILabel!
    
    @IBOutlet var noCareTakerSmallConstraint: NSLayoutConstraint! {
        didSet {
            noCareTakerSmallConstraint.isActive = false
        }
    }
    
    var refObservers = [(FIRDatabaseReference, UInt)]()
    
    func setUpOptionsToShow() {
        
        userHandle = userRef.child("careTakers").observe(.value, with: { snapshot in
            if (snapshot.value != nil && snapshot.exists()) {
                let careTakerDict = snapshot.value as! [String: String]
                if !careTakerDict.isEmpty {
                    
                    // get data of just first caretaker
                    if let ctID = Array(careTakerDict.values).first {
                        // remove previous observers
                        self.removeObservers()
                        
                        let ctPatientRef = FIRDatabase.database().reference().child("users").child(ctID).child("patients")
                        let handle = ctPatientRef.observe(.value, with: { snapshot in
                            //guard snapshot.exists() && snapshot.value != nil else { return }
                            
                            let ctPatients = snapshot.value as? [String: String]
                            
                            let UID = (FIRAuth.auth()?.currentUser?.uid)!
                            if !snapshot.exists() || ctPatients == nil || !Array((ctPatients?.values)!).contains(UID) {
                                
                                // update view - waiting confirmation
                                self.careTakerInfoView.isHidden = true
                                self.noCareTakerView.isHidden = false
                                self.noCTTopLabel.text = "Caretaker Pending"
                                self.noCTBottomLabel.isHidden = true
                                self.noCTSubtitleLabel.text = "Waiting on caretaker confirmation"
                                self.noCTSubtitleBottomLabel.isHidden = true
                                self.noCareTakerSmallConstraint.isActive = false
                                self.noCareTakerFullContsraint?.isActive = true
                                
                                NotificationCenter.default.post(name: Notification.Name(rawValue: removedCaretakerKey), object: self)
                                
                                // hide email field
                                self.addCareTakerView.isHidden = true
                                
                                UIView.animate(withDuration: 0.2) {
                                    self.view.layoutIfNeeded()
                                }
                                return
                            }
                            
                            let ctInfoRef = FIRDatabase.database().reference().child("users").child(ctID).child("info")
                            let handle = ctInfoRef.observe(.value, with: { snapshot in
                                guard snapshot.exists() && snapshot.value != nil else { return }
                                
                                let ctInfoDict = snapshot.value as? [String: String]
                                
                                // update view - caretaker confirmed
                                self.careTakerInfoView.isHidden = false
                                self.noCareTakerView.isHidden = true
                                self.noCareTakerFullContsraint?.isActive = false
                                // hide email field
                                self.addCareTakerView.isHidden = true
                                
                                NotificationCenter.default.post(name: Notification.Name(rawValue: hasCaretakerKey), object: self)
                                
                                let firstName = ctInfoDict?["firstName"]
                                let lastName = ctInfoDict?["lastName"]
                                let email = ctInfoDict?["email"]
                                let phone = ctInfoDict?["phone"]
                                
                                if (firstName == nil || lastName == nil || email == nil || phone == nil) {
                                    print("error in database, UID: " + ctID)
                                    return
                                }
                                self.setCareTakerLabels(firstName: firstName!, lastName: lastName!, phone: phone!, email: email!)
                            })
                            self.refObservers.append((ctInfoRef, handle))
                        })
                        self.refObservers.append(ctPatientRef, handle)
                    }
                    return
                }
            }
            // update view - has no caretaker
            self.careTakerInfoView.isHidden = true
            self.addCareTakerView.isHidden = false
            self.noCareTakerView.isHidden = false
            self.noCareTakerSmallConstraint.isActive = false
            self.noCareTakerFullContsraint?.isActive = true
            self.noCTTopLabel.text = "You don't have"
            self.noCTBottomLabel.isHidden = false
            self.noCTSubtitleLabel.text = "Type your caretaker's email into the field above"
            self.noCTSubtitleBottomLabel.isHidden = false
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: removedCaretakerKey), object: self)
            
        })
    }
    
    func removeObservers() {
        for (ref, handle) in refObservers {
            ref.removeObserver(withHandle: handle)
        }
        refObservers.removeAll()
    }
    
    @IBAction func submitTapped(_ sender: Any) {
        // check stuff
        if (careTakerEmailField.text == nil || (careTakerEmailField.text)!.isEmpty) {
            showAlert("Please enter an email")
        } else if (!PatientDatabase.isValidEmail(email: careTakerEmailField.text!)) {
            showAlert("Please enter a properly formated email")
        } else {
            let formatedEmail = PatientDatabase.emailRegex(email: careTakerEmailField.text!)
            FIRDatabase.database().reference().child("careTakerEmails").child(formatedEmail).observeSingleEvent(of: .value, with: { snapshot in
                let targetCareTakerUID = snapshot.value as? String
                
                guard let UID = targetCareTakerUID else {
                    self.showAlert("No user with that email was found.")
                    return
                }
                
                self.userRef.child("info").child("status").setValue("active")
                self.userRef.child("careTakers").childByAutoId().setValue(UID)
                // hide keyboard
                self.dismissKeyBoard()
            })
        }
    }
    
    @IBAction func removeCareTaker(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: "Your caretaker can always be added back.", preferredStyle: UIAlertControllerStyle.alert)
        let no = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let yes = UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.userRef.child("careTakers").removeValue()
        })
        alert.addAction(no)
        alert.addAction(yes)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func setCareTakerLabels(firstName: String, lastName: String, phone: String, email: String) {
        careTakerNameLabel.text = firstName + " " + lastName
        careTakerPhoneLabel.text = phone
        careTakerEmailLabel.text = email
        
    }
    
    // MARK: - Gestures
    
    func setUpGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyBoard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyBoard() {
        view.endEditing(true)
    }
    
    // MARK: - Navigation
    
    @IBAction func doneTapped(_ sender: Any) {
        // do things
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()?.signOut()
                NotificationCenter.default.post(name: Notification.Name(rawValue: loggedOutPatientKey), object: self)
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                
                // reset navbar
                let navigationBarAppearace = UINavigationBar.appearance()
                navigationBarAppearace.barStyle = .black
                navigationBarAppearace.backgroundColor = Colors.blue
                navigationBarAppearace.barTintColor = Colors.blue
                navigationBarAppearace.tintColor = .white
                navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
                navigationBarAppearace.isTranslucent = false
                UIApplication.shared.statusBarStyle = .lightContent
                
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func changePasswordTapped(_ sender: Any) {
        FIRAuth.auth()?.sendPasswordReset(withEmail: (FIRAuth.auth()?.currentUser?.email)!, completion: { (error) in
            
            let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
            
            if (error == nil) {
                alertController.title = "Success!"
                alertController.message = "Password reset email sent."
                
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                
                alertController.addAction(defaultAction)
                
            } else {
                alertController.title = "Oops"
                alertController.message = (error?.localizedDescription)!
                
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alertController.addAction(defaultAction)
            }
            
            self.present(alertController, animated: true, completion:  nil)
        })
    }
    
    // MARK: - Helper funcs
    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
}
