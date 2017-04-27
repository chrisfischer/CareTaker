//
//  GetInfoViewController.swift
//  CareTaker
//
//  Created by Chris Fischer on 4/08/17.
//  Copyright © 2017 Chris Fischer. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class GetInfoViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var pickOption = ["", "Patient", "Caretaker"]
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var accountTypeField: UITextField!
    
    @IBOutlet weak var takePhotoButton: RoundedButton!
    
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var phoneInfoButton: UIButton!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pickerView = UIPickerView()
        pickerView.backgroundColor = .white
        
        pickerView.delegate = self
        
        accountTypeField.inputView = pickerView
        
        // Do any additional setup after loading the view.
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            takePhotoButton.isHidden = true
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }
    
    // MARK: - UIPickerView DataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickOption.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickOption[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        accountTypeField.text = pickOption[row]
        if (accountTypeField.text == "Patient") {
            // do something
            takePhotoButton.isHidden = false
        } else if (accountTypeField.text == "Caretaker") {
            // do something else
            takePhotoButton.isHidden = true
        } else {
            takePhotoButton.isHidden = true
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func confirm(_ sender: Any) {
        guard accountTypeField.text != "" else {
            sendAlert()
            return
        }
        
        if (accountTypeField.text == "Caretaker") {
            if let firstName = firstNameField.text, let lastName = lastNameField.text, let phone = phoneNumberField.text {
                if (firstName != "" && lastName != "" && phone != "") {
                    let ref = FIRDatabase.database().reference()
                    let userID = FIRAuth.auth()?.currentUser?.uid
                    let userEmail = FIRAuth.auth()?.currentUser?.email
                    
                    // add caretaker info to their node in "users"
                    ref.child("users").child(userID!).child("info").setValue([
                        "type": "careTaker",
                        "firstName": firstName,
                        "lastName": lastName,
                        "email": userEmail!,
                        "phone": phone
                        ])
                    
                    // add email to caretaker emails data structure
                    ref.child("careTakerEmails").child(PatientDatabase.emailRegex(email: userEmail!)).setValue(userID!)
                    
                    performSegue(withIdentifier: "careTakerConfirmSegue", sender: self)
                } else {
                    sendAlert()
                }
            }
        } else if (accountTypeField.text == "Patient") {
            
            // TODO do something with sign up code
            
            if let firstName = firstNameField.text, let lastName = lastNameField.text, let phone = phoneNumberField.text {
                if (firstName != "" && lastName != "" && phone != "") {
                    let ref = FIRDatabase.database().reference()
                    let userID = FIRAuth.auth()?.currentUser?.uid
                    let userEmail = FIRAuth.auth()?.currentUser?.email
                    
                    // add patient info to their node in "users"
                    ref.child("users").child(userID!).child("info").updateChildValues([
                        "type": "patient",
                        "firstName": firstName,
                        "lastName": lastName,
                        "email": userEmail!,
                        "phone": phone
                        ])
                    
                    // add email to patient emails data structure
                    ref.child("patientEmails").child(PatientDatabase.emailRegex(email: userEmail!)).setValue(userID!)
                    
                    performSegue(withIdentifier: "patientConfirmSegue", sender: self)
                } else {
                    sendAlert()
                }
            }
        }
    }
    
    @IBAction func phoneInfo(_ sender: Any) {
        let alertController = UIAlertController(title: "Phone Number", message: "Used to let you make easy calls between you and your caretaker.", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func sendAlert() {
        let alertController = UIAlertController(title: "Error", message: "Please complete all fields", preferredStyle: .alert)
        
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Get Image
    
    @IBAction func takePicture(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        //picker.mediaTypes = [kUTTypeImage]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image  = info[UIImagePickerControllerOriginalImage] as? UIImage
        image = self.resizeImage(image: image!, targetSize: CGSize(width: 100.0, height: 100.0))
        let data = UIImageJPEGRepresentation(image!, 0.8)! as NSData
        let userID = FIRAuth.auth()?.currentUser?.uid
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpg"
        self.takePhotoButton.layer.backgroundColor = Colors.lightGray.cgColor
        self.takePhotoButton.isEnabled = false
        FIRStorage.storage().reference().child("profiles/\(userID!).jpg").put(data as Data, metadata: metadata) {(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                let downloadURL = metaData!.downloadURL()!.absoluteString
                //store downloadURL at database
                FIRDatabase.database().reference().child("users").child(FIRAuth.auth()!.currentUser!.uid).child("info").child("profilePhoto").setValue(downloadURL)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width/image.size.width
        let heightRatio = targetSize.height/image.size.height
        
        // determine orientation
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    
    
}
