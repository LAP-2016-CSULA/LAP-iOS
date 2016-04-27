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
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet weak var bottomBar: UINavigationItem!
//    @IBOutlet weak var name: UILabel!
    @IBOutlet var nextButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        title = "Specie";
        let logo = UIImage(named: "topbaricon");
        let imageView = UIImageView(image:logo);
        self.bottomBar.titleView = imageView;
        
        let URL = NSURL(string: String(self.observation.specie["image"]))!
        let resource = Resource(downloadURL: URL, cacheKey: String(self.observation.specie["image"]))
        
        self.imageView.layer.borderWidth = 1;
        self.imageView.layer.borderColor = UIColor(red: 187.0, green: 226.0, blue: 188.0, alpha: 1.0).CGColor;

        self.imageView.kf_setImageWithResource(resource, placeholderImage: nil,
            optionsInfo: [.Transition(ImageTransition.Fade(1))])
        
//        self.name.text = String(self.observation.specie["name"])
        title = String(self.observation.specie["name"]);
        
        //does not allow text view to be edited.
        textView.editable = false
        
        textView.layer.borderWidth = 1;
        textView.layer.borderColor = UIColor(red: 187.0, green: 226.0, blue: 188.0, alpha: 1.0).CGColor;
        
        //sets description on specie from API
        textView.text = String(self.observation.specie["description"]);
        
        if(observation.viewOnly == true){
            nextButton.enabled = false;
            nextButton.tintColor = UIColor.clearColor();
        }
        if(observation.guest == true){
            nextButton.enabled = false;
            nextButton.tintColor = UIColor.clearColor();
        }
        
    }
    
    @IBAction func toQuestions(sender: AnyObject)
    {
        if(String(self.observation.specie["type"]["id"]) == "1")
        {
            performSegueWithIdentifier("toTreeQuestions", sender: self)
        }
        
        if(String(self.observation.specie["type"]["id"]) == "2")
        {
            performSegueWithIdentifier("toBirdQuestions", sender: self)
        }
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