//
//  PostsCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import UIKit
import AVFoundation
import ActiveLabel

class PostsCellWithVideo: UITableViewCell {
   
   weak var delegateUserTaps: TappedUserDelegate? // for sending user info
   weak var delegateSpotInfoTaps: TappedSpotInfoDelegate? // when tapping go to spot info from alert
   
   var post: PostItem!
   
   @IBOutlet weak var userPhoto: RoundedImageView!
   @IBOutlet weak var userLoginHeaderButton: UIButton!
   
   @IBOutlet weak var spotPostMediaHeight: NSLayoutConstraint!
   @IBOutlet var spotPostMedia: MediaContainerView!
   var player: AVPlayer!
   
   @IBOutlet weak var postDate: UILabel!
   @IBOutlet weak var postDescription: ActiveLabel! {
      didSet {
         postDescription.numberOfLines = 0
         postDescription.enabledTypes = [.mention, .hashtag, .url]
         postDescription.textColor = .black
         postDescription.mentionColor = .brown
         postDescription.hashtagColor = .purple
         postDescription.handleHashtagTap { hashtag in }
      }
   }
   @IBOutlet weak var isLikedPhoto: UIImageView!
   @IBOutlet weak var likesCount: UILabel!
   @IBOutlet weak var openComments: UIButton!
   
   var postIsLiked: Bool!
   
   var userLikedOrDeletedLike = false //using this to update cache if user liked or disliked post
   
   func initialize(with cachedCell: PostItemCellCache, _ post: PostItem) {
      self.post                 = post
      
      userLoginHeaderButton.setTitle(post.userLogin, for: .normal)
      if post.userProfilePhoto90 != nil {
         userPhoto.kf.setImage(with: URL(string: post.userProfilePhoto90!))
      }
      
      postDate.text        = cachedCell.postDate
      postDescription.text = post.userLogin + " " + post.description
      customizeDescUserLogin()
      
      likesCount.text      = String(describing: cachedCell.likesCount)
      let commentsCount    = String(describing: cachedCell.commentsCount)
      openComments.setTitle("Open commentaries (\(commentsCount))", for: .normal)
      
      postIsLiked          = cachedCell.postIsLiked
      
      isLikedPhoto.image   = cachedCell.isLikedPhoto.image
      
      addDoubleTapGestureOnPostPhotos()
      addDoubleTapGestureOnUserPhoto()
   }
   
   func addDoubleTapGestureOnUserPhoto() {
      let tap = UITapGestureRecognizer(target:self, action:#selector(userInfoTapped))
      tap.numberOfTapsRequired = 1
      userPhoto.addGestureRecognizer(tap)
      userPhoto.isUserInteractionEnabled = true
   }
   
   func addDoubleTapGestureOnPostPhotos() {
      //adding method on spot main photo tap
      let tap = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:))) //target was only self
      tap.numberOfTapsRequired = 2
      spotPostMedia.addGestureRecognizer(tap)
      spotPostMedia.isUserInteractionEnabled = true
      
      let tapOnFist = UITapGestureRecognizer(target:self, action:#selector(postLiked(_:)))
      tapOnFist.numberOfTapsRequired = 1
      isLikedPhoto.addGestureRecognizer(tapOnFist)
      isLikedPhoto.isUserInteractionEnabled = true
   }
   
   func postLiked(_ sender: Any) {
      if (userLikedOrDeletedLike) { // it might be a situation when user liked and disliked posts with out scroll.
         userLikedOrDeletedLike = false
      } else {
         userLikedOrDeletedLike = true
      }
      
      if(!postIsLiked) {
         postIsLiked = true
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! + 1)
         addNewLike()
      } else {
         postIsLiked = false
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         let countOfLikesInt = Int(likesCount.text!)
         likesCount.text = String(countOfLikesInt! - 1)
         removeExistedLike()
      }
   }
   
   func addNewLike() {
      // init new like
      let currentUserId = UserModel.getCurrentUserId()
      let likePlacedTime = String(describing: Date())
      let newLike = LikeItem(who: currentUserId, what: post.key,
                             postWasAddedBy: post.addedByUser, at: likePlacedTime)
      Like.add(newLike)
   }
   
   func removeExistedLike() {
      let currentUserId = UserModel.getCurrentUserId()
      
      Like.remove(with: currentUserId, post)
   }
   
   @IBAction func openAlert(_ sender: UIButton) {
      print("a")
      let alertController = UIAlertController(title: nil, message: "Actions", preferredStyle: .actionSheet)
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
      
      alertController.addAction(cancelAction)
      
      let goToSpotInfoAction = UIAlertAction(title: "Go To Spot Info", style: .default) { action in
         self.goToSpotInfo()
      }
      
      alertController.addAction(goToSpotInfoAction)
      
      let reportAction = UIAlertAction(title: "Report post", style: .destructive) { action in
         self.openReportReasonEnterAlert()
      }
      
      alertController.addAction(reportAction)
      
      parentViewController?.present(alertController, animated: true) // you can see Core/UIViewExtensions
   }
   
   func openReportReasonEnterAlert() {
      let alertController = UIAlertController(title: "Report post", message: "", preferredStyle: .alert)
      
      let saveAction = UIAlertAction(title: "Send", style: .destructive, handler: { alert in
         let reasonTextField = alertController.textFields![0] as UITextField
         UserModel.addReportOnPost(with: self.post.key, reason: reasonTextField.text!)
      })
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .default)
      
      alertController.addTextField { textField in
         textField.placeholder = "Enter reason.."
      }
      
      alertController.addAction(saveAction)
      alertController.addAction(cancelAction)
      
      parentViewController?.present(alertController, animated: true, completion: nil)
   }
   
   @IBAction func userLoginHeaderButtonTapped(_ sender: UIButton) {
      goToUserProfile(tappedUserLogin: post.userLogin)
   }
   
   func userInfoTapped() {
      goToUserProfile(tappedUserLogin: post.userLogin)
   }
   
   // from @username
   private func goToUserProfile(tappedUserLogin: String) {
      UserModel.getItemByLogin(
      for: tappedUserLogin) { fetchedUserItem in
         self.delegateUserTaps?.userInfoTapped(fetchedUserItem)
      }
   }
   
   func goToSpotInfo() {
      delegateSpotInfoTaps?.spotInfoTapped(with: post.spotId)
   }
   
   private func customizeDescUserLogin() {
      postDescription.customize { description in
         //Looks for userItem.login
         let loginTappedType = ActiveType.custom(pattern: "^\(post.userLogin)\\b")
         description.enabledTypes.append(loginTappedType)
         description.handleCustomTap(for: loginTappedType) { login in
            self.userInfoTapped()
         }
         
         description.customColor[loginTappedType] = UIColor.black
         
         postDescription.configureLinkAttribute = { (type, attributes, isSelected) in
            var atts = attributes
            switch type {
            case .custom(pattern: "^\(self.post.userLogin)\\b"):
               atts[NSFontAttributeName] = UIFont(name: "Roboto-Medium", size: 15)
            default: ()
            }
            
            return atts
         }
         
         description.handleMentionTap { mention in // mention is @userLogin
            self.goToUserProfile(tappedUserLogin: mention)
         }
      }
   }
}
