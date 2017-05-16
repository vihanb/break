//
//  AssignmentsViewController.swift
//  break
//
//  Created by Saagar Jha on 1/18/16.
//  Copyright © 2016 Saagar Jha. All rights reserved.
//

import UIKit

class AssignmentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate {

	static let cellIdentifier = "assignment"

	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEEE, MMMM d"
		return dateFormatter
	}()

	var schoolLoop: SchoolLoop!
	var assignments = [Date: [SchoolLoopAssignment]]()
	var filteredAssignments = [Date: [SchoolLoopAssignment]]()
	var filteredAssignmentDueDates = [Date]()

	var destinationViewController: AssignmentDescriptionViewController!

	@IBOutlet weak var assignmentsTableView: UITableView! {
		didSet {
			breakShared.autoresizeTableViewCells(for: assignmentsTableView)
			breakShared.addRefreshControl(refreshControl, to: assignmentsTableView)
			refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
		}
	}
	let refreshControl = UIRefreshControl()
	let searchController = UISearchController(searchResultsController: nil)

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		addSearchBar(from: searchController, to: assignmentsTableView)
		schoolLoop = SchoolLoop.sharedInstance
		if traitCollection.forceTouchCapability == .available {
			registerForPreviewing(with: self, sourceView: assignmentsTableView)
		}
		refresh(self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		assignments = SchoolLoop.sharedInstance.assignmentsWithDueDates
		updateSearchResults(for: searchController)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func refresh(_ sender: Any) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		schoolLoop.getAssignments { (_, error) in
			DispatchQueue.main.async { [weak self] in
				guard let `self` = self else {
					return
				}
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				if error == .noError {
					(UIApplication.shared.delegate as? AppDelegate)?.saveCache()
					`self`.assignments = `self`.schoolLoop.assignmentsWithDueDates
					`self`.updateSearchResults(for: `self`.searchController)
				}
				// Otherwise the refresh control dismiss animation doesn't work
				`self`.refreshControl.perform(#selector(UIRefreshControl.endRefreshing), with: nil, afterDelay: 0)
			}
		}

	}

	@IBAction func openSettings(_ sender: Any) {
		let viewController = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "settings")
		navigationController?.present(viewController, animated: true, completion: nil)
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return filteredAssignments.keys.count
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return AssignmentsViewController.dateFormatter.string(from: filteredAssignmentDueDates[section])
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return filteredAssignments[filteredAssignmentDueDates[section]]?.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: AssignmentsViewController.cellIdentifier, for: indexPath) as? AssignmentTableViewCell else {
			assertionFailure("Could not deque AssignmentTableViewCell")
			return tableView.dequeueReusableCell(withIdentifier: AssignmentsViewController.cellIdentifier, for: indexPath)
		}
		(filteredAssignments[filteredAssignmentDueDates[indexPath.section]]?[indexPath.row]).flatMap { assignment in
			cell.courseNameDiscriminatorView.backgroundColor = UIColor(string: assignment.courseName)
			if assignment.isCompleted {
				let titleText = NSAttributedString(string: assignment.title, attributes: [NSStrikethroughStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)])
				let courseNameText = NSAttributedString(string: assignment.courseName, attributes: [NSStrikethroughStyleAttributeName: NSNumber(value: NSUnderlineStyle.styleSingle.rawValue)])
				cell.titleLabel.attributedText = titleText
				cell.courseNameLabel.attributedText = courseNameText
			} else {
				cell.titleLabel.text = assignment.title
				cell.courseNameLabel.text = assignment.courseName
			}
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}

	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let completeAction = UITableViewRowAction(style: .normal, title: "Mark\nDone") { [unowned self] _, indexPath in
			(self.filteredAssignments[self.filteredAssignmentDueDates[indexPath.section]]?[indexPath.row]).flatMap { assignment in
				assignment.isCompleted = !assignment.isCompleted
				DispatchQueue.main.async {
					tableView.reloadData()
				}
			}
		}
		completeAction.backgroundColor = view.tintColor
		return [completeAction]
	}

	func updateSearchResults(for searchController: UISearchController) {
		let filter = searchController.searchBar.text?.lowercased() ?? ""
		if filter != "" {
			filteredAssignments.removeAll()
			for assignment in Array(assignments.values).flatMap({ $0 }) {
				if assignment.title.lowercased().contains(filter) || assignment.courseName.lowercased().contains(filter) {
					var assignments = filteredAssignments[assignment.dueDate] ?? []
					assignments.append(assignment)
					filteredAssignments[assignment.dueDate] = assignments
				}
			}
		} else {
			filteredAssignments = assignments
		}
		filteredAssignmentDueDates = Array(filteredAssignments.keys).sorted {
			$0.compare($1) == .orderedAscending
		}
		DispatchQueue.main.async { [unowned self] in
			self.assignmentsTableView.reloadData()
		}
	}

	// MARK: - Navigation

	func openAssignmentDescription(for assignment: SchoolLoopAssignment) {
		guard let assignmentDescriptionViewController = storyboard?.instantiateViewController(withIdentifier: "assignmentDescription") as? AssignmentDescriptionViewController else {
			assertionFailure("Could not create AssignmentDescriptionViewController")
			return
		}
		assignmentDescriptionViewController.iD = assignment.iD
		navigationController?.pushViewController(assignmentDescriptionViewController, animated: true)
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		guard let indexPath = assignmentsTableView.indexPathForRow(at: location),
			let cell = assignmentsTableView.cellForRow(at: indexPath) else {
				return nil
		}
		guard let destinationViewController = storyboard?.instantiateViewController(withIdentifier: "assignmentDescription") as? AssignmentDescriptionViewController else {
			return nil
		}
		guard let selectedAssignment = filteredAssignments[filteredAssignmentDueDates[indexPath.section]]?[indexPath.row] else {
			assertionFailure("Previewing index path is invalid")
			return nil
		}
		destinationViewController.iD = selectedAssignment.iD
		destinationViewController.preferredContentSize = .zero
		previewingContext.sourceRect = cell.frame
		return destinationViewController
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		navigationController?.pushViewController(viewControllerToCommit, animated: true)
	}

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		guard let destinationViewController = segue.destination as? AssignmentDescriptionViewController,
			let cell = sender as? AssignmentTableViewCell,
			let indexPath = assignmentsTableView.indexPath(for: cell) else {
				assertionFailure("Could not cast destinationViewController to AssignmentDescriptionViewController")
				return
		}
		let selectedAssignment = filteredAssignments[filteredAssignmentDueDates[indexPath.section]]![indexPath.row]
		destinationViewController.iD = selectedAssignment.iD
		self.destinationViewController = destinationViewController
	}
}
