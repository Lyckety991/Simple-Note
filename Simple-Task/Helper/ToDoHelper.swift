//
//  ToDoHelper.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 26.05.25.
//

import Foundation

extension PrivateTask {
    var todosArray: [ToDoItem] {
        let set = todos as? Set<ToDoItem> ?? []
        return set.sorted {
            ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
        }
    }
}
