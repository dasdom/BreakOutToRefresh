# BreakOutToRefresh
Play BreakOut while loading - A playable pull to refresh view using SpriteKit

![](https://raw.githubusercontent.com/dasdom/BreakOutToRefresh/master/Example/PullToRefreshDemo/what.gif)

BreakOutToRefresh uses SpriteKit to add a playable mini game to the pull to refresh view in a table view. In this case the mini game is BreakOut but a lot of other mini games could be presented in this space.

## Installation

### CocoaPods

Add this to your Podfile:

```
use_frameworks!

pod 'BreakOutToRefresh'
```

### Manual

Add **BreakOutToRefreshView.swift** to your project.

## Usage

If you need it only once in your app, add this to your table view controller:
```swift
class DemoTableViewController: UITableViewController {

  var refreshView: BreakOutToRefreshView!
  
  // ...
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    refreshView = BreakOutToRefreshView(scrollView: tableView)
    refreshView.refreshDelegate = self
  
    // configure the refresh view
    refreshView.scenebackgroundColor = .white
    refreshView.textColor = .black
    refreshView.paddleColor = .brown
    refreshView.ballColor = .darkGray
    refreshView.blockColors = [.blue, .green, .red]
  
    tableView.addSubview(refreshView)
  }  
}

extension DemoTableViewController: UIScrollViewDelegate {
 
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    refreshView.scrollViewDidScroll(scrollView)
  }
  
  override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    refreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
  }
  
  override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    refreshView.scrollViewWillBeginDragging(scrollView)
  }
}

extension DemoTableViewController: BreakOutToRefreshDelegate {
  
  func refreshViewDidRefresh(refreshView: BreakOutToRefreshView) {
    // load stuff from the internet
  }

}
```

In case you need it more than once in your app, add the setup to `viewWillAppear` and clean up in `viewWillDisappear` like this:

```swift
override func viewWillAppear(_ animated: Bool) {
  super.viewWillAppear(animated)
  
  refreshView = BreakOutToRefreshView(scrollView: tableView)
  refreshView.refreshDelegate = self
  
  // configure the refresh view
  refreshView.scenebackgroundColor = .white
  refreshView.textColor = .black
  refreshView.paddleColor = .brown
  refreshView.ballColor = .darkGray
  refreshView.blockColors = [.blue, .green, .red]
  
  tableView.addSubview(refreshView)
}

override func viewWillDisappear(_ animated: Bool) {
  super.viewWillDisappear(animated)
  
  refreshView.removeFromSuperview()
  refreshView = nil
}
```

When the loading of new content is finished, call `endRefreshing()` of the `refreshView`.

When `endRefreshing()` is called the mini game doesn't stop immediately. The game stops (and the view is dismissed) when the user lifts the finger. If you like to end the mini game immediately set the `forceEnd` property to true.

## Status

It's kind of beta status.

## Feedback

If you use this code or got inspired by the idea and build an app with an even more awesome PullToRefresh game, please let me know.

## Author

Dominik Hauser

[Twitter: @dasdom](https://twitter.com/dasdom)

[dasdom.github.io](https://dasdom.github.io/)

## Support

If you want to give me something back, I would highly appreciate if you buy [my book about Test-Driven Development with Swift](https://leanpub.com/tddfakebookforios) and give me feedback about it. 

## Thanks

Thanks to [Ben Oztalay](https://github.com/boztalay/BOZPongRefreshControl) and [raywenderlich.com](http://www.raywenderlich.com) for inspiration.

## Licence

MIT
