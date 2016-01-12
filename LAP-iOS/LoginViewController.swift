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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
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
        
        var confirmed = false;
        
        let tokenURL = NSURL(string: "http://isitso.pythonanywhere.com/o/token/")!
        let identifier: String  =  "UEnyWPl9HbI7H1cX8T282IQ01xIF8Y9RWC02jYUh"
        let secret: String = "h1HwH0Br8LGYVigcOdzeYxn3mcCjunxq2CCfbyLTnX8wBbp7ZrBO20oOBiFWkN6rReegKz9lVxO30iLfZ8eheeWTPx3KEPEBHOjMrlFnmOPKm0i57trBfWjHvzisRLXH"
        
        let credential = OAuthClientCredentials(id: identifier, secret: secret)
        
        
        let heimdallr = Heimdallr(tokenURL: tokenURL, credentials: credential)
        
        
        heimdallr.requestAccessToken(username: userName, password: userPassword) { result in
            switch result {
            case .Success:
                print(result.description)
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
                    
                    self.performSegueWithIdentifier("loginSuccessful", sender: self)
                }
                else
                {
                    self.displayMessage("Your Login Credentials are incorrect")
                }
            }
        }

    }
    
    func displayMessage(message: String){
        let myAlert = UIAlertController(title:"Alert", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated:true, completion: nil);
    }
    
}
