//
//  ViewSpecie.swift
//  LAP-iOS
//
//  Created by kevin on 1/18/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//


import Alamofire
import Foundation
import UIKit
import Heimdallr
import Kingfisher

class ViewSpecie: UIViewController {

    var observation: Observation!;
        
    //text and image displayed.
    @IBOutlet var textView: UITextView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var bottomBar: UINavigationItem!
    @IBOutlet var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.kf_showIndicatorWhenLoading = true;
        let logo = UIImage(named: "topbaricon");
        let imageView = UIImageView(image:logo);
        self.bottomBar.titleView = imageView;
        
        let URL = NSURL(string: String(self.observation.specie["image"]))!
        let resource = Resource(downloadURL: URL, cacheKey: String(self.observation.specie["image"]))

        self.imageView.kf_setImageWithResource(resource, placeholderImage: nil,optionsInfo: [.Transition(ImageTransition.Fade(1))]);
        
        title = String(self.observation.specie["name"]);
        
        //does not allow text view to be edited.
        textView.editable = false
        
        textView.layer.borderWidth = 1;
        textView.layer.borderColor = UIColor(red: 187.0, green: 226.0, blue: 188.0, alpha: 1.0).CGColor;
        
        //sets description on specie from API
        textView.text = String(self.observation.specie["description"]);
        
//        Determine what buttons should be displayed on screen
        if(observation.viewOnly == true){
            nextButton.enabled = false;
            nextButton.tintColor = UIColor.clearColor();
            deleteButton.enabled = false;
            deleteButton.tintColor = UIColor.clearColor();
        }
        if(observation.guest == true){
            nextButton.enabled = false;
            nextButton.tintColor = UIColor.clearColor();
            deleteButton.enabled = false;
            deleteButton.tintColor = UIColor.clearColor();
        }
        
        if(observation.isUpdate == false){
            deleteButton.enabled = false;
            deleteButton.tintColor = UIColor.clearColor();
        }
        
    }
    
    @IBAction func toQuestions(sender: AnyObject){
        if(String(self.observation.specie["type"]["id"]) == "1")
        {
            performSegueWithIdentifier("toTreeQuestions", sender: self)
        }
        
        if(String(self.observation.specie["type"]["id"]) == "2")
        {
            performSegueWithIdentifier("toBirdQuestions", sender: self)
        }
    }
    
    @IBAction func sendDeletionRequest(sender: AnyObject) {
//        ***
//        Leaving this here for now, may use this to determine if user can delete trees without having to
//        send emails
        print(self.observation.user["is_superuser"]);
//        ***
        let email = "laphenology@gmail.com";
        let treeID = self.observation.treeID;
        let url = NSURL(string: "mailto:\(email)?subject=Request%20to%20delete%20tree:%20\(treeID)%20&body=Request%20to%20delete%20tree:%20\(treeID),%20Please%20provide%20a%20brief%20explanation:%20");
        
        let menu = UIAlertController(title: "Attention", message: "*You must email LAP administrator to request for tree to be removed*", preferredStyle: UIAlertControllerStyle.ActionSheet);
        let sendEmailAction = UIAlertAction(title: "Email", style: .Default, handler: {(action: UIAlertAction!) in
            UIApplication.sharedApplication().openURL(url!);
        });
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {(alert: UIAlertAction!) -> Void in
        });
        
        menu.addAction(sendEmailAction);
        menu.addAction(cancelAction);
        
        presentViewController(menu, animated: true, completion: nil);

    }
    
    @IBAction func cancelAdditionButton(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "toTreeQuestions")
        {
            let dest = segue.destinationViewController as! QuestionsCollectionView
            dest.observation = self.observation;
        }
        if(segue.identifier == "toBirdQuestions")
        {
            
        }
    }
}