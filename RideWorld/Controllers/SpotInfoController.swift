//
//  SpotInfoController.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 30.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import Kingfisher
import SVProgressHUD
import Gallery

class SpotInfoController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
   var spotInfo: SpotItem!
   var user: UserItem!
   
   @IBOutlet weak var photosCollection: UICollectionView!
   
   var photosURLs = [String]()
   
   @IBOutlet weak var name: UILabel!
   @IBOutlet weak var desc: UILabel!
   
   @IBOutlet weak var addedByUser: UIButton!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      name.text = spotInfo.name
      desc.text = spotInfo.description
      
      initializePhotos()
      initUserLabel()
      initFollowButton()
   }
   
   // MARK: - Photo collection part
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return photosURLs.count
   }
   
   func collectionView(_ collectionView: UICollectionView,
                       cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(
         withReuseIdentifier: "ImageCollectionViewCell", for: indexPath as IndexPath)
         as! ImageCollectionViewCell
      let photoURL = URL(string: photosURLs[indexPath.row])
      cell.postPicture.kf.setImage(with: photoURL!)
      
      return cell
   }
   
   private func initializePhotos() {
      self.photosURLs.append(self.spotInfo.mainPhotoRef)
      Spot.getAllPhotosURLs(for: spotInfo.key) { photoURLs in
         self.photosURLs.append(contentsOf: photoURLs)
         self.photosCollection.reloadData()
      }
   }
   
   // MARK: - initialize user
   private func initUserLabel() {
      UserModel.getItemById(for: spotInfo.addedByUser) { user in
         self.user = user
         self.addedByUser.setTitle(user.login, for: .normal)
      }
   }
   
   @IBAction func userButtonTapped(_ sender: Any) {
      if user.uid == UserModel.getCurrentUserId() {
         self.performSegue(withIdentifier: "goToUserProfileFromSpotInfo", sender: self)
      } else {
         self.performSegue(withIdentifier: "goToRidersProfileFromSpotInfo", sender: self)
      }
   }
   
   //MARK: - follow part
   @IBOutlet weak var followSpotButton: UIBarButtonItem!
   
   private func initFollowButton() {
      UserModel.isCurrentUserFollowingSpot(with: spotInfo.key) { isFollowing in
         if isFollowing {
            self.followSpotButton.title = "Following"
         } else {
            self.followSpotButton.title = "Follow"
         }
         
         self.followSpotButton.isEnabled = true
      }
   }
   
   @IBAction func followSpotButtonTapped(_ sender: Any) {
      if followSpotButton.title == "Follow" { // add or remove like
         UserModel.addFollowingToSpot(with: spotInfo.key)
      } else {
         UserModel.removeFollowingToSpot(with: spotInfo.key)
      }
      
      swapFollowButtonTittle()
   }
   
   private func swapFollowButtonTittle() {
      if followSpotButton.title == "Follow" {
         followSpotButton.title = "Following"
      } else {
         followSpotButton.title = "Follow"
      }
   }
   
   @IBAction func goToPostsButtonTapped(_ sender: UIButton) {
      performSegue(withIdentifier: "fromSpotInfoToSpotPosts", sender: self)
   }
   
   // MARK: - prepare for segue
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      switch segue.identifier! {
      case "goToRidersProfileFromSpotInfo":
         let newRidersProfileController = segue.destination as! RidersProfileController
         newRidersProfileController.ridersInfo = user
         newRidersProfileController.title = user.login
         
      case "goToUserProfileFromSpotInfo":
         let userProfileController = segue.destination as! UserProfileController
         userProfileController.cameFromSpotDetails = true
         
      case "fromSpotInfoToSpotPosts":
         let postsStripController = segue.destination as! PostsStripController
         postsStripController.spotDetailsItem = spotInfo
         postsStripController.cameFromSpotOrMyStrip = true // came from spot
         
      default: break
      }
   }
}

// MARK: - Camera extension
extension SpotInfoController : GalleryControllerDelegate {
   
   @IBAction func addPhotoButtonTapped(_ sender: Any) {
      let gallery = GalleryController()
      gallery.delegate = self
      
      Config.Camera.imageLimit = 1
      Config.showsVideoTab = false
      
      present(gallery, animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectImages images: [UIImage]) {
      let img = images[0]
      
      SVProgressHUD.show()
      SpotMedia.uploadForInfo(img, for: self.spotInfo.key, with: 270.0) { url in
         if url != nil {
            self.photosURLs.append(url!)
            
            self.photosCollection.reloadData()
         }
         
         SVProgressHUD.dismiss()
      }
      
      controller.dismiss(animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
   }
   
   func galleryController(_ controller: GalleryController, requestLightbox images: [UIImage]) {
   }
   
   func galleryControllerDidCancel(_ controller: GalleryController) {
      controller.dismiss(animated: true, completion: nil)
   }
}
