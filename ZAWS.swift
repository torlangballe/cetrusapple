//
//  ZAWS.swift
//  capsulefm
//
//  Created by Tor Langballe on /13/6/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation

import AWSCore
import AWSCognito
//import AWSCognitoIdentityUserPool
import AWSS3

class ZAWS {
    init() {
        let credentialsProvider = AWSStaticCredentialsProvider()
        
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionAPSoutheast1
            credentialsProvider:credentialsProvider];
        
        AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;

    }
}
/*
class ZAWS {
    let cognitoPoolId: String

    init() {
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: "d86f18b0-0a9d-42a4-9e74-d0e31131fafe")
        if let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider) {
            AWSServiceManager.default().defaultServiceConfiguration = configuration
            cognitoPoolId = credentialsProvider.identityId ?? ""
        } else {
            cognitoPoolId = ""
        }
    }

    func storeUserInfo(set: String = "default", key:String, value:String) {
        let syncClient = AWSCognito.default()
        
        // Create a record in a dataset and synchronize with the server
        let dataset = syncClient.openOrCreateDataset(set)
        dataset.setString(value, forKey:key)
        dataset.synchronize().continueWith {(task: AWSTask!) -> AnyObject! in
            return nil
        }
    }

    func UploadFileToBucket(_ bucket:String, userName:String, poolId:String = "", file:ZFileUrl, done:@escaping (_ error:ZError?, _ s3url:String)->Void) {
//            let pool = getPool(cognitoPoolId)
//
//            SignInUserToPool(pool, userName:userName) { (error) in
//                if error != nil {
//                    ZAlert.ShowError("Error signing in user to upload", error:error!)
//                    return
//                }

        //        if let uploadRequest = AWSS3TransferManagerUploadRequest() {
            
        let transferUtility = AWSS3TransferUtility.default()
        if let data = ZData.FromUrl(file) {
            let ext = file.Extension
            
            let expression = AWSS3TransferUtilityUploadExpression()
            expression.progressBlock = { (task, progress) in
                ZMainQue.async {
                    print("prog:", progress.fractionCompleted)
                }
            }
            transferUtility.uploadData(
                data,
                bucket: bucket,
                key: ProcessInfo.processInfo.globallyUniqueString + "." + ext,
                contentType: "image/" + ext, // fix!!!!!!!!!
                expression: expression,
                completionHandler: { (task, error) in
                    ZMainQue.async(execute: {
                        if let e = error {
                            ZDebug.Print("Failed with error:", e)
                        } else {
                            print("successes!")
                        }
                    })
                }
            ).continueWith { (task) -> AnyObject! in
                if let error = task.error {
                    print("Error: \(error.localizedDescription)")
                }
                
                if let _ = task.result {
                    print("Upload Starting!")
                    // Do something with uploadTask.
                }
                return nil;
            }
        }
    }
}

func SignInUserToPool(pool:AWSCognitoIdentityUserPool, userName:String, done:(_ error:ZError?)->Void) {
    
    let user = pool.getUser(userName)
    let status = user.confirmedStatus
    if status == .Confirmed {
        done(error:nil)
        return
    }

    let email = AWSCognitoIdentityUserAttributeType()
    email.name = "email"
    email.value = userName
    
    let password = AWSCognitoIdentityUserAttributeType()
    password.name = "password"
    password.value = "pss"
    
    pool.signUp("username", password:"password", userAttributes:[email], validationData:nil).continueWithBlock() { (task) in
        dispatch_async(ZMainQue) { () in
            if task.error == nil {
                if task.result!.userConfirmed! == nil {
                    //need to confirm user using user.confirmUser:
                }
            } else if task.error!.GetTypeString() == "UsernameExistsException" {
                done(error:nil)
                return
            }
            done(error:task.error)
        }
        return nil
    }
}
*/

