//
//  GameScene.swift
//  SearchForMacOS
//
//  Created by Ethan Humphrey on 3/22/18.
//  Copyright © 2018 Ethan Humphrey. All rights reserved.
//

import SpriteKit
import GameplayKit
import Cocoa

// MARK: - Structs
//Categories for collision detection
struct CollisionCategory {
    static let None: UInt32 = 0
    static let All: UInt32 = UInt32.max
    static let Player: UInt32 = UInt32(1)
    static let Window: UInt32 = UInt32(2)
    static let SideBorder: UInt32 = UInt32(4)
    static let GoodItem: UInt32 = UInt32(8)
    static let BadItem: UInt32 = UInt32(16)
    static let BottomBorder: UInt32 = UInt32(32)
    static let MavericksPowerUp: UInt32 = UInt32(64)
    static let YosemitePowerUp: UInt32 = UInt32(128)
    static let CapitanPowerUp: UInt32 = UInt32(256)
}

//Different Types of Items
struct ItemType {
    static let None: Int = 0
    static let Good: Int = 1
    static let Bad: Int = 2
    static let PowerUp: Int = 3
}

//Different Types of Power Ups
struct PowerUpTypes {
    static let Mavericks: Int = 0 //Double Points
    static let Yosemite: Int = 1 //Invincibility
    static let Capitan: Int = 2 //Extra Life
}

