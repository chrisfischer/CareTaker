//
//  FirstViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/8/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class AccountViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    @IBOutlet weak var infoStackView: UIStackView!
    
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
        
                
        let infoRef = FIRDatabase.database().reference().child("users").child((FIRAuth.auth()?.currentUser?.uid)!).child("info")
        infoRef.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else { return }
            let infoDict = snapshot.value as? [String: String]
            
            if let infoDict = infoDict {
                let firstName = infoDict["firstName"]
                let lastName = infoDict["lastName"]
                let email = infoDict["email"]
                let phone = infoDict["phone"]
                
                if (firstName == nil || lastName == nil || email == nil || phone == nil) {
                    print("error in database. UID: \((FIRAuth.auth()?.currentUser?.uid)!))")
                } else {
                    self.nameLabel.text = "\(firstName!) \(lastName!)"
                    self.emailLabel.text = email
                    self.phoneLabel.text = phone
                    
                    self.infoStackView.isHidden = false
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                }
            }
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func logOutTapped(_ sender: Any) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()?.signOut()
                NotificationCenter.default.post(name: Notification.Name(rawValue: loggedOutCaretakerKey), object: self)
                self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                
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

    
}

