//
//  AppDelegate.swift
//  PullToRefreshDemo
//
//  Created by dasdom on 17.01.15.
//  Copyright (c) 2015 Dominik Hauser. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    let swiftViewController = DemoTableViewController()
    swiftViewController.title = "Swift"
    let objcViewController = ObjcTableViewController()
    objcViewController.title = "Objective-C"
    
    let tabBarController = UITabBarController()
    tabBarController.viewControllers = [
      UINavigationController(rootViewController: objcViewController),
      UINavigationController(rootViewController: swiftViewController),
    ]
    
    window?.rootViewController = tabBarController
    window?.makeKeyAndVisible()
    
    return true
  }
}

