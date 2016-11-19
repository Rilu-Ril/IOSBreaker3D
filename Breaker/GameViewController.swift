/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*
* Sanira Madzhikova
*/

import UIKit
import SceneKit

/*
 Ball: 1 (Decimal) = 00000001 (Binary)
 Barrier: 2 (Decimal) = 00000010 (Binary)
 Brick: 4 (Decimal) = 00000100 (Binary)
 Paddle: 8 (Decimal) = 00001000 (Binary)
*/

enum ColliderType: Int {
  case Ball = 0b1
  case Barrier = 0b10
  case Brick = 0b100
  case Paddle = 0b1000
}

class GameViewController: UIViewController {
  
  var scnView: SCNView!
  var scnScene: SCNScene!
  var horizontalCameraNode: SCNNode!
  var ballNode: SCNNode!
  var verticalCameraNode: SCNNode!
  var paddleNode: SCNNode!
  
  var touchX: CGFloat = 0
  var paddleX: Float = 0
  
  var game = GameHelper.sharedInstance
  var lastContactNode: SCNNode!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupScene()
    setupNodes()
    setupSounds()
  }
  
  func setupScene() {
    scnView = self.view as! SCNView
    scnView.delegate = self
    scnScene = SCNScene(named: "Breaker.scnassets/Scenes/Game.scn")
    scnScene.physicsWorld.contactDelegate = self
    scnView.scene = scnScene
  }
  
  func setupNodes() {
      scnScene.rootNode.addChildNode(game.hudNode)
    horizontalCameraNode =
      scnScene.rootNode.childNode(withName: "HorizontalCamera", recursively: true)!
    verticalCameraNode =
      scnScene.rootNode.childNode(withName: "VerticalCamera", recursively: true)!
    ballNode = scnScene.rootNode.childNode(withName: "Ball", recursively:
      true)!
    ballNode.physicsBody?.contactTestBitMask = ColliderType.Barrier.rawValue |
      ColliderType.Brick.rawValue | ColliderType.Paddle.rawValue
    
    paddleNode = scnScene.rootNode.childNode(withName: "Paddle", recursively: true)!
  
  }
  
  func setupSounds() {
  }
  
  override var shouldAutorotate : Bool {
    return true
  }
  
  override var prefersStatusBarHidden : Bool {
    return true
  }
  
  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    let deviceOrientation = UIDevice.current.orientation
    switch(deviceOrientation) {
    case .portrait:
      scnView.pointOfView = verticalCameraNode
    default:
      scnView.pointOfView = horizontalCameraNode
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let location = touch.location(in: scnView)
      touchX = location.x
      paddleX = paddleNode.position.x
    }
  }
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch in touches {
      let location = touch.location(in: scnView)
      paddleNode.position.x = paddleX + (Float(location.x - touchX) * 0.1)
      
      if paddleNode.position.x > 4.5 {
        paddleNode.position.x = 4.5
      } else if paddleNode.position.x < -4.5 {
        paddleNode.position.x = -4.5
      }
    }
  }
}

extension GameViewController: SCNSceneRendererDelegate {
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    game.updateHUD()
  }
}
extension GameViewController: SCNPhysicsContactDelegate {
  func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
    var contactNode: SCNNode!
    if contact.nodeA.name == "Ball" {
      contactNode = contact.nodeB
    } else {
      contactNode = contact.nodeA
    }
    if lastContactNode != nil &&
      lastContactNode == contactNode {
      return
    }
    lastContactNode = contactNode
    
    if contactNode.physicsBody?.categoryBitMask == ColliderType.Barrier.rawValue {
      if contactNode.name == "Bottom" {
        game.lives -= 1
        if game.lives == 0 {
          game.saveState()
          game.reset()
        }
      }
    }
    if contactNode.physicsBody?.categoryBitMask == ColliderType.Brick.rawValue {
      game.score += 1
      contactNode.isHidden = true
      contactNode.runAction(
        SCNAction.waitForDurationThenRunBlock(120) {
          (node:SCNNode!) -> Void in
          node.isHidden = false
      })
    }
    
    if contactNode.physicsBody?.categoryBitMask == ColliderType.Paddle.rawValue {
      if contactNode.name == "Left" {
        ballNode.physicsBody!.velocity.xzAngle -= (convertToRadians(20))
      }
      if contactNode.name == "Right" {
        ballNode.physicsBody!.velocity.xzAngle += (convertToRadians(20))
      }
    }
    ballNode.physicsBody?.velocity.length = 5.0
  }
}































