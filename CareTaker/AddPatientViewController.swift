//
//  AddPatientViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class AddPatientViewController: UIViewController {
    
    @IBOutlet weak var patientEmailField: UITextField!
    @IBOutlet weak var indicatorImageView: UIImageView!
    @IBOutlet weak var indicatorContainerView: UIView!
    
    @IBOutlet var emailTrailingConstraint: NSLayoutConstraint!
    var emailFullTrailingContraint: NSLayoutConstraint?
    
    var targetPatientUID: String? {
        didSet {
            if targetPatientUID != nil {
                indicatorImageView.image = #imageLiteral(resourceName: "checkmark")
            } else {
                indicatorImageView.image = #imageLiteral(resourceName: "x")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        patientEmailField.addTarget(self, action: #selector(emailFieldDidChange), for: .editingChanged)
        
        emailFullTrailingContraint = NSLayoutConstraint(item: patientEmailField, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailingMargin, multiplier: 1, constant: 0)
        emailTrailingConstraint.isActive = false
        emailFullTrailingContraint?.isActive = true
        
        patientEmailField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Text Field Changes
    
    func emailFieldDidChange() {
        if (patientEmailField.text! == "") {
            self.indicatorContainerView.isHidden = true
            self.emailTrailingConstraint.isActive = false
            self.emailFullTrailingContraint?.isActive = true
            return
        }
        if (!PatientDatabase.isValidEmail(email: patientEmailField.text!)) {
            indicatorImageView.image = #imageLiteral(resourceName: "x")
            self.indicatorContainerView.isHidden = false
            self.emailTrailingConstraint.isActive = true
            self.emailFullTrailingContraint?.isActive = false
            
            targetPatientUID = nil
            
            return
        }
        
        // valid email was entered
        indicatorImageView.image = nil
        
        self.indicatorContainerView.isHidden = false
        self.emailTrailingConstraint.isActive = true
        self.emailFullTrailingContraint?.isActive = false
        
        let patientEmail = PatientDatabase.emailRegex(email: patientEmailField.text!)
        
        let patientEmailRef = FIRDatabase.database().reference().child("patientEmails").child(patientEmail)
        patientEmailRef.observeSingleEvent(of: .value, with: { snapshot in
            self.targetPatientUID = snapshot.value as? String
        }) { error in
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: - Navigation
    
    @IBAction func submitTapped(_ sender: Any) {
        if (patientEmailField.text == nil || (patientEmailField.text)! == "") {
            self.showAlert("Please enter an email")
            return
        }
        if (!PatientDatabase.isValidEmail(email: patientEmailField.text!)) {
            self.showAlert("Email was not properly formated")
            return
        }
        if (targetPatientUID == nil) {
            self.showAlert("Patient with that email not found")
            return
        }
        
        
        let ref = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!).child("patients")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            if (snapshot.value != nil && snapshot.exists()) {
                let patientDict = snapshot.value as! [String: String]
                if Array(patientDict.values).contains(self.targetPatientUID!) {
                    self.showAlert("Patient with that email has already been added")
                } else {
                    self.performSegue(withIdentifier: "submittedSegue", sender: nil)
                }
            } else {
                self.performSegue(withIdentifier: "submittedSegue", sender: nil)
            }
            
        })
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier != "submittedSegue") {
            return true
        }
        if targetPatientUID != nil {
            return true
        }
        if patientEmailField.text == "" {
            showAlert("Please enter an email.")
        } else {
            showAlert("A patient account with that email was not found.")
        }
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "submittedSegue") {
            let careTakerRef = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!).child("patients").childByAutoId()
            careTakerRef.setValue(targetPatientUID)
            
        }
    }
    
    // MARK: - Helper funcs
    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Oops", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "Okay", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
}
