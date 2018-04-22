//
//  StartScene.swift
//  SearchForMacOS
//
//  Created by Ethan Humphrey on 3/31/18.
//  Copyright © 2018 Ethan Humphrey. All rights reserved.
//

import SpriteKit
import GameplayKit
import Cocoa

public class StartScene: SKScene {
    
    var macSprite: SKSpriteNode!
    
    override public func sceneDidLoad() {
        //Find the Mac Node
        guard let macSprite = childNode(withName: "macSprite") as? SKSpriteNode else {
            fatalError("Mac node not loaded")
        }
        self.macSprite = macSprite
    }
    
    override public func mouseUp(with theEvent: NSEvent) {
        //Start the game when clicked
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFit
            self.scene?.view?.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.3))
        }
    }

}
