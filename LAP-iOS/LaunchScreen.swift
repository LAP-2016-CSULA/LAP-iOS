//
//  LaunchScreen.swift
//  LAP-iOS
//
//  Created by Kevin Argumedo on 4/12/16.
//  Copyright © 2016 Hugo Sanchez. All rights reserved.
//

import Foundation
import UIKit
import Heimdallr

class LaunchScreen : UIViewController {
    
    let ats = OAuthAccessTokenKeychainStore(service: "http://isitso.pythonanywhere.com/o/token/")
    var heimdallr : Heimdallr!;
    let k = KeychainWrapper.standardKeychainAccess();

    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let userName: String? = k.stringForKey("username");
        let userPassword: String? = k.stringForKey("p")
        if userName != nil && userPassword != nil
        {
            var confirmed = false;
            let tokenURL = NSURL(string: "http://isitso.pythonanywhere.com/o/token/")!
            let identifier: String  =  "UEnyWPl9HbI7H1cX8T282IQ01xIF8Y9RWC02jYUh"
            let secret: String = "h1HwH0Br8LGYVigcOdzeYxn3mcCjunxq2CCfbyLTnX8wBbp7ZrBO20oOBiFWkN6rReegKz9lVxO30iLfZ8eheeWTPx3KEPEBHOjMrlFnmOPKm0i57trBfWjHvzisRLXH";
            
            let credential = OAuthClientCredentials(id: identifier, secret: secret)
            
            self.heimdallr = Heimdallr(tokenURL: tokenURL, credentials: credential, accessTokenStore: self.ats)
            
            self.heimdallr.requestAccessToken(username: userName!, password: userPassword!)
            { result in
                switch result
                {
                case .Success:
                    confirmed = true
                    
                case .Failure(let error):
                    print("failure: \(error)")
                    print("--------------------")
                    print(error.localizedDescription)
                }
                
                dispatch_async(dispatch_get_main_queue())
                {
                    if(confirmed)
                    {
                        
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isUserLoggedIn");
                        NSUserDefaults.standardUserDefaults().synchronize();
                        
                        self.k.setString(userName!, forKey:"username");
                        
                        self.k.setString(userPassword!, forKey: "p");
                        
                        self.performSegueWithIdentifier("toMap", sender: self)
                    }
                    else
                    {
                        self.performSegueWithIdentifier("toLoginView", sender: self)
                    }
                }
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue())
            {
                self.performSegueWithIdentifier("toLoginView", sender: self)
            }
        }

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if(segue.identifier == "toMap")
        {
            let navDest = segue.destinationViewController as! UINavigationController
            
            let heim = navDest.viewControllers.first as! MapViewController
            
            heim.heimdallr = self.heimdallr
            heim.ats = self.ats
        }
    }
}