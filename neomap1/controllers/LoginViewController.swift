//
//  ViewController.swift
//  neomap1
//
//  Created by Ananya Jajoo on 12/28/20.
//

import UIKit
import GoogleSignIn
import Firebase
import AuthenticationServices

class LoginViewController: UIViewController {
    
    
    
    var hasLoadedUsername: Bool!
    
    var username: String!
    
    // Declaration for email and password fields
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hasLoadedUsername = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func login(_ sender: UIButton) {
        
        let email = emailField.text!
        let password = passwordField.text!

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let e = error {
                print(e.localizedDescription)
            } else {

                //print(self.username!)
                //print(authResult?.credential ?? "invalid credential")
                self.performSegue(withIdentifier: "loginToUser", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let uv = segue.destination as! UserViewController
        uv.email = emailField.text
        
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
