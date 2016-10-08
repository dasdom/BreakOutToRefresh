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

@objc public protocol BreakOutToRefreshDelegate: class {
  func refreshViewDidRefresh(_ refreshView: BreakOutToRefreshView)
}

open class BreakOutToRefreshView: SKView {

  fileprivate let sceneHeight = CGFloat(100)

  fileprivate let breakOutScene: BreakOutScene
  fileprivate unowned let scrollView: UIScrollView
  open weak var refreshDelegate: BreakOutToRefreshDelegate?
  open var forceEnd = false

  open var isRefreshing = false
  fileprivate var isDragging = false
  fileprivate var isVisible = false

  open var scenebackgroundColor: UIColor {
    didSet {
      breakOutScene.scenebackgroundColor = scenebackgroundColor
      startScene.backgroundColor = scenebackgroundColor
    }
  }

  open var textColor: UIColor {
    didSet {
      breakOutScene.textColor = textColor
      startScene.textColor = textColor
    }
  }

  open var paddleColor: UIColor {
    didSet {
      breakOutScene.paddleColor = paddleColor
    }
  }
  open var ballColor: UIColor {
    didSet {
      breakOutScene.ballColor = ballColor
    }
  }

  open var blockColors: [UIColor] {
    didSet {
      breakOutScene.blockColors = blockColors
    }
  }

  fileprivate lazy var startScene: StartScene = {
    let size = CGSize(width: self.scrollView.frame.size.width, height: self.sceneHeight)
    let startScene = StartScene(size: size)
    startScene.backgroundColor = self.scenebackgroundColor
    startScene.textColor = self.textColor
    return startScene
  }()

  public override init(frame: CGRect) {
    fatalError("Use init(scrollView:) instead.")
  }

  public init(scrollView inScrollView: UIScrollView) {

    let frame = CGRect(x: 0.0, y: -sceneHeight, width: inScrollView.frame.size.width, height: sceneHeight)

    breakOutScene = BreakOutScene(size: frame.size)
    self.scrollView = inScrollView

    scenebackgroundColor = UIColor.white
    textColor = UIColor.black
    paddleColor = UIColor.gray
    ballColor = UIColor.black
    blockColors = [UIColor(white: 0.2, alpha: 1.0), UIColor(white: 0.4, alpha: 1.0), UIColor(white: 0.6, alpha: 1.0)]

    breakOutScene.scenebackgroundColor = scenebackgroundColor
    breakOutScene.textColor = textColor
    breakOutScene.paddleColor = paddleColor
    breakOutScene.ballColor = ballColor
    breakOutScene.blockColors = blockColors

    super.init(frame: frame)

    layer.borderColor = UIColor.gray.cgColor
    layer.borderWidth = 1.0

    presentScene(startScene)
  }

  public required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  open func beginRefreshing() {
    isRefreshing = true

    presentScene(breakOutScene, transition: .doorsOpenVertical(withDuration: 0.4))
    breakOutScene.updateLabel("Loading...")

    if self.scrollView.contentOffset.y < -60 {
      self.breakOutScene.reset()
      self.breakOutScene.start()
    }
    UIView.animate(withDuration: 0.4, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
      self.scrollView.contentInset.top += self.sceneHeight
      }) { (_) -> Void in
        self.isVisible = true
    }
  }

  open func endRefreshing() {
    if (!isDragging || forceEnd) && isVisible {
      self.isVisible = false
      UIView.animate(withDuration: 0.4, delay: 0, options: UIViewAnimationOptions(), animations: { () -> Void in
        self.scrollView.contentInset.top -= self.sceneHeight
        }) { (_) -> Void in
          self.isRefreshing = false
          self.presentScene(StartScene(size: CGSize(width: self.scrollView.frame.size.width, height: self.sceneHeight)))
      }
    } else {
      breakOutScene.updateLabel("Loading Finished")
      isRefreshing = false
    }
  }
}

