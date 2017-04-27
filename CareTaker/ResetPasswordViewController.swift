//
//  ResetPasswordViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/9/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseAuth

class ResetPasswordViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    @IBAction func backTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func sendResetEmailTapped(_ sender: Any) {
        if self.emailField.text == "" {
            let alertController = UIAlertController(title: "Oops!", message: "Please enter an email.", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            
        } else {
            FIRAuth.auth()?.sendPasswordReset(withEmail: self.emailField.text!, completion: { (error) in
                
                let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
                
                if (error == nil) {
                    alertController.title = "Success!"
                    alertController.message = "Password reset email sent."
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel) {
                        UIAlertAction in
                        
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                    alertController.addAction(defaultAction)
                    
                } else {
                    alertController.title = "Oops"
                    alertController.message = (error?.localizedDescription)!
                    self.emailField.text = ""
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                }
                
                self.present(alertController, animated: true, completion:  nil)
            })
        }

    }
}
