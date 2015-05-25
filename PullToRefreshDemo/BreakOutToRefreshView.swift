//
//  BreakOutToRefreshView.swift
//  PullToRefreshDemo
//
//  Created by dasdom on 17.01.15.
//
//  Copyright (c) 2015 Dominik Hauser <dominik.hauser@dasdom.de>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import SpriteKit

protocol BreakOutToRefreshDelegate: class {
  func refreshViewDidRefresh(refreshView: BreakOutToRefreshView)
}

class BreakOutToRefreshView: SKView {

  private let sceneHeight = CGFloat(100)

  private let breakOutScene: BreakOutScene
  private unowned let scrollView: UIScrollView
  weak var delegate: BreakOutToRefreshDelegate?
  var forceEnd = false

  var isRefreshing = false
  private var isDragging = false
  private var isVisible = false

  var scenebackgroundColor: UIColor {
    didSet {
      breakOutScene.scenebackgroundColor = scenebackgroundColor
    }
  }

  var paddleColor: UIColor {
    didSet {
      breakOutScene.paddleColor = paddleColor
    }
  }
  var ballColor: UIColor {
    didSet {
      breakOutScene.ballColor = ballColor
    }
  }

  var blockColors: [UIColor] {
    didSet {
      breakOutScene.blockColors = blockColors
    }
  }

  override init(frame: CGRect) {
    assert(false, "Use init(scrollView:) instead.")
    breakOutScene = BreakOutScene(size: frame.size)
    scrollView = UIScrollView()

    scenebackgroundColor = UIColor.whiteColor()
    paddleColor = UIColor.whiteColor()
    ballColor = UIColor.whiteColor()
    blockColors = [UIColor.whiteColor()]

    super.init(frame: frame)
  }


  init(scrollView inScrollView: UIScrollView) {

    let frame = CGRect(x: 0.0, y: -sceneHeight, width: inScrollView.frame.size.width, height: sceneHeight)

    breakOutScene = BreakOutScene(size: frame.size)
    self.scrollView = inScrollView

    scenebackgroundColor = UIColor.whiteColor()
    paddleColor = UIColor.grayColor()
    ballColor = UIColor.blackColor()
    blockColors = [UIColor(white: 0.2, alpha: 1.0), UIColor(white: 0.4, alpha: 1.0), UIColor(white: 0.6, alpha: 1.0)]

    breakOutScene.scenebackgroundColor = scenebackgroundColor
    breakOutScene.paddleColor = paddleColor
    breakOutScene.ballColor = ballColor
    breakOutScene.blockColors = blockColors

    super.init(frame: frame)

    layer.borderColor = UIColor.grayColor().CGColor
    layer.borderWidth = 1.0

    presentScene(StartScene(size: frame.size))
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  func beginRefreshing() {
    isRefreshing = true

    let doors = SKTransition.doorsOpenVerticalWithDuration(0.5)
    presentScene(breakOutScene, transition: doors)
    breakOutScene.updateLabel("Loading...")

    UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
      self.scrollView.contentInset.top += self.sceneHeight
      }) { (_) -> Void in
        if self.scrollView.contentOffset.y < -60 {
          self.breakOutScene.reset()
          self.breakOutScene.start()
        }
        self.isVisible = true
    }
  }

  func endRefreshing() {
    if (!isDragging || forceEnd) && isVisible {
      self.isVisible = false
      UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { () -> Void in
        self.scrollView.contentInset.top -= self.sceneHeight
        }) { (_) -> Void in
          self.isRefreshing = false
          self.presentScene(StartScene(size: self.frame.size))
      }
    } else {
      breakOutScene.updateLabel("Loading Finished")
      isRefreshing = false
    }
  }
}

extension BreakOutToRefreshView: UIScrollViewDelegate {

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
    let frameHeight = frame.size.height
    let yPosition = sceneHeight - (-scrollView.contentInset.top-scrollView.contentOffset.y)*2

    breakOutScene.moveHandle(yPosition)
  }
}

class BreakOutScene: SKScene, SKPhysicsContactDelegate {

  let ballName = "ball"
  let paddleName = "paddle"
  let blockName = "block"
  let backgroundLabelName = "backgroundLabel"

  let ballCategory   : UInt32 = 0x1 << 0
  let backCategory : UInt32 = 0x1 << 1
  let blockCategory  : UInt32 = 0x1 << 2
  let paddleCategory : UInt32 = 0x1 << 3

  var contentCreated = false
  var isStarted = false

  var scenebackgroundColor: UIColor!
  var paddleColor: UIColor!
  var ballColor: UIColor!
  var blockColors: [UIColor]!

  override func didMoveToView(view: SKView) {
    super.didMoveToView(view)
    if !contentCreated {
      createSceneContents()
      contentCreated = true
    }
  }

