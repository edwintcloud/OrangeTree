//
//  GameScene.swift
//  OrangeTrees
//
//  Created by Edwin Cloud on 9/18/18.
//  Copyright © 2018 Edwin Cloud. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var orangeTree: SKSpriteNode!
    var orange: Orange?
    var touchStart: CGPoint = .zero
    var shapeNode = SKShapeNode()
    var boundary = SKNode()
    
    // Static variable to store current level
    static var currentLevel: Int = 1
    
    // Static variable to store our lives
    static var currentLives: Int = 5
    
    // Class method to load .sks files
    static func Load(level: Int) -> GameScene? {
        return GameScene(fileNamed: "Level-\(level)")
    }
    
    override func update(_ currentTime: TimeInterval) {
        if childNode(withName: "life1") == nil && isPaused == false {
            gameOver()
            isPaused = true
        }
    }
    
    func gameOver() {
        GameScene.currentLives = 5
        GameScene.currentLevel = 1
        let gameOverText = SKLabelNode(text: "Game Over")
        gameOverText.name = "gameOverText"
        gameOverText.color = SKColor.black
        gameOverText.fontSize = 70
        gameOverText.zPosition = 1000
        gameOverText.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(gameOverText)
    }
    
    override func didMove(to view: SKView) {
        // Connect GameObjects
        orangeTree = childNode(withName: "tree") as? SKSpriteNode
        
        // Configure shapeNode
        shapeNode.lineWidth = 20
        shapeNode.lineCap = .round
        shapeNode.strokeColor = UIColor(white: 1, alpha: 0.3)
        addChild(shapeNode)
        
        // Set the contact delegate
        physicsWorld.contactDelegate = self
        
        // Setup the boundaries
        boundary.physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        boundary.position = .zero
        addChild(boundary)
        
        // Add the Sun to the scene
        let sun = SKSpriteNode(imageNamed: "Sun")
        sun.name = "sun"
        sun.position.y = view.bounds.height * 2 - 80
        sun.position.x = view.bounds.width * 2 - 80
        addChild(sun)
        
        // Add level label inside the Sun
        let levelLabel = SKLabelNode(text: "Level " + String(GameScene.currentLevel))
        levelLabel.fontSize = 50
        levelLabel.name = "levelLabel"
        levelLabel.fontColor = SKColor.black
        levelLabel.position = CGPoint(x: view.bounds.width, y: view.bounds.height * 2 - 80)
        addChild(levelLabel)
        
        // Add orange to top of the screen to count number of lives
        for i in 1...GameScene.currentLives {
            let orange = SKSpriteNode(texture: SKTexture(imageNamed: "Orange"))
            orange.name = "life" + String(i)
            orange.position = CGPoint(x: 100 + (CGFloat(i)*50), y: view.bounds.height * 2 - 70)
            addChild(orange)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the location of the touch on the screen
        let touch = touches.first!
        let location = touch.location(in: self)
        
        if isPaused == true {
            if let view = self.view {
                // Load the SKScene from 'GameScene.sks'
                if let scene = GameScene.Load(level: 1){
                    // Set the scale mode to scale to fit the window
                    scene.scaleMode = .aspectFill
                    
                    // Present the scene
                    view.presentScene(scene)
                }
            }
        }
        
        // Check if the touch was on the Orange Tree
        if atPoint(location).name == "tree" && isPaused != true{
            // Create the orange and add it to the scene at touch location
            orange = Orange()
            orange?.physicsBody?.isDynamic = false
            orange?.position = location
            addChild(orange!)
            
            // Store the location of the touch
            touchStart = location
            
            // Remove life
            enumerateChildNodes(withName: "*life*") {
                (node, stop) in
                
                if let name = node.name, name.contains(String(GameScene.currentLives)) {
                    node.removeFromParent()
                    GameScene.currentLives -= 1
                    stop.initialize(to: true)
                }
            }
        }
        
        // Check whether the sun was tapped and change the level
        for node in nodes(at: location) {
            if node.name == "sun" {
                GameScene.currentLevel += 1
                if let scene = GameScene.Load(level: GameScene.currentLevel) {
                    scene.scaleMode = .aspectFill
                    if let view = view {
                        view.presentScene(scene)
                        let levelLabel = childNode(withName: "levelLabel") as! SKLabelNode
                        levelLabel.text = "Level " + String(GameScene.currentLevel)
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the location of the touch
        let touch = touches.first!
        let location = touch.location(in: self)
        
        // Update the postion of the orange to the current location
        orange?.position = location
        
        // Draw the firing vector
        let path = UIBezierPath()
        path.move(to: touchStart)
        path.addLine(to: location)
        shapeNode.path = path.cgPath
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the location of where the touch ended
        let touch = touches.first!
        let location = touch.location(in: self)
        
        // Get the difference between the start and end point as a vector
        let dx = (touchStart.x - location.x) * 0.5
        let dy = (touchStart.y - location.y) * 0.5
        let vector = CGVector(dx: dx, dy: dy)
        
        // Set the orange dynamic again and apply the vector as an impulse
        orange?.physicsBody?.isDynamic = true
        orange?.physicsBody?.applyImpulse(vector)
        
        // Remove the path from the shapeNode
        shapeNode.path = nil
    }
}

extension GameScene: SKPhysicsContactDelegate {
    // Called when the physicsWorld detects two nodes colliding
    func didBegin(_ contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        // Check that the bodies collided hard enough
        if contact.collisionImpulse > 15 {
            if nodeA?.name == "skull" {
                nodeA!.removeFromParent()
                loadNextLevel()
            } else if nodeB?.name == "skull" {
                nodeB!.removeFromParent()
                loadNextLevel()
            } else {
                
            }
        }
    }
    
    func loadNextLevel() {
        GameScene.currentLevel += 1
        if let scene = GameScene.Load(level: GameScene.currentLevel) {
            scene.scaleMode = .aspectFill
            if let view  = view {
                
                view.presentScene(scene, transition: SKTransition.reveal(with: .down, duration: 2))
                
            }
        }
    }
}


