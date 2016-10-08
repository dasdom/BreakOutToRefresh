//
//  DemoTableViewController.swift
//  PullToRefreshDemo
//
//  Created by dasdom on 17.01.15.
//  Copyright (c) 2015 Dominik Hauser. All rights reserved.
//

import UIKit
import BreakOutToRefresh

class DemoTableViewController: UITableViewController {
	
	var refreshView: BreakOutToRefreshView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//    let refreshHeight = CGFloat(100)
		
		// configure the refresh view
		//    refreshView.scenebackgroundColor = UIColor(hue: 0.68, saturation: 0.9, brightness: 0.3, alpha: 1.0)
		//    refreshView.textColor = UIColor.whiteColor()
		//    refreshView.paddleColor = UIColor.lightGrayColor()
		//    refreshView.ballColor = UIColor.whiteColor()
		//    refreshView.blockColors = [UIColor(hue: 0.17, saturation: 0.9, brightness: 1.0, alpha: 1.0), UIColor(hue: 0.17, saturation: 0.7, brightness: 1.0, alpha: 1.0), UIColor(hue: 0.17, saturation: 0.5, brightness: 1.0, alpha: 1.0)]
		
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DemoCell")
	}
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    refreshView = BreakOutToRefreshView(scrollView: tableView)
    refreshView.refreshDelegate = self
    tableView.addSubview(refreshView)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    refreshView.removeFromSuperview()
    refreshView = nil
  }
	
	// MARK: - Table view data source
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 20
	}
	
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DemoCell", for: indexPath)
		
		cell.textLabel?.text = "Row \((indexPath as NSIndexPath).row)"
		
		return cell
	}
	
}

extension DemoTableViewController {
 
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		refreshView.scrollViewDidScroll(scrollView)
	}
	
	override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		refreshView.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
	}
	
	override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		refreshView.scrollViewWillBeginDragging(scrollView)
	}
}

extension DemoTableViewController: BreakOutToRefreshDelegate {
	
	func refreshViewDidRefresh(_ refreshView: BreakOutToRefreshView) {
		// this code is to simulage the loading from the internet
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(NSEC_PER_SEC * 3)) / Double(NSEC_PER_SEC), execute: { () -> Void in
			refreshView.endRefreshing()
		})
	}
	
}
