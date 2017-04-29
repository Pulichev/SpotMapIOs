//
//  PostsCell.swift
//  RideWorld
//
//  Created by Владислав Пуличев on 23.01.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//
//  Using this class to cache text info from SpotPostCells

import ActiveLabel

class PostItemCellCache {
   var key: String!
   var post: PostItem!
   var userInfo: UserItem!
   var userNickName = String()
   var postDate = String()
   var postTime = String()
   var postDescription = String()
   var isPhoto = Bool()
   var isLikedPhoto = UIImageView()
   var postIsLiked = Bool()
   var likesCount = Int()
   var isCached = false
   
   init(_ post: PostItem, completion: @escaping (_ cellCache: PostItemCellCache) -> Void) {
      key = post.key
      self.post = post
      // formatting date to yyyy-mm-dd
      postDate = DateTimeParser.getDate(from: post.createdDate)
      postTime = DateTimeParser.getTime(from: post.createdDate)
      postDescription = post.description
      isPhoto = post.isPhoto
      initializeUser(completion: {
         self.userLikedThisPost(completion: {
            self.countPostLikes(completion: {
               completion(self)
            })
         })
      })
   }
   
   func initializeUser(completion: @escaping () -> Void) {
      User.getItemById(for: post.addedByUser,
                       completion: { userItem in
                        self.userInfo = userItem
                        self.userNickName = self.userInfo.login
                        completion()
      })
   }
   
   func userLikedThisPost(completion: @escaping () -> Void) {
      Post.isLikedByUser(post.key,
                         completion: { isLiked in
                           if isLiked {
                              self.postIsLiked = true
                              self.isLikedPhoto.image = UIImage(named: "respectActive.png")
                           } else {
                              self.postIsLiked = false
                              self.isLikedPhoto.image = UIImage(named: "respectPassive.png")
                           }
                           completion()
      })
   }
   
   func countPostLikes(completion: @escaping () -> Void) {
      Post.getLikesCount(for: post.key,
                         completion: { countOfPostLikes in
                           self.likesCount = countOfPostLikes
                           completion()
      })
   }
   
   func changeLikeToDislikeAndViceVersa() { //If change = true, User liked. false - disliked
      if (!postIsLiked) {
         postIsLiked = true
         isLikedPhoto.image = UIImage(named: "respectActive.png")
         likesCount += 1
      } else {
         postIsLiked = false
         isLikedPhoto.image = UIImage(named: "respectPassive.png")
         likesCount -= 1
      }
   }
}