//
//  breakShared.swift
//  break
//
//  Created by Saagar Jha on 4/28/17.
//  Copyright © 2017 Saagar Jha. All rights reserved.
//

import UIKit

extension UIColor {
	static let `break` = #colorLiteral(red: 0.1019607843, green: 0.737254902, blue: 0.6117647059, alpha: 1)

	convenience init(string: String) {
		let hashValue = UInt(bitPattern: string.hashValue)
		let channelSize = UInt(MemoryLayout<UInt>.size * 8 / 3)
		let mask = 1 << channelSize - 1
		let red = CGFloat(hashValue & mask) / CGFloat(mask + 1)
		let green = CGFloat(hashValue >> channelSize & mask) / CGFloat(mask + 1)
		let blue = CGFloat(hashValue >> (channelSize * 2) & mask) / CGFloat(mask + 1)
		self.init(red: red, green: green, blue: blue, alpha: 1)
	}
}

enum breakTabIndices: Int, CustomStringConvertible {
	case courses = 0
	case assignments
	case loopMail
	case news
	case locker

	var description: String {
		switch self {
		case .courses:
			return "Courses"
		case .assignments:
			return "Assignments"
		case .loopMail:
			return "LoopMail"
		case .news:
			return "News"
		case .locker:
			return "Locker"
		}
	}
}

extension UIViewController {
	func setupSelfAsMasterViewController() {
		splitViewController?.preferredDisplayMode = .allVisible

		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = true
			navigationItem.largeTitleDisplayMode = .always
		}
	}

	func setupSelfAsDetailViewController() {
		navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
		navigationItem.leftItemsSupplementBackButton = true

		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
			navigationItem.largeTitleDisplayMode = .never
		}
	}
}

@objc protocol Refreshable {
	func refresh(_ sender: Any)
}

extension Refreshable where Self: UITableViewController {
	func setupRefreshControl() {
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
	}
}

extension UISearchResultsUpdating where Self: UIViewController {
	func addSearchBar(from searchController: UISearchController, to tableView: UITableView) {
		definesPresentationContext = true
		searchController.searchResultsUpdater = self
		searchController.dimsBackgroundDuringPresentation = false
		if #available(iOS 11.0, *),
			// Workaround for rdar://problem/35436877
			type(of: self) != ProgressReportViewController.self {
			navigationItem.searchController = searchController
		} else {
			tableView.tableHeaderView = searchController.searchBar
			// Hide the search bar by default
			tableView.contentOffset.y = searchController.searchBar.frame.height
		}
	}
}

extension UIViewControllerPreviewingDelegate where Self: UIViewController {
	func setupForceTouch(originatingFrom sourceView: UIView) {
		if traitCollection.forceTouchCapability == .available {
			registerForPreviewing(with: self, sourceView: sourceView)
		}
	}
}

enum breakConstants {
	static let iTunesIdentifier = "1113901082"

	static let loginStationaryAnimationDuration = 1.0
	static let loginMovableAnimationDuration = 0.5
	static let loginMovableAnimationDelay = 0.1

	static let webViewDefaultStyle = "<meta charset=\"utf-8\"><meta name=\"viewport\" content=\"initial-scale=1\" /><style type=\"text/css\">body{font: -apple-system-body;}</style>"

	static let tableViewCellVerticalPadding = 12

	static let discriminatorViewWidth: CGFloat = 4
}

protocol RefreshableView: AnyObject {
	@available(iOS 10.0, *)
	var refreshControl: UIRefreshControl? { get set }

	var backgroundView: UIView? { get set }
}

extension UITableView: RefreshableView { }
extension UICollectionView: RefreshableView { }

enum breakShared {
	static func autoresizeTableViewCells(for tableView: UITableView) {
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 80.0
	}

	static func add<V: UIView>(_ refreshControl: UIRefreshControl, to view: V) where V: RefreshableView {
		if #available(iOS 10.0, *) {
			view.refreshControl = refreshControl
		} else {
			view.addSubview(refreshControl)
			view.backgroundView = UIView()
			view.backgroundView?.backgroundColor = .clear
		}
	}
}