extension BreakOutToRefreshView: UIScrollViewDelegate {

  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    isDragging = true
  }

  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    isDragging = false

    if !isRefreshing && scrollView.contentOffset.y + scrollView.contentInset.top < -sceneHeight {
      beginRefreshing()
      targetContentOffset.pointee.y = -scrollView.contentInset.top
      refreshDelegate?.refreshViewDidRefresh(self)
    }

    if !isRefreshing {
      endRefreshing()
    }

  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
  var textColor: UIColor!
  var paddleColor: UIColor!
  var ballColor: UIColor!
  var blockColors: [UIColor]!

  override func didMove(to view: SKView) {
    super.didMove(to: view)
    if !contentCreated {
      createSceneContents()
      contentCreated = true
    }
  }

  override func update(_ currentTime: TimeInterval) {
    guard let ball = self.childNode(withName: ballName) as? SKSpriteNode,
          let physicsBody = ball.physicsBody else {
        return;
    }

    let maxSpeed: CGFloat = 600.0
    let speed = sqrt(physicsBody.velocity.dx * physicsBody.velocity.dx + physicsBody.velocity.dy * physicsBody.velocity.dy)

    if speed > maxSpeed {
      physicsBody.linearDamping = 0.4
    }
    else {
      physicsBody.linearDamping = 0.0
    }
  }

  func createSceneContents() {
    physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
    physicsWorld.contactDelegate = self

    backgroundColor = scenebackgroundColor
    scaleMode = .aspectFit

    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    physicsBody?.restitution = 1.0
    physicsBody?.friction = 0.0
    name = "scene"

    let back = SKNode()
    back.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: frame.size.width - 1, y: 0),
        to: CGPoint(x: frame.size.width - 1, y: frame.size.height))
    back.physicsBody?.categoryBitMask = backCategory
    addChild(back)

    createLoadingLabelNode()

    let paddle = createPaddle()
    paddle.position = CGPoint(x: frame.size.width-30.0, y: frame.midY)
    addChild(paddle)

    createBall()
    createBlocks()

  }

  func createPaddle() -> SKSpriteNode {
    let paddle = SKSpriteNode(color: paddleColor, size: CGSize(width: 5, height: 30))

    paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
    paddle.physicsBody?.isDynamic = false
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
        block.physicsBody = SKPhysicsBody(rectangleOf: block.size)

        block.physicsBody?.categoryBitMask = blockCategory
        block.physicsBody?.allowsRotation = false
        block.physicsBody?.restitution = 1.0
        block.physicsBody?.friction = 0.0
        block.physicsBody?.isDynamic = false

        addChild(block)
      }
    }
  }

  func removeBlocks() {
    var node = childNode(withName: blockName)
    while (node != nil) {
      node?.removeFromParent()
      node = childNode(withName: blockName)
    }
  }

  func createBall() {
    let ball = SKSpriteNode(color: ballColor, size: CGSize(width: 8, height: 8))


    ball.position = CGPoint(x: frame.size.width - 30.0 - ball.size.width, y: frame.height*CGFloat(arc4random())/CGFloat(UINT32_MAX))
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
    if let ball = childNode(withName: ballName) {
      ball.removeFromParent()
    }
  }

  func createLoadingLabelNode() {
    let loadingLabelNode = SKLabelNode(text: "Loading...")
    loadingLabelNode.fontColor = textColor
    loadingLabelNode.fontSize = 20
    loadingLabelNode.position = CGPoint(x: frame.midX, y: frame.midY)
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

    let ball = childNode(withName: ballName)
    ball?.physicsBody?.applyImpulse(CGVector(dx: -0.5, dy: 0.2))
  }

  func updateLabel(_ text: String) {
    if let label: SKLabelNode = childNode(withName: backgroundLabelName) as? SKLabelNode {
      label.text = text
    }
  }

  func moveHandle(_ value: CGFloat) {
    let paddle = childNode(withName: paddleName)

    paddle?.position.y = value
  }

  func didEnd(_ contact: SKPhysicsContact) {
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

    if let body = otherBody , (body.categoryBitMask & blockCategory != 0) && body.categoryBitMask == blockCategory {
      body.node?.removeFromParent()
      if isGameWon() {
        reset()
        start()
      }
    }
  }

  func isGameWon() -> Bool {
    var numberOfBricks = 0
    self.enumerateChildNodes(withName: blockName) { node, stop in
      numberOfBricks = numberOfBricks + 1
    }
    return numberOfBricks == 0
  }
}

class StartScene: SKScene {
  var contentCreated = false

  var textColor = SKColor.black {
    didSet {
      self.startLabelNode.fontColor = textColor
      self.descriptionLabelNode.fontColor = textColor
    }
  }

  lazy var startLabelNode: SKLabelNode = {
    let startNode = SKLabelNode(text: "Pull to Break Out!")
    startNode.fontColor = self.textColor
    startNode.fontSize = 20
    startNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
    startNode.name = "start"

    return startNode
  }()

  lazy var descriptionLabelNode: SKLabelNode = {
    let descriptionNode = SKLabelNode(text: "Scroll to move handle")
    descriptionNode.fontColor = self.textColor
    descriptionNode.fontSize = 17
    descriptionNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY-20)
    descriptionNode.name = "description"

    return descriptionNode
  }()

  override func didMove(to view: SKView) {
    super.didMove(to: view)
    if !contentCreated {
      createSceneContents()
      contentCreated = true
    }
  }

  func createSceneContents() {
    scaleMode = .aspectFit
    addChild(startLabelNode)
    addChild(descriptionLabelNode)
  }
}