// MARK: - Game
public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Nodes
    var player: SKSpriteNode!
    var collidingWindow: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var doubleIndicator: SKLabelNode!
    var batteryNode: SKSpriteNode!
    var gameNode: SKNode!

    // MARK: - Dynamic
    let windows = ["calculatorWindow", "puzzleWindow", "finderWindow", "controlsWindow", "mapWindow", "memoryWindow", "soundWindow", "viewsWindow"]
    let goodItems = ["saveIcon", "commandIcon", "paintIcon", "pencilIcon", "happyMac"]
    let badItems = ["watchIcon", "trashIcon", "bombIcon", "errorMac"]
    let powerUpItems = ["mavericks", "yosemite", "capitan"]
    let randomCraigSayings = ["craigAudioUnknown.mp3", "craigGraphics.mp3", "craigInnovation.mov", "craigeSmoothScrolling.mp3", "craigTraining.mp3", "craigVirtualCows.mp3"]
    var trashItems: Array<SKSpriteNode> = []
    
    // MARK: - Constants
    let minJumpForce: CGFloat = 500.0
    let maxJumpForce: CGFloat = 800.0
    let windowSpeed: CGFloat = 400.0
    let powerUpDuration = 7.0
    let timeBetweenSayings = 10.0
    
    // MARK: - Player Variables
    var lives = 3
    var score = 0.0
    var jumpForce: CGFloat = 0.0
    var isOnGround = true
    var isCollidingWithWindow = false
    
    // MARK: - Power Up Variables
    var isMavericksActive = false
    var isYosemiteActive = false
    var isCapitanActive = false
    
    // MARK: - Time Variables
    var lastTime: TimeInterval = 0
    var currentTime: TimeInterval = 0.0
    var nextWindowWaitDuration = 1.0
    var lastWindowSpawn = 0.0
    var lastPowerUpTime: TimeInterval = 0.0
    var lastCraigSaying: TimeInterval = 0.0
    
    // MARK: - Overrides
    override public func sceneDidLoad() {
        //Load Main Game Node
        guard let gameNode = childNode(withName: "gameNode") else {
            fatalError("Game node not loaded")
        }
        self.gameNode = gameNode
        
        //Load Player Node
        guard let player = gameNode.childNode(withName: "player") as? SKSpriteNode else {
            fatalError("Player node not loaded")
        }
        self.player = player
        player.zPosition = 5 //Set Z Position of Player (Above everything but score and battery)
        
        //Load Score Label
        guard let scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode else {
            fatalError("Score node not loaded")
        }
        self.scoreLabel = scoreLabel
        scoreLabel.zPosition = 6 //Set Z Position of Score Label (Above everything)
        
        //Load Battery/Lives Node
        guard let batteryNode = childNode(withName: "batteryNode") as? SKSpriteNode else {
            fatalError("Battery node not loaded")
        }
        self.batteryNode = batteryNode
        batteryNode.zPosition = 6 //Set Z Position of Battery Node (Above everything)
        
        //Load Mavericks Power Up Indicator
        guard let doubleIndicator = childNode(withName: "doubleIndicator") as? SKLabelNode else {
            fatalError("Score node not loaded")
        }
        self.doubleIndicator = doubleIndicator
        doubleIndicator.zPosition = 6 //Set Z Position (Above everything)
        doubleIndicator.isHidden = true
        
        //Load Invisible Barriers
        guard let gravityBarrier = childNode(withName: "gravityBarrier")
            as? SKSpriteNode else {
                fatalError("Barrier node not loaded")
        }
        
        guard let leftGravityBarrier = childNode(withName: "leftGravityBarrier")
            as? SKSpriteNode else {
                fatalError("Barrier node not loaded")
        }
        
        guard let rightGravityBarrier = childNode(withName: "rightGravityBarrier")
            as? SKSpriteNode else {
                fatalError("Barrier node not loaded")
        }
        
        //Set Physics Bodies for Borders
        leftGravityBarrier.physicsBody = SKPhysicsBody(rectangleOf: leftGravityBarrier.size)
        leftGravityBarrier.physicsBody?.isDynamic = false
        leftGravityBarrier.physicsBody?.categoryBitMask = CollisionCategory.SideBorder
        rightGravityBarrier.physicsBody = SKPhysicsBody(rectangleOf: rightGravityBarrier.size)
        rightGravityBarrier.physicsBody?.isDynamic = false
        rightGravityBarrier.physicsBody?.categoryBitMask = CollisionCategory.SideBorder
        
        let borderBody = SKPhysicsBody(edgeLoopFrom: gravityBarrier.frame)
        self.physicsBody = borderBody
        self.physicsBody?.categoryBitMask = CollisionCategory.BottomBorder
        self.physicsBody?.restitution = 0 //Prevent Bouncing
        
        //Set Player Physics Body
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.categoryBitMask = CollisionCategory.Player
        player.physicsBody?.contactTestBitMask = CollisionCategory.All
        player.physicsBody?.collisionBitMask =  CollisionCategory.SideBorder | CollisionCategory.BottomBorder | CollisionCategory.Window
        player.physicsBody?.restitution = 0 //Prevent Bouncing
        physicsWorld.contactDelegate = self
        
        jumpForce = minJumpForce
        
        //Play Starting Phrase
//        run(SKAction.playSoundFileNamed(randomCraigSayings[Int(random(min: 0, max: CGFloat(randomCraigSayings.count)))], waitForCompletion: true))
    }
    
    override public func update(_ currentTime: TimeInterval) {
        //Make sure game doesn't run after Game Over
        if lives != 0 {
            //Update Score
            scoreLabel.text = String(Int(score))
            
            //Keep track of time between frames
            var timeElapsed: TimeInterval = 0
            if lastTime == 0 {
                timeElapsed = 0
            }
            else {
                timeElapsed = currentTime - lastTime
            }
            lastTime = currentTime
            self.currentTime = currentTime
            
            //If the player somehow changes rotation, set him back
            if player.zRotation != 0.0 {
                player.zRotation = 0.0
            }
            
            //If enough time has passed, play another Craig saying
            if (currentTime - lastCraigSaying) >= timeBetweenSayings {
                run(SKAction.playSoundFileNamed(randomCraigSayings[Int(random(min: 0, max: CGFloat(randomCraigSayings.count)))], waitForCompletion: true))
                lastCraigSaying = currentTime
            }
            
            //If enough time has passed, spawn another window
            if (currentTime - lastWindowSpawn) >= nextWindowWaitDuration {
                addWindow()
                lastWindowSpawn = currentTime
            }
            
            //If enough time has passed, disable powerups
            if (currentTime - lastPowerUpTime) >= powerUpDuration {
                isMavericksActive = false
                isYosemiteActive = false
                isCapitanActive = false
                player.alpha = 1 //Disable Yosemite Indicator
                doubleIndicator.isHidden = true //Disable Mavericks Indicator
            }
            
            if player.physicsBody!.velocity.dy > CGFloat(0) {
                //Prevent window collisions if jumping and not touching window
                if !isCollidingWithWindow {
                    player.physicsBody?.collisionBitMask &= ~CollisionCategory.Window
                }
            }
            else {
                //Allow window collisions if falling and not touching window
                if !isCollidingWithWindow {
                    player.physicsBody?.collisionBitMask |= CollisionCategory.Window
                }
            }
            
            //Check if player is above window, and allow collisions
            if isCollidingWithWindow && collidingWindow != nil {
                if (player.position.y - CGFloat(player.size.height/2.0)) > (collidingWindow.position.y + CGFloat(collidingWindow.size.height/2.0)) {
                    isOnGround = true
                    player.physicsBody?.collisionBitMask |= CollisionCategory.Window
                }
                else if (player.position.x + CGFloat(player.size.width/2.0)) < (collidingWindow.position.x - CGFloat(collidingWindow.size.width/2.0)) {
                    player.physicsBody?.collisionBitMask &= ~CollisionCategory.Window
                }
                else {
                    isOnGround = false
                }
            }
            else {
                //If there is no colliding window, then there is no collision
                isCollidingWithWindow = false
            }
        }
        
    }
    
    //MARK: - Click Detection
    override public func mouseDown(with theEvent: NSEvent) {
        if lives != 0 {
            //Make sure the player is on the ground before allowing jumping
            if isOnGround {
                //Allow for varying jumping heights based on length of click
                let timerAction = SKAction.wait(forDuration: 0.05)
                self.player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: self.minJumpForce))
                let update = SKAction.run({
                    if (self.jumpForce < self.maxJumpForce) {
                        self.player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
                        self.jumpForce += 50
                    }
                    else {
                        self.jumpForce = self.maxJumpForce
                    }
                })
                let sequence = SKAction.sequence([timerAction, update])
                let repeatAction = SKAction.repeatForever(sequence)
                self.run(repeatAction, withKey:"repeatAction")
            }
        }
    }
    
    override public func mouseUp(with theEvent: NSEvent) {
        if lives != 0 {
            //Stop jump
            self.removeAction(forKey: "repeatAction")
            if player.physicsBody!.velocity.dy > 0 {
                player.physicsBody?.velocity = CGVector(dx: 0, dy: player.physicsBody!.velocity.dy * 0.5)
            }

            jumpForce = minJumpForce
        }
    }
    
    // MARK: - Contact Detection
    public func didBegin(_ contact: SKPhysicsContact) {
        //Sort Collision
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //Detect Type of Collision for player
        switch firstBody.categoryBitMask {
        case CollisionCategory.Player:
            switch secondBody.categoryBitMask {
            case CollisionCategory.GoodItem:
                secondBody.node?.removeFromParent()
                //Check if Mavericks Power Up is active and then increase score
                if isMavericksActive {
                    score += 2
                }
                else {
                    score += 1
                }
            case CollisionCategory.BadItem:
                //Check if Yosemite Power Up is active, if not then remove a life
                if !isYosemiteActive {
                    secondBody.node?.removeFromParent()
                    lives -= 1
                    updateLivesCounter()
                }
                if trashItems.index(of: secondBody.node! as! SKSpriteNode) != nil {
                    run(SKAction.playSoundFileNamed("craigTrash.mov", waitForCompletion: false))
                    lastCraigSaying = currentTime
                }
            case CollisionCategory.MavericksPowerUp:
                secondBody.node?.removeFromParent()
                //Activate Mavericks Power Up
                isMavericksActive = true
                lastPowerUpTime = currentTime
                doubleIndicator.isHidden = false
                run(SKAction.playSoundFileNamed("craigMavericks.mp3", waitForCompletion: false))
                lastCraigSaying = currentTime
            case CollisionCategory.YosemitePowerUp:
                secondBody.node?.removeFromParent()
                //Activate Yosemite Power Up
                isYosemiteActive = true
                lastPowerUpTime = currentTime
                player.alpha = 0.5
                run(SKAction.playSoundFileNamed("craigYosemite.mov", waitForCompletion: false))
                lastCraigSaying = currentTime
            case CollisionCategory.CapitanPowerUp:
                secondBody.node?.removeFromParent()
                //Activate Capitan Power Up
                isCapitanActive = true
                if lives != 3 {
                    lives += 1
                    updateLivesCounter()
                }
                lastPowerUpTime = currentTime
                run(SKAction.playSoundFileNamed("craigCapitan.mov", waitForCompletion: false))
                lastCraigSaying = currentTime
            case CollisionCategory.Window:
                isCollidingWithWindow = true
                //Set that the player is on the ground (only if above window)
                collidingWindow = secondBody.node! as! SKSpriteNode
                if (firstBody.node!.position.y - CGFloat((firstBody.node! as! SKSpriteNode).size.height/2.0)) > (secondBody.node!.position.y + CGFloat((secondBody.node! as! SKSpriteNode).size.height/2.0)) {
                    isOnGround = true
                }
            case CollisionCategory.BottomBorder:
                //Set that the player is on the ground
                isOnGround = true
            default:
                break
            }
        default:
            break
        }
    }
    
    public func didEnd(_ contact: SKPhysicsContact) {
        //Sort Collisions
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        switch firstBody.categoryBitMask {
        case CollisionCategory.Player:
            switch secondBody.categoryBitMask {
            case CollisionCategory.Window:
                //Player is Off Ground
                isCollidingWithWindow = false
                collidingWindow = nil
                isOnGround = false
            case CollisionCategory.BottomBorder:
                //Player is Off Ground
                isOnGround = false
            default:
                break
            }
        default:
            break
        }
    }
    
    //MARK: - Other Functions
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addWindow() {
        //Create a random window
        let window = SKSpriteNode(imageNamed: windows[Int(random(min: 0, max: CGFloat(windows.count)))])
        window.size = CGSize(width: window.size.width*2, height: window.size.height*2)
        let topSceneY = (size.height/2) - 75
        let bottomSceneY = -(size.height/2) + 75
        
        //Random Y value, making sure the top of the window will be in the frame
        let windowY = random(min: bottomSceneY - (window.size.height/2), max: topSceneY - (window.size.height/2))
        window.position = CGPoint(x: (size.width/2) + (window.size.width/2), y: windowY)
        window.zPosition = 3
        
        //Set up Window Physics Body
        window.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: -window.size.width/2, y: (window.size.height/2)), to: CGPoint(x: window.size.width/2, y: (window.size.height/2)))
        window.physicsBody?.isDynamic = false
        window.physicsBody?.categoryBitMask = CollisionCategory.Window
        window.physicsBody?.restitution = 0
        
        //Add Window
        gameNode.addChild(window)
        
        //Calculate Time for next window spawn and time for window to cross the screen based on window speed constant
        let startX = (size.width/2) + (window.size.width/2)
        let endX = -(window.size.width/2) - (frame.width/2)
        let duration = TimeInterval((startX - endX)/windowSpeed)
        
        let spawnX = startX - (window.size.width) - 75
        nextWindowWaitDuration = TimeInterval((startX - spawnX)/windowSpeed)
        
        //Move window to off the left side of screen and remove after
        let actionMove = SKAction.move(to: CGPoint(x: endX, y: windowY), duration: duration)
        let actionMoveDone = SKAction.removeFromParent()
        window.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        //Set up the chances of certain items spawning
        var itemTypeChances = [ItemType.None, ItemType.None, ItemType.Good, ItemType.Good, ItemType.Good, ItemType.Good, ItemType.Good, ItemType.Bad, ItemType.Bad, ItemType.Bad, ItemType.PowerUp]
        
        //If a power up is active, don't allow another to spawn
        if isMavericksActive || isYosemiteActive || isCapitanActive {
            itemTypeChances.remove(at: itemTypeChances.count - 1)
        }
        
        //Create a new item with chances set
        let itemType = itemTypeChances[Int(random(min: 0, max: CGFloat(itemTypeChances.count)))]
        var itemSprite: SKSpriteNode!
        switch itemType {
        case ItemType.Good:
            itemSprite = SKSpriteNode(imageNamed: goodItems[Int(random(min: 0, max: CGFloat(goodItems.count)))])
            itemSprite?.size = CGSize(width: 50, height: 50)
            itemSprite?.physicsBody = SKPhysicsBody(rectangleOf: itemSprite.size)
            itemSprite.physicsBody?.categoryBitMask = CollisionCategory.GoodItem
        case ItemType.Bad:
            let imageName = badItems[Int(random(min: 0, max: CGFloat(badItems.count)))]
            itemSprite = SKSpriteNode(imageNamed: imageName)
            if (imageName == "trashIcon") {
                trashItems.append(itemSprite)
            }
            itemSprite?.size = CGSize(width: 50, height: 50)
            itemSprite?.physicsBody = SKPhysicsBody(rectangleOf: itemSprite.size)
            itemSprite.physicsBody?.categoryBitMask = CollisionCategory.BadItem
        case ItemType.PowerUp:
            let powerUpType = Int(random(min: 0, max: CGFloat(powerUpItems.count)))
            itemSprite = SKSpriteNode(imageNamed: powerUpItems[powerUpType])
            itemSprite.size = CGSize(width: 50, height: 50)
            itemSprite?.physicsBody = SKPhysicsBody(rectangleOf: itemSprite.size)
            switch(powerUpType) {
            case PowerUpTypes.Mavericks:
                itemSprite.physicsBody?.categoryBitMask = CollisionCategory.MavericksPowerUp
            case PowerUpTypes.Yosemite:
                itemSprite.physicsBody?.categoryBitMask = CollisionCategory.YosemitePowerUp
            case PowerUpTypes.Capitan:
                itemSprite.physicsBody?.categoryBitMask = CollisionCategory.CapitanPowerUp
            default:
                break
            }
        default:
            itemSprite = nil
        }
        if itemSprite != nil {
            //Place Item on a random position on the window
            let randomXPosition = random(min: window.frame.minX, max: window.frame.maxX)
            
            //Put the Item on top of the window
            let itemYPosition = windowY + (window.size.height/2) + (itemSprite.size.height/2) + 5
            
            //Set up Item Physics Body
            itemSprite.physicsBody?.restitution = 0
            itemSprite?.position = CGPoint(x: randomXPosition, y: itemYPosition)
            itemSprite?.zPosition = 4 //Items are above windows
            itemSprite?.physicsBody?.isDynamic = false
            itemSprite?.physicsBody?.collisionBitMask = CollisionCategory.None
            
            //Add Item
            gameNode.addChild(itemSprite)
            
            //Same speed as window
            let startX = randomXPosition
            let endX = -(itemSprite.size.width/2) - (frame.width/2)
            let duration = TimeInterval((startX - endX)/windowSpeed)
            
            let actionMove = SKAction.move(to: CGPoint(x: endX, y: itemYPosition), duration: duration)
            let actionMoveDone = SKAction.removeFromParent()
            itemSprite?.run(SKAction.sequence([actionMove, actionMoveDone]))
        }
    }
    
    func updateLivesCounter() {
        switch lives {
        case 0:
            batteryNode.texture = SKTexture(image: #imageLiteral(resourceName: "emptyBattery"))
            //Game Over if no lives
            gameOver()
        case 1:
            batteryNode.texture = SKTexture(image: #imageLiteral(resourceName: "lowBattery"))
        case 2:
            batteryNode.texture = SKTexture(image: #imageLiteral(resourceName: "midBattery"))
        case 3:
            batteryNode.texture = SKTexture(image: #imageLiteral(resourceName: "fullBattery"))
        default:
            break;
        }
    }
    
    func gameOver() {
        //Freeze everything
        gameNode.isPaused = true
        player.physicsBody?.isDynamic = false
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        //Flash Battery to indicate death
        let offFlashAction = SKAction.run {
            self.batteryNode.isHidden = true
        }
        let onFlashAction = SKAction.run {
            self.batteryNode.isHidden = false
        }
        let waitAction = SKAction.wait(forDuration: 0.5)
        run(SKAction.repeat(SKAction.sequence([offFlashAction, waitAction, onFlashAction, waitAction]), count: 3)) {
            //Present Game Over
            if let scene = GameOverScene(fileNamed: "GameOverScene") {
                scene.scaleMode = .aspectFit
                scene.setScore(score: Int(self.score))
                self.scene?.view?.presentScene(scene, transition: SKTransition.crossFade(withDuration: 0.3))
            }
            
        }
    }
    
}
