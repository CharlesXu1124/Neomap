//
//  ViewController.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/28/20.
//

import UIKit
import AuthenticationServices
import GoogleSignIn
import Firebase

class RegisterViewController:
    UIViewController {
    
    //Declare database instance
    let db = Firestore.firestore()
    
    //Decalring user field's
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func register(_ sender: UIButton) {
        let email = emailField.text!
        let password = passwordField.text!
        let name = nameField.text!
        
        addUsername(withName: name, withEmail: email)
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            // [START_EXCLUDE]
          guard let user = authResult?.user, error == nil else {
            return
          }
          print("\(user.email!) created")
        }
            // [END_EXCLUDE]
    }
    
    func addUsername(withName name: String, withEmail email: String) {
        var ref: DocumentReference? = nil
        ref = db.collection("usersInfo").addDocument(data: [
            "username": name,
            "email": email
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
