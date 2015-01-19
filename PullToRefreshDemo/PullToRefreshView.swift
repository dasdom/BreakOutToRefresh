//
//  PullToRefreshView.swift
//  PullToRefreshDemo
//
//  Created by dasdom on 17.01.15.
//  Copyright (c) 2015 Dominik Hauser. All rights reserved.
//

import UIKit
import SpriteKit

protocol RefreshViewDelegate: class {
  func refreshViewDidRefresh(refreshView: PullToRefreshView)
}

class PullToRefreshView: SKView {

  private let sceneHeight = CGFloat(100)
  
  let breakOutScene: BreakOutScene
  private unowned let scrollView: UIScrollView
  weak var delegate: RefreshViewDelegate?
  
  var isRefreshing = false
  var isDragging = false
  
  override init(frame: CGRect) {
    assert(false, "Use init(scrollView:) instead.")
    breakOutScene = BreakOutScene(size: frame.size)
    scrollView = UIScrollView()
    
    super.init(frame: frame)
  }
  
  
  init(scrollView inScrollView: UIScrollView) {
    
    let frame = CGRect(x: 0.0, y: -sceneHeight, width: inScrollView.frame.size.width, height: sceneHeight)
    
    breakOutScene = BreakOutScene(size: frame.size)
    self.scrollView = inScrollView
    
    super.init(frame: frame)
    
    presentScene(StartScene(size: frame.size))
  }

  required init(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }
  
  
  func beginRefreshing() {
    isRefreshing = true
    
    let doors = SKTransition.doorsOpenVerticalWithDuration(0.5)
    presentScene(breakOutScene, transition: doors)
    
    UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
      self.scrollView.contentInset.top += self.sceneHeight
    }) { (_) -> Void in
      if self.scrollView.contentOffset.y < -60 && !self.breakOutScene.isStarted {
        self.breakOutScene.start()
      }
    }
  }
  
  func endRefreshing() {
    if !isDragging {
      UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
        self.scrollView.contentInset.top -= self.sceneHeight
        }) { (_) -> Void in
          self.isRefreshing = false
          self.presentScene(StartScene(size: self.frame.size))
      }
    } else {
      self.isRefreshing = false
    }
  }
  
}

extension PullToRefreshView: UIScrollViewDelegate {
  
  func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    isDragging = true
  }
  
  func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    isDragging = false
    
    if !isRefreshing && scrollView.contentOffset.y + scrollView.contentInset.top < -sceneHeight {
      beginRefreshing()
      targetContentOffset.memory.y = -scrollView.contentInset.top
      delegate?.refreshViewDidRefresh(self)
    }
    
    if !isRefreshing {
      endRefreshing()
    }
    
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    println("\(scrollView.contentOffset)")

    let frameHeight = frame.size.height
    let yPosition = sceneHeight - (-scrollView.contentInset.top-scrollView.contentOffset.y)*2
    
    breakOutScene.moveHandle(yPosition)
    
//    if scrollView.contentOffset.y < -60 && !breakOutScene.isStarted {
//      breakOutScene.start()
//    }
  }
}

class BreakOutScene: SKScene, SKPhysicsContactDelegate {
  
  let ballName = "ball"
  let paddleName = "paddle"
  let blockName = "block"
  
  let ballCategory   : UInt32 = 0x1 << 0
  let bottomCategory : UInt32 = 0x1 << 1
  let blockCategory  : UInt32 = 0x1 << 2
  let paddleCategory : UInt32 = 0x1 << 3
  
