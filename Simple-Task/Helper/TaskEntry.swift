//
//  TaskEntry.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 28.03.25.
//

import Foundation
import WidgetKit

struct TaskEntry: TimelineEntry, Codable {
    let date: Date
    let tasks: [TaskEntryItem]
    let importantCount: Int
    let workCount: Int
    let privateCount: Int
}

struct TaskEntryItem: Codable, Identifiable {
    var id: UUID
    var title: String
    var category: String
    
}
