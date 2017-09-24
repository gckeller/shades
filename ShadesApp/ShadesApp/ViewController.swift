//
//  ViewController.swift
//  ShadesApp
//
//  Created by Manuel M T Chakravarty on 02.08.17.
//  Copyright © 2017 Manuel M T Chakravarty. All rights reserved.
//

import Cocoa
import SpriteKit
import GameplayKit

class ViewController: NSViewController {

  @IBOutlet var skView: SKView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    if let view = self.skView {

        // Grab the SpriteKit scene defined in Haskell and present it in this SpriteKit view.
      if let scene = game_scene() as? SKScene {

          // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFit
        
          // Present the scene
        view.presentScene(scene)

        view.setFrameSize(NSSize(width: 50, height: 50))
        view.needsDisplay = true
      }

      view.ignoresSiblingOrder = true
      
      view.showsFPS = true
      view.showsNodeCount = true
    }
  }
}