  override func update(currentTime: NSTimeInterval) {
    let ball = self.childNodeWithName(ballName) as! SKSpriteNode!

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

    backgroundColor = scenebackgroundColor
    scaleMode = .AspectFit

    physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
    physicsBody?.restitution = 1.0
    physicsBody?.friction = 0.0
    name = "scene"

    let back = SKNode()
    back.physicsBody = SKPhysicsBody(edgeFromPoint: CGPointMake(frame.size.width - 1, 0),
        toPoint: CGPointMake(frame.size.width - 1, frame.size.height))
    back.physicsBody?.categoryBitMask = backCategory
    addChild(back)

    createLoadingLabelNode()

    let paddle = createPaddle()
    paddle.position = CGPoint(x: frame.size.width-30.0, y: CGRectGetMidY(frame))
    addChild(paddle)

    createBall()
    createBlocks()

  }

  func createPaddle() -> SKSpriteNode {
    let paddle = SKSpriteNode(color: paddleColor, size: CGSize(width: 5, height: 30))

    paddle.physicsBody = SKPhysicsBody(rectangleOfSize: paddle.size)
    paddle.physicsBody?.dynamic = false
    paddle.physicsBody?.restitution = 1.0
    paddle.physicsBody?.friction = 0.0

    paddle.name = paddleName

    return paddle
  }

  func createBlocks() {
    for i in 0..<3 {
      var color = blockColors.count > 0 ? blockColors[0] : UIColor(white: 0.2, alpha: 1.0)
      if i == 1 {
        color = blockColors.count > 1 ? blockColors[1] : UIColor(white: 0.4, alpha: 1.0)
      } else if i == 2 {
        color = blockColors.count > 2 ? blockColors[2] : UIColor(white: 0.6, alpha: 1.0)
      }

      for j in 0..<5 {
        let block = SKSpriteNode(color: color, size: CGSize(width: 5, height: 19))
        block.position = CGPoint(x: 20+CGFloat(i)*6, y: CGFloat(j)*20 + 10)
        block.name = blockName
        block.physicsBody = SKPhysicsBody(rectangleOfSize: block.size)

        block.physicsBody?.categoryBitMask = blockCategory
        block.physicsBody?.allowsRotation = false
        block.physicsBody?.restitution = 1.0
        block.physicsBody?.friction = 0.0
        block.physicsBody?.dynamic = false

        addChild(block)
      }
    }
  }

  func removeBlocks() {
    var node = childNodeWithName(blockName)
    while (node != nil) {
      node?.removeFromParent()
      node = childNodeWithName(blockName)
    }
  }

  func createBall() {
    let ball = SKSpriteNode(color: ballColor, size: CGSize(width: 8, height: 8))


    ball.position = CGPoint(x: frame.size.width - 30.0 - ball.size.width, y: CGRectGetHeight(frame)*CGFloat(arc4random())/CGFloat(UINT32_MAX))
    ball.name = ballName

    ball.physicsBody = SKPhysicsBody(circleOfRadius: ceil(ball.size.width/2.0))
    ball.physicsBody?.usesPreciseCollisionDetection = true
    ball.physicsBody?.categoryBitMask = ballCategory
    ball.physicsBody?.contactTestBitMask = blockCategory | paddleCategory | backCategory
    ball.physicsBody?.allowsRotation = false

    ball.physicsBody?.linearDamping = 0.0
    ball.physicsBody?.restitution = 1.0
    ball.physicsBody?.friction = 0.0

    addChild(ball)
  }

  func removeBall() {
    if let ball = childNodeWithName(ballName) {
      ball.removeFromParent()
    }
  }

  func createLoadingLabelNode() {
    let loadingLabelNode = SKLabelNode(text: "Loading...")
    loadingLabelNode.fontColor = UIColor.lightGrayColor()
    loadingLabelNode.fontSize = 20
    loadingLabelNode.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame))
    loadingLabelNode.name = backgroundLabelName

    addChild(loadingLabelNode)
  }

  func reset() {
    removeBlocks()
    createBlocks()
    removeBall()
    createBall()
  }

  func start() {
    isStarted = true

    let ball = childNodeWithName(ballName)
    ball?.physicsBody?.applyImpulse(CGVector(dx: -0.5, dy: 0.2))
  }

  func updateLabel(text: String) {
    if let label: SKLabelNode = childNodeWithName(backgroundLabelName) as? SKLabelNode {
      label.text = text
    }
  }

  func moveHandle(value: CGFloat) {
    let paddle = childNodeWithName(paddleName)

    paddle?.position.y = value
  }

  func didEndContact(contact: SKPhysicsContact) {
    var ballBody: SKPhysicsBody?
    var otherBody: SKPhysicsBody?

    if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
      ballBody = contact.bodyA
      otherBody = contact.bodyB
    } else {
      ballBody = contact.bodyB
      otherBody = contact.bodyA
    }

    if ((otherBody?.categoryBitMask ?? 0) == backCategory) {
      reset()
      start()
    } else if ballBody!.categoryBitMask & ballCategory != 0 {
      let minimalXVelocity = CGFloat(20.0)
      let minimalYVelocity = CGFloat(20.0)
      var velocity = ballBody!.velocity as CGVector
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
      ballBody?.velocity = velocity
    }

    if otherBody != nil && (otherBody!.categoryBitMask & blockCategory != 0) && otherBody!.categoryBitMask == blockCategory {
      otherBody!.node?.removeFromParent()
      if isGameWon() {
        reset()
        start()
      }
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
