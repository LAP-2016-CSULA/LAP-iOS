//
//  LoginViewController.swift
//  LAP-iOS
//
//  Created by kevin on 1/11/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//  

import Foundation
import UIKit
import Heimdallr

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var userPasswordTextField: UITextField!
    
    let ats = OAuthAccessTokenKeychainStore(service: "http://isitso.pythonanywhere.com/o/token/")
    
    var heimdallr : Heimdallr!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap);
    }
    
    override func viewWillAppear(animated: Bool) {
        let retrievedUsername: String? = KeychainWrapper.stringForKey("username");
        let pass: String? = KeychainWrapper.stringForKey("p")
        if retrievedUsername != nil && pass != nil{
            login(retrievedUsername!, userPassword: pass!);
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonTapped(sender: AnyObject) {
        let userName = String(userNameTextField.text!);
        let userPassword = String(userPasswordTextField.text!);
        
        
        if(userName.isEmpty || userPassword.isEmpty)
        {
            displayMessage("All Fields Are Required")
            return
        }
        
        login(userName,userPassword: userPassword);
 
    }
        
    func displayMessage(message: String){
        let myAlert = UIAlertController(title:"Alert", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated:true, completion: nil);
    }
    
func login(userName: String, userPassword: String){
        var confirmed = false;
        let tokenURL = NSURL(string: "http://isitso.pythonanywhere.com/o/token/")!
        let identifier: String  =  "UEnyWPl9HbI7H1cX8T282IQ01xIF8Y9RWC02jYUh"
        let secret: String = "h1HwH0Br8LGYVigcOdzeYxn3mcCjunxq2CCfbyLTnX8wBbp7ZrBO20oOBiFWkN6rReegKz9lVxO30iLfZ8eheeWTPx3KEPEBHOjMrlFnmOPKm0i57trBfWjHvzisRLXH";
        let credential = OAuthClientCredentials(id: identifier, secret: secret)
    
        self.heimdallr = Heimdallr(tokenURL: tokenURL, credentials: credential, accessTokenStore: self.ats)
        self.heimdallr.requestAccessToken(username: userName, password: userPassword) { result in
            switch result {
            case .Success:
                confirmed = true
                
            case .Failure(let error):
                print("failure: \(error)")
                print("--------------------")
                print(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                if(confirmed)
                {
                    
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isUserLoggedIn");
                    NSUserDefaults.standardUserDefaults().synchronize();
                    
                    KeychainWrapper.setString(userName, forKey:"username");
                    KeychainWrapper.setString(userPassword, forKey: "p");
                    
                    self.performSegueWithIdentifier("loginSuccessful", sender: self)
                }
                else
                {
                    self.displayMessage("Your Login Credentials are incorrect")
                }
            }
            
        }
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "loginSuccessful")
        {
            let navDest = segue.destinationViewController as! UINavigationController
            
            let heim = navDest.viewControllers.first as! MapViewController
            
            heim.heimdallr = self.heimdallr
            heim.ats = self.ats
        }
    }
}
