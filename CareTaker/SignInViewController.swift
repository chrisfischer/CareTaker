//
//  SignInViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let user = FIRAuth.auth()?.currentUser {
            self.signIn(uid: user.uid)
        } else {
            // No user is signed in.
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    // MARK: - Sign in
    
    func signIn(uid: String) {
        let ref = FIRDatabase.database().reference().child("users").child(uid).child("info").child("type")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let accountType = snapshot.value as? String ?? ""
            
            if (accountType == "careTaker") {
                self.performSegue(withIdentifier: "signInCareTakerSegue", sender: self)
            } else if (accountType == "patient") {
                self.performSegue(withIdentifier: "signInPatientSegue", sender: self)
            } else {
                self.performSegue(withIdentifier: "stillNeedMoreInfoSegue", sender: self)
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
        
    }

    @IBAction func signInTapped(_ sender: Any) {
        if self.emailField.text == "" || self.passwordField.text == "" {
            
            //Alert to tell the user that there was an error because they didn't fill anything in the textfields because they didn't fill anything in
            
            let alertController = UIAlertController(title: "Error", message: "Please enter an email and password.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            FIRAuth.auth()?.signIn(withEmail: self.emailField.text!, password: self.passwordField.text!) {
                (user, error) in
                
                if error == nil {
                    let userID = FIRAuth.auth()?.currentUser?.uid
                    self.signIn(uid: userID!)
                } else {
                    
                    //Tells the user that there is an error and then gets firebase to tell them the error
                    let alertController = UIAlertController(title: "Oops", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }

    }
}
