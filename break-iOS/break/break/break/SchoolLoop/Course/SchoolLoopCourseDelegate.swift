//
//  SchoolLoopCourseDelegate.swift
//  break
//
//  Created by Saagar Jha on 1/19/16.
//  Copyright © 2016 Saagar Jha. All rights reserved.
//

import Foundation

protocol SchoolLoopCourseDelegate: class {
    func gotGrades(schoolLoop: SchoolLoop, error: SchoolLoopError?)
}
