//
//  AppDelegate.swift
//  ShadesApp
//
//  Created by Manuel M T Chakravarty on 02.08.17.
//  Copyright © 2017 Manuel M T Chakravarty. All rights reserved.
//


import Cocoa
import HaskellSpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  override init() {
    hs_init(nil, nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    hs_exit()
  }
}