  var contentCreated = false
  var isStarted = false
  
  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    if !contentCreated {
      createSceneContents()
      contentCreated = true
    }
  }
  
  override func update(currentTime: NSTimeInterval) {
    let ball = self.childNodeWithName(ballName) as SKSpriteNode!
    
    let maxSpeed: CGFloat = 600.0
    let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
    
    if speed > maxSpeed {
      ball.physicsBody!.linearDamping = 0.4
    }
    else {
      ball.physicsBody!.linearDamping = 0.0
    }
  }
  
  func createSceneContents() {
    physicsWorld.gravity = CGVectorMake(0.0, 0.0)
    physicsWorld.contactDelegate = self
    
    backgroundColor = SKColor.blackColor()
    scaleMode = .AspectFit
    
    physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
    physicsBody?.restitution = 1.0
    physicsBody?.friction = 0.0
    
    let paddle = createPaddle()
    paddle.position = CGPoint(x: frame.size.width-30.0, y: CGRectGetMidY(frame))
    addChild(paddle)
    
    createBall()
    createBlocks()
    
  }
  
  func createPaddle() -> SKSpriteNode {
    let paddle = SKSpriteNode(color: UIColor.yellowColor(), size: CGSize(width: 5, height: 30))
    
    paddle.physicsBody = SKPhysicsBody(rectangleOfSize: paddle.size)
    paddle.physicsBody?.categoryBitMask = paddleCategory
    paddle.physicsBody?.dynamic = false
    paddle.physicsBody?.restitution = 1.0
    paddle.physicsBody?.friction = 0.0
    
    paddle.name = paddleName
    
    return paddle
  }
  
  func createBlocks() {
    for i in 0..<4 {
      for j in 0..<5 {
        let block = SKSpriteNode(color: SKColor.greenColor(), size: CGSize(width: 5, height: 19))
        block.position = CGPoint(x: 20+CGFloat(i)*6, y: CGFloat(j)*20 + 10)
        block.name = blockName
        block.physicsBody = SKPhysicsBody(rectangleOfSize: block.size)
        
        block.physicsBody?.categoryBitMask = blockCategory
        block.physicsBody?.allowsRotation = false
        block.physicsBody?.restitution = 1.0
        block.physicsBody?.friction = 0.0
//        block.physicsBody?.mass = 1000.0
        block.physicsBody?.dynamic = false
        
        addChild(block)
      }
    }
  }
  
  func createBall() {
    let ball = SKSpriteNode(color: SKColor.redColor(), size: CGSize(width: 8, height: 8))
    ball.position = CGPoint(x: frame.size.width - 30.0 - ball.size.width, y: CGRectGetMidY(frame))
    ball.name = ballName
    
    ball.physicsBody = SKPhysicsBody(circleOfRadius: ceil(ball.size.width/2.0))
    ball.physicsBody?.usesPreciseCollisionDetection = true
    ball.physicsBody?.categoryBitMask = ballCategory
    ball.physicsBody?.contactTestBitMask = blockCategory | paddleCategory
    ball.physicsBody?.allowsRotation = false
    
    ball.physicsBody?.linearDamping = 0.0
    ball.physicsBody?.restitution = 1.0
    ball.physicsBody?.friction = 0.0
    
    addChild(ball)
  }
  
  func start() {
    isStarted = true
    
    let ball = childNodeWithName(ballName)
    ball?.physicsBody?.applyImpulse(CGVector(dx: -0.5, dy: 0.2))
  }
  
  func moveHandle(value: CGFloat) {
//    println("\(value)")
    
    let paddle = childNodeWithName(paddleName)
    
    paddle?.position.y = value
  }
  
  func didEndContact(contact: SKPhysicsContact) {
    var ballBody: SKPhysicsBody?
    var otherBody: SKPhysicsBody?
    
//    println("--------------------------------------------")
//    println("A \(contact.bodyA) \(contact.bodyA.categoryBitMask) \(ballCategory)")
//    println("B \(contact.bodyB) \(contact.bodyB.categoryBitMask) \(ballCategory)")
    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
//      println("first")
      ballBody = contact.bodyA
      otherBody = contact.bodyB
    } else {
//      println("second")
      ballBody = contact.bodyB
      otherBody = contact.bodyA
    }
    
    if ballBody!.categoryBitMask & ballCategory != 0 {
      let minimalXVelocity = CGFloat(20.0)
      let minimalYVelocity = CGFloat(20.0)
      var velocity = ballBody!.velocity as CGVector
      println("ball category: \(ballBody?.categoryBitMask)")
      println("before \(velocity.dx) \(velocity.dy)")
      if velocity.dx > -minimalXVelocity && velocity.dx <= 0 {
        velocity.dx = -minimalXVelocity-1
      } else if velocity.dx > 0 && velocity.dx < minimalXVelocity {
        velocity.dx = minimalXVelocity+1
      }
      if velocity.dy > -minimalYVelocity && velocity.dy <= 0 {
        velocity.dy = -minimalYVelocity-1
      } else if velocity.dy > 0 && velocity.dy < minimalYVelocity {
        velocity.dy = minimalYVelocity+1
      }
      println("after \(velocity.dx) \(velocity.dy)")
      ballBody?.velocity = velocity
    }
    
    if otherBody != nil && (otherBody!.categoryBitMask & blockCategory != 0) {
      otherBody!.node?.removeFromParent()
      if isGameWon() {
        createBlocks()
      }
      return
    }
    
  }
  
  func isGameWon() -> Bool {
    var numberOfBricks = 0
    self.enumerateChildNodesWithName(blockName) { node, stop in
      numberOfBricks = numberOfBricks + 1
    }
    return numberOfBricks == 0
  }
  
}

class StartScene: SKScene {
  
  var contentCreated = false

  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    if !contentCreated {
      createSceneContents()
      contentCreated = true
    }
  }
  
  func createSceneContents() {
    backgroundColor = SKColor.whiteColor()
    scaleMode = .AspectFit
    addChild(startLabelNode())
    addChild(descriptionLabelNode())
  }
  
  func startLabelNode() -> SKLabelNode {
    let startNode = SKLabelNode(text: "Pull to Break Out!")
    startNode.fontColor = UIColor.blackColor()
    startNode.fontSize = 20
    startNode.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
    startNode.name = "start"
    
    return startNode
  }
  
  func descriptionLabelNode() -> SKLabelNode {
    let descriptionNode = SKLabelNode(text: "Scroll to move handle")
    descriptionNode.fontColor = UIColor.blackColor()
    descriptionNode.fontSize = 17
    descriptionNode.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame)-20)
    descriptionNode.name = "description"
    
    return descriptionNode
  }
  
}
