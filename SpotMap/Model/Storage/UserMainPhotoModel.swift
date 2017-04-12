//
//  UserMainPhotoModel.swift
//  SpotMap
//
//  Created by Владислав Пуличев on 12.04.17.
//  Copyright © 2017 Владислав Пуличев. All rights reserved.
//

import FirebaseStorage

class UserMainPhotoModel {
    static func uploadUserMainPhoto(userId: String, image: UIImage, sizePx: Double) {
        let resizedPhoto = ImageManipulations.resize(image: image, targetSize: CGSize(width: sizePx, height: sizePx))
        let sizePxString = String(describing: sizePx)
        let userPhotoRef = FIRStorage.storage().reference(withPath: "media/userMainPhotoURLs").child(userId + "_resolution" + sizePxString + "x" + sizePxString + ".jpeg")
        //with low compression
        let dataLowCompressionFor: Data = UIImageJPEGRepresentation(resizedPhoto, 0.8)!
        userPhotoRef.put(dataLowCompressionFor)
    }
}
