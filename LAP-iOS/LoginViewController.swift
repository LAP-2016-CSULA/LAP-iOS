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
    
    let ats = OAuthAccessTokenKeychainStore(service: "http://lap.pythonanywhere.com/o/token/");
    var heimdallr : Heimdallr!
    var guestLoggedIn = false;
    let k = KeychainWrapper.standardKeychainAccess();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        view.addGestureRecognizer(tap);
    }
    
    override func viewWillAppear(animated: Bool) {
        let retrievedUsername: String? = k.stringForKey("username");
        let pass: String? = k.stringForKey("p")
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
        
    @IBAction func guestLoginbuttonTapped(sender: AnyObject) {
        var confirmed = false;
        let tokenURL = NSURL(string: "http://lap.pythonanywhere.com/o/token/")!
        let identifier: String  =  "jDrkG226oJROtk53UCuyWKkvYpA5Wpi2iivMa2LV"
        let secret: String = "go7XmobVllAaZz5NlD6v7lgoN9DcETtU1yZNDvHtbjKAUiuBBJKeMfWKVmBCqnw1N1SOy31aePwPb7JWz8dXNAVPpb7ZPBayOWsMEGZJCP6VrZeypXBVvIUr5Z3XeWqr";
        let credential = OAuthClientCredentials(id: identifier, secret: secret);
        self.heimdallr = Heimdallr(tokenURL: tokenURL, credentials: credential, accessTokenStore: self.ats);
        self.guestLoggedIn = true;
        self.heimdallr.requestAccessToken(username: "guest", password: "guest123456789101112LAP") { result in
            switch result {
            case .Success:
                confirmed = true
                
            case .Failure(let error):
                print("failure: \(error)")
                print("--------------------")
                print(error.localizedDescription)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                if(confirmed){
                    self.performSegueWithIdentifier("loginSuccessful", sender: self);
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
    
    func login(userName: String, userPassword: String){
        var confirmed = false;
        let tokenURL = NSURL(string: "http://lap.pythonanywhere.com/o/token/")!
        let identifier: String  =  "jDrkG226oJROtk53UCuyWKkvYpA5Wpi2iivMa2LV"
        let secret: String = "go7XmobVllAaZz5NlD6v7lgoN9DcETtU1yZNDvHtbjKAUiuBBJKeMfWKVmBCqnw1N1SOy31aePwPb7JWz8dXNAVPpb7ZPBayOWsMEGZJCP6VrZeypXBVvIUr5Z3XeWqr";
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
                    
                    self.k.setString(userName, forKey:"username");
                    self.k.setString(userPassword, forKey: "p");
                    
                    self.performSegueWithIdentifier("loginSuccessful", sender: self);
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
            heim.guestLoggedIn = self.guestLoggedIn;
        }
    }
}
