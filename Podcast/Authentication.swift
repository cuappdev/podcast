//
//  Authentication.swift
//  Podcast
//
//  Created by Natasha Armbrust on 12/15/17.
//  Copyright © 2017 Cornell App Development. All rights reserved.
//

import Foundation
import FacebookLogin
import FacebookCore

class Authentication: NSObject, GIDSignInDelegate {

    static var sharedInstance = Authentication()
    var facebookLoginManager: LoginManager!
    var isMergingGoogleAccount: Bool = false

    var facebookAccessToken: String? {
        get {
            return AccessToken.current?.authenticationToken
        }
    }

    var googleAccessToken: String? {
        get {
            return GIDSignIn.sharedInstance().currentUser?.authentication.accessToken
        }
    }

    override init() {
        super.init()
        GIDSignIn.sharedInstance().clientID = "724742275706-h8qs46h90squts3dco76p0q6lja2c7nh.apps.googleusercontent.com"

        let profileScope = "https://www.googleapis.com/auth/userinfo.profile"
        let emailScope = "https://www.googleapis.com/auth/userinfo.email"

        GIDSignIn.sharedInstance().scopes.append(contentsOf: [profileScope, emailScope])
        facebookLoginManager = LoginManager()
        GIDSignIn.sharedInstance().delegate = self
    }

    func signInWithFacebook(viewController: UIViewController, success: (() -> ())? = nil, failure: (() -> ())? = nil) {
        facebookLoginManager.logIn(readPermissions: [.publicProfile, .email, .userFriends], viewController: viewController) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
                failure?()
            case .cancelled:
                print("User cancelled login.")
                failure?()
            case .success(_):
                success?()
            }
        }
    }

    func signInSilentlyWithGoogle() {
         GIDSignIn.sharedInstance().signInSilently()
    }
    
    func signInWithGoogle() {
        GIDSignIn.sharedInstance().signIn()
    }

    func logout() {
        GIDSignIn.sharedInstance().signOut()
        facebookLoginManager.logOut()
    }

    // Google sign in functionality
    func handleSignIn(url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplicationOpenURLOptionsKey.annotation])
    }

    // delegate method for Google sign in - called when sign in is comeplete
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let window = UIApplication.shared.delegate?.window as? UIWindow, let navigationController = window.rootViewController as? UINavigationController, let viewController = navigationController.viewControllers.first as? LoginViewController {
            viewController.signInWithGoogle(wasSuccessful: error == nil, accessToken: Authentication.sharedInstance.googleAccessToken)
        } else {
            if error == nil {
                Authentication.sharedInstance.mergeAccounts(signInTypeToMergeIn: .Google, success: { _,_,_ in
                    UserSettings.mainSettingsPage.navigationController?.popToRootViewController(animated: false)}
                , failure: { UserSettings.mainSettingsPage.navigationController?.popToRootViewController(animated: false) })

            }
        }
    }

    func mergeAccounts(signInTypeToMergeIn: SignInType, success: ((User, Session, Bool) -> ())? = nil, failure: (() -> ())? = nil) {
        var accessToken: String = ""
        switch signInTypeToMergeIn {
        case .Google:
             guard let token = Authentication.sharedInstance.googleAccessToken else { return } // Safe to send to the server
            accessToken = token
        case .Facebook:
             guard let token = Authentication.sharedInstance.facebookAccessToken else { return } // Safe to send to the server
             accessToken = token
        }
        let endpointRequest = MergeUserAccuntsEndpointRequest(signInType: signInTypeToMergeIn, accessToken: accessToken)
        endpointRequest.success = { request in
            guard let result = request.processedResponseValue as? [String: Any],
                let user = result["user"] as? User, let session = result["session"] as? Session, let isNewUser = result["is_new_user"] as? Bool else {
                    print("error authenticating")
                    failure?()
                    return
            }
            System.currentUser = user
            System.currentSession = session
            success?(user, session, isNewUser)
        }

        endpointRequest.failure = { _ in
            failure?()
        }

        System.endpointRequestQueue.addOperation(endpointRequest)
    }

    // authenticates the user and executes success block if valid user, else executes failure block
    func authenticateUser(signInType: SignInType, accessToken: String, success: ((User, Session, Bool) -> ())? = nil, failure: (() -> ())? = nil) {
        let authenticateUserEndpointRequest = AuthenticateUserEndpointRequest(signInType: signInType, accessToken: accessToken)

        authenticateUserEndpointRequest.success = { (endpointRequest: EndpointRequest) in
            guard let result = endpointRequest.processedResponseValue as? [String: Any],
                let user = result["user"] as? User, let session = result["session"] as? Session, let isNewUser = result["is_new_user"] as? Bool else {
                    print("error authenticating")
                    failure?()
                    return
            }
            System.currentUser = user
            System.currentSession = session
            success?(user, session, isNewUser)
        }

        authenticateUserEndpointRequest.failure = { (endpointRequest: EndpointRequest) in
            failure?()
        }

        System.endpointRequestQueue.addOperation(authenticateUserEndpointRequest)
    }
}
