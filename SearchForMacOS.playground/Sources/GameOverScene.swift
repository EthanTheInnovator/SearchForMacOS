//
//  GameOverScene.swift
//  SearchForMacOS
//
//  Created by Ethan Humphrey on 3/31/18.
//  Copyright © 2018 Ethan Humphrey. All rights reserved.
//

import SpriteKit
import GameplayKit
import Cocoa

public class GameOverScene: SKScene {
    
    var macSprite: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var nameLabel: SKLabelNode!
    
    let macOSNames = ["Joshua Tree", "Redwood", "Alcatraz", "Golden Gate", "Sturtevant", "Tahoe", "Sequoia", "Death Valley", "Balboa", "Oxnard", "Rancho Cucamonga", "Hollywood", "Weed", "Monterey", "Santa Cruz", "Julian", "Napa", "Pfeiffer", "McWay"]
    
    override public func sceneDidLoad() {
        //Find the Mac Icon Node
        guard let macSprite = childNode(withName: "macSprite") as? SKSpriteNode else {
            fatalError("Mac node not loaded")
        }
        self.macSprite = macSprite
        
        //Find the Score Label Node
        guard let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode else {
            fatalError("Score node not loaded")
        }
        self.scoreLabel = scoreLabel
        
        //Find the macOS Name Label Node
        guard let nameLabel = childNode(withName: "nameLabel") as? SKLabelNode else {
            fatalError("Name node not loaded")
        }
        self.nameLabel = nameLabel
    }
    
    public func setScore(score: Int) {
        self.scoreLabel.text = String(score)
        //Pick a name for the next macOS based on the score of the user
        let nameIndex = score % macOSNames.count
        self.nameLabel.text = "macOS " + macOSNames[nameIndex]
        let latestSoundAction = SKAction.playSoundFileNamed("craigLatestOSX.mov", waitForCompletion: true)
        var knownNameAction: SKAction!
        //Check if there is a Craig saying for this version
        switch macOSNames[nameIndex] {
        case "Oxnard":
            knownNameAction = SKAction.playSoundFileNamed("craigOxnard.mov", waitForCompletion: true)
        case "Rancho Cucamonga":
            knownNameAction = SKAction.playSoundFileNamed("craigRancho.mov", waitForCompletion: true)
        case "Weed":
            knownNameAction = SKAction.playSoundFileNamed("craigWeed.mov", waitForCompletion: true)
        default:
            break
        }
        if knownNameAction != nil {
            run(SKAction.sequence([latestSoundAction, knownNameAction]))
        }
        else {
            run(latestSoundAction)
        }
    }
    
    override public func mouseUp(with theEvent: NSEvent) {
        //Restart the game if clicked
        if let scene = GameScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFit
            self.scene?.view?.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.3))
        }
    }

}
