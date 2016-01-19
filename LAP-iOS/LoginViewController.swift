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
import Alamofire

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var userPasswordTextField: UITextField!
    
    let ats = OAuthAccessTokenKeychainStore(service: "http://isitso.pythonanywhere.com/o/token/")
    
    var heimdallr : Heimdallr!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if(NSUserDefaults.standardUserDefaults().valueForKey("heimdallr") != nil)
        {
            print("its there")
        }
        else
        {
            print("It is not there")
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
        
        var confirmed = false;
        
        let tokenURL = NSURL(string: "http://isitso.pythonanywhere.com/o/token/")!
        let identifier: String  =  "UEnyWPl9HbI7H1cX8T282IQ01xIF8Y9RWC02jYUh"
        let secret: String = "h1HwH0Br8LGYVigcOdzeYxn3mcCjunxq2CCfbyLTnX8wBbp7ZrBO20oOBiFWkN6rReegKz9lVxO30iLfZ8eheeWTPx3KEPEBHOjMrlFnmOPKm0i57trBfWjHvzisRLXH"
        
        let credential = OAuthClientCredentials(id: identifier, secret: secret)
        
        self.heimdallr = Heimdallr(tokenURL: tokenURL, credentials: credential, accessTokenStore: self.ats)
        
        self.heimdallr.requestAccessToken(username: userName, password: userPassword) { result in
            switch result {
            case .Success:
                print(result.description)
                confirmed = true
                print(self.ats.retrieveAccessToken()!.accessToken)
                print(self.ats.retrieveAccessToken()!.refreshToken)
                print(self.ats.retrieveAccessToken()!.expiresAt)
                print(self.ats.retrieveAccessToken()!.tokenType)
                
            case .Failure(let error):
                print("failure: \(error)")
                print("--------------------")
                print(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                if(confirmed)
                {
                        
//                    var userDefaults = NSUserDefaults.standardUserDefaults()
//                    userDefaults.setValue(self.heimdallr, forKey: "heimdallr")
                    
                    //NSUserDefaults.standardUserDefaults().setValue(self.ats, forKey: "ats")
                        
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isUserLoggedIn");
                    NSUserDefaults.standardUserDefaults().synchronize();
                    
                    print("2-------")
                    print(self.ats.retrieveAccessToken()!.accessToken)
                    
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
