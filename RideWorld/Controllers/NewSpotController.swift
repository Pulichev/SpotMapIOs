//
//  CameraRollController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 21.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Fusuma
import SVProgressHUD

class NewSpotController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
   var spotLatitude: Double!
   var spotLongitude: Double!
   
   @IBOutlet weak var spotTitle: UITextField!
   @IBOutlet var spotDescription: UITextView! {
      didSet {
         spotDescription.layer.borderColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
         spotDescription.layer.borderWidth = 1.0
         spotDescription.layer.cornerRadius = 5
      }
   }
   
   @IBOutlet weak var imageView: UIImageView!
   
   override func viewDidLoad() {
      UICustomizing()
      
      spotTitle.delegate = self
      spotDescription.delegate = self
      
      //For scrolling the view if keyboard on
      NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillShow),
                                             name: NSNotification.Name.UIKeyboardWillShow, object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(NewSpotController.keyboardWillHide),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
   }
   
   func UICustomizing() {
      //adding method on spot main photo tap
      addGestureToOpenCameraOnPhotoTap()
      imageView.image = UIImage(named: "plus-512.gif") //Setting default picture
   }
   
   func addGestureToOpenCameraOnPhotoTap() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(takePhoto(_:)))
      imageView.addGestureRecognizer(tap)
      imageView.isUserInteractionEnabled = true
   }
   
   @IBAction func saveSpotDetails(_ sender: Any) {
      SVProgressHUD.show()
      enableUserTouches = false
      
      let newSpotKey = Spot.getNewSpotRefKey()
      
      // something like transaction. Start saving new
      // spot info only after media has beed uploaded
      SpotMedia.upload(imageView.image!, for: newSpotKey, with: 270.0,
                       completion: { isSuccessfully in
                        if isSuccessfully {
                           Spot.create(with: self.spotTitle.text!,
                                       self.spotDescription.text!,
                                       self.spotLatitude,
                                       self.spotLongitude,
                                       newSpotKey,
                                       completion: { hasAddedSpotSuccessfully in
                                          if hasAddedSpotSuccessfully {
                                             //saving image to camera roll
                                             UIImageWriteToSavedPhotosAlbum(self.imageView.image!, nil, nil , nil)
                                             SVProgressHUD.dismiss()
                                             self.enableUserTouches = true
                                             //go back
                                             _ = self.navigationController?.popViewController(animated: true)
                                          } else {
                                             SVProgressHUD.dismiss()
                                             self.enableUserTouches = true
                                             self.showAlertThatErrorInNewSpot()
                                          }
                           })
                        } else {
                           SVProgressHUD.dismiss()
                           self.enableUserTouches = true
                           self.showAlertThatErrorInNewSpot()
                        }
      })
   }
   
   private func showAlertThatErrorInNewSpot() {
      let alert = UIAlertController(title: "Creating new spot failed!", message: "Some error happened in new spot creating.", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
      
      present(alert, animated: true, completion: nil)
   }
   
   var enableUserTouches = true {
      didSet {
         if enableUserTouches {
            navigationController?.navigationBar.isUserInteractionEnabled = true
            navigationItem.hidesBackButton = false
         } else {
            navigationController?.navigationBar.isUserInteractionEnabled = false
            navigationItem.hidesBackButton = true
         }
      }
   }// for disabling user touches, while uploading
   
   var keyBoardAlreadyShowed = false //using this to not let app to scroll view. Look at extension
}

//MARK: - Fusuma delegate
extension NewSpotController: FusumaDelegate {
   @IBAction func takePhoto(_ sender: Any) {
      let fusuma = FusumaViewController()
      fusuma.delegate = self
      fusuma.hasVideo = false // If you want to let the users allow to use video.
      present(fusuma, animated: true, completion: nil)
   }
   
   // MARK: FusumaDelegate Protocol
   func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
      switch source {
      case .camera:
         print("Image captured from Camera")
      case .library:
         print("Image selected from Camera Roll")
      default:
         print("Image selected")
      }
      
      imageView.image = image
      imageView.layer.cornerRadius = imageView.frame.size.height / 8
      imageView.layer.masksToBounds = true
      imageView.layer.borderWidth = 0
   }
   
   func fusumaImageSelected(_ image: UIImage) {
      //look example on https://github.com/ytakzk/Fusuma
   }
   
   func fusumaVideoCompleted(withFileURL fileURL: URL) {
      //If u want to use video in future - add code here. You can watch code in NewPostController.swift
   }
   
   func fusumaDismissedWithImage(_ image: UIImage, source: FusumaMode) {
      switch source {
      case .camera:
         print("Called just after dismissed FusumaViewController using Camera")
      case .library:
         print("Called just after dismissed FusumaViewController using Camera Roll")
      default:
         print("Called just after dismissed FusumaViewController")
      }
   }
   
   func fusumaCameraRollUnauthorized() {
      
      print("Camera roll unauthorized")
      
      let alert = UIAlertController(title: "Access Requested", message: "Saving image needs to access your photo album", preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { (action) -> Void in
         
         if let url = URL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(url)
         }
         
      }))
      
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
         
      }))
      
      present(alert, animated: true, completion: nil)
   }
   
   func fusumaClosed() {
      print("Called when the FusumaViewController disappeared")
   }
   
   func fusumaWillClosed() {
      print("Called when the close button is pressed")
   }
}

// MARK: - Scroll view on keyboard show/hide
extension NewSpotController {
   //if we tapped UITextField and then another UITextField
   func keyboardWillShow(notification: NSNotification) {
      if !keyBoardAlreadyShowed {
         view.frame.origin.y -= 200
         keyBoardAlreadyShowed = true
      }
   }
   
   func keyboardWillHide(notification: NSNotification) {
      view.frame.origin.y += 200
      keyBoardAlreadyShowed = false
   }
   
   override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      for touch: AnyObject in touches {
         if !enableUserTouches {
            touch.view.isUserInteractionEnabled = false
         } else {
            touch.view.isUserInteractionEnabled = true
         }
      }
      
      view.endEditing(true)
   }
}

