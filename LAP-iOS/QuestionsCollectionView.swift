//
//  QuestionsCollectionView.swift
//  LAP-iOS
//
//  Created by kevin on 1/26/16.
//  Copyright © 2016 Kevin Argumedo. All rights reserved.
//

import Foundation
import UIKit
import Heimdallr
import Alamofire

class QuestionsCollectionView : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    var questionsObject = [JSON]()
    var questions = [String]();
    var selected = [Bool]();
    var selectedInts = [String]()
    var image : UIImage!;
    var birdsPerched = [JSON]()
    var observation: Observation!;
    
    @IBOutlet weak var doneButton: UIBarButtonItem!

    @IBOutlet weak var bottomBar: UINavigationItem!
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidAppear(animated: Bool) {
        if(self.image != nil){
            self.doneButton.enabled = true;
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let logo = UIImage(named: "topbaricon")
        let imageView = UIImageView(image:logo)
        self.bottomBar.titleView = imageView;
        collectionView.allowsSelection = true
        let url = NSURL(string: "http://isitso.pythonanywhere.com/questions/")
        let request = NSURLRequest(URL: url!)
        
        if(self.observation.isUpdate == true){
            self.doneButton.enabled = true;
        }
        else{
            self.doneButton.enabled = false;
        }
        
        self.observation.heimdallr.self.authenticateRequest(request)
            { (result) in
                switch result {
                case .Success:
                    let parameters  = ["access_token": self.observation.ats.retrieveAccessToken()!.accessToken]
                    
                    Alamofire.request(.GET, "http://isitso.pythonanywhere.com/questions/", parameters: parameters)
                        .responseJSON { response in
                            
                            if let JSON1 = response.result.value
                            {
                                for(_,jso) in JSON(JSON1)
                                {
                                    self.questionsObject.append(jso)
                                    self.selected.append(false)
                                    
                                    var temp : JSON = jso
                                    self.questions.append(String(temp["text"]))
                                }
                                
                                print(self.questionsObject)
                                
                            }
                            dispatch_async(dispatch_get_main_queue()) {
                                self.collectionView.reloadData()
                            }
                    }
                case .Failure:
                    print("Failed")
                }
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.questionsObject.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
            as! QuestionCell
        
        cell.textDisplay.text = String(self.questionsObject[indexPath.row]["text"])
        
        cell.textDisplay.editable = false
        cell.textDisplay.userInteractionEnabled = false
        cell.checked = selected[indexPath.row]
        
        if(cell.checked!)
        {
            cell.checkedButton.setImage(UIImage(named:"checkedMark.png"), forState: UIControlState.Normal)
        }
        else
        {
            cell.checkedButton.setImage(UIImage(named:"checkMark.png"), forState: UIControlState.Normal)
        }
        
        cell.checkedButton?.layer.setValue(indexPath, forKey: "sendIndex")
        cell.checkedButton?.layer.setValue(cell, forKey: "sendCell")
        cell.checkedButton?.addTarget(self, action: #selector(QuestionsCollectionView.checkMark(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        return cell
    }
    
    
        
    func checkMark(sender:UIButton)
    {
        
        let cell = sender.layer.valueForKey("sendCell") as! QuestionCell
        let index = sender.layer.valueForKey("sendIndex") as! NSIndexPath
        if(cell.checked!)
        {
            self.selected[index.row] = false
        }
        else
        {
            self.selected[index.row] = true
        }
        
        self.collectionView.reloadData()
    }
    
    @IBAction func postObservation(sender: AnyObject)
    {
        if(self.image == nil && self.observation.isUpdate == false)
        {
            self.displayMessage("You must take a picture before attempting to upload")
            return
        }
        
        let uploadChecked = NSMutableData()
        
        for i in 0...self.questionsObject.count-1
        {
            for (_,choice) in self.questionsObject[i]["choices"]
            {
                if(selected[i])
                {
                    if(String(choice["value"]).lowercaseString == "true")
                    {
                        self.selectedInts.append(String(choice["id"]))
                    }
                }
                else{
                    if(String(choice["value"]).lowercaseString == "false")
                    {
                        self.selectedInts.append(String(choice["id"]))
                    }
                }
            }
        }
        
        let spaghettipizza = [0]
        
        for string in self.selectedInts                            {
            if let stringData = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            {
                uploadChecked.appendData(stringData)
                uploadChecked.appendBytes(spaghettipizza, length: 1)
                
            } else {
                NSLog("Uh oh, trouble!")
            }
        }
        
        if(self.observation.isUpdate == false)
        {
            let treeLong = String(self.observation.treeLocation.longitude);
            let treeLat = String(self.observation.treeLocation.latitude);
            Alamofire.upload(
                .POST,
                "http://isitso.pythonanywhere.com/trees/",
                multipartFormData: {
                    multipartFormData in
                    multipartFormData.appendBodyPart(data: treeLong.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "long")
                    multipartFormData.appendBodyPart(data:
                        treeLat.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "lat")
                    multipartFormData.appendBodyPart(data: String(self.observation.specie["id"]).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "species")
                    
                },
                encodingCompletion: {
                    encodingResult in
                    switch encodingResult {
                    case .Success(let upload, _, _ ):
                        upload.responseJSON { response in
                            
                            var tempObject = JSON(response.result.value!)

                            
                            Alamofire.upload(
                                .POST,
                                "http://isitso.pythonanywhere.com/dailyupdates/",
                                multipartFormData: {
                                    multipartFormData in
                                    multipartFormData.appendBodyPart(data: String(tempObject["id"]).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "tree")
                                    
                                    for object in self.selectedInts
                                    {
                                        multipartFormData.appendBodyPart(data: String(object).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "choices")
                                    }
                                
                                    multipartFormData.appendBodyPart(data: UIImageJPEGRepresentation(self.image, 0.5)!, name: "image", fileName: "tree.jpg", mimeType: "image/jpg")

                                    if(self.birdsPerched.count != 0)
                                    {
                                        for object in self.birdsPerched{
                                            multipartFormData.appendBodyPart(data: String(object["id"]).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "birds")
                                        }
                                        
                                    }
                                
                                },
                                encodingCompletion: {
                                    encodingResult in
                                    switch encodingResult {
                                    case .Success(let upload, _, _ ):
                                        upload.responseJSON { response in
                                            print("-------------")
                                            print(response)
                                        }
                                    case .Failure(let encodingError):
                                        print("Failure")
                                        print(encodingError)
                                    }
                                }
                            )
                            
                            let actionSheetController: UIAlertController = UIAlertController(title: "Alert", message: "The tree has been added.", preferredStyle: .Alert)
                            
                            
                            let nextAction: UIAlertAction = UIAlertAction(title: "OK", style: .Default)
                                { action -> Void in
                                    
                                    self.performSegueWithIdentifier("toMap", sender: self)
                                }
                            
                            actionSheetController.addAction(nextAction)
                            
                            
                            self.presentViewController(actionSheetController, animated: true, completion: nil)

                        }
                    case .Failure(let encodingError):
                        print("Failure")
                        print(encodingError)
                    }
                }
            )
        }
        
        if((self.observation.isUpdate))
        {
            if(self.observation.isUpdate == true)
            {
                Alamofire.upload(
                    .POST,
                    "http://isitso.pythonanywhere.com/dailyupdates/",
                    multipartFormData: {
                        multipartFormData in
                        print(self.observation.specie)
                        multipartFormData.appendBodyPart(data: String(self.observation.specie["treeID"]).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "tree")
                        
                        for object in self.selectedInts
                        {
                            multipartFormData.appendBodyPart(data: String(object).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "choices")
                        }
                        
                        if(self.image != nil)
                        {
                            multipartFormData.appendBodyPart(data: UIImageJPEGRepresentation(self.image, 0.5)!, name: "image", fileName: "tree.jpg", mimeType: "image/jpg")
                        }
                        
                        if(self.birdsPerched.count != 0)
                        {
                            for object in self.birdsPerched{
                                multipartFormData.appendBodyPart(data: String(object["id"]).dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, name: "birds")
                            }

                        }
                        
                    },
                    encodingCompletion: {
                        encodingResult in
                        switch encodingResult {
                        case .Success(let upload, _, _ ):
                            upload.responseJSON { response in
                            }
                        case .Failure(let encodingError):
                            print("Failure")
                            print(encodingError)
                        }
                    }
                )
            }
            
            let actionSheetController: UIAlertController = UIAlertController(title: "Alert", message: "The tree has been updated.", preferredStyle: .Alert)
            
            
            let nextAction: UIAlertAction = UIAlertAction(title: "OK", style: .Default)
                { action -> Void in
                    
                    self.performSegueWithIdentifier("toMap", sender: self)
            }
            
            actionSheetController.addAction(nextAction)
            
            
            self.presentViewController(actionSheetController, animated: true, completion: nil)

        }
    }
    
    @IBAction func takePicture(sender: AnyObject)
    {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .Camera
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        self.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        self.image = resizeImage(self.image, newWidth: 600);
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    func displayMessage(message: String){
        let myAlert = UIAlertController(title:"Alert", message:message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        myAlert.addAction(okAction);
        self.presentViewController(myAlert, animated:true, completion: nil);
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "toMap")
        {
            let navDest = segue.destinationViewController as! UINavigationController
            
            let heim = navDest.viewControllers.first as! MapViewController
            heim.heimdallr = self.observation.heimdallr;
            heim.ats = self.observation.ats;
            
        }
        
        if(segue.identifier == "toBirdList"){
            let heim = segue.destinationViewController as! BirdQuestionCollection
            heim.observation = self.observation;
        }

    }
    
    
    @IBAction func cancelAdditionButton(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func doneButton(segue: UIStoryboardSegue) {
        if let birdCollection = segue.sourceViewController as? BirdQuestionCollection
        {            
            self.birdsPerched = birdCollection.birdsPerched
        }
    }
}