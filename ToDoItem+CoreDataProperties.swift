//
//  ToDoItem+CoreDataProperties.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 26.05.25.
//
//

import Foundation
import CoreData


extension ToDoItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoItem> {
        return NSFetchRequest<ToDoItem>(entityName: "ToDoItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var isDone: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var task: PrivateTask?

}

extension ToDoItem : Identifiable {

}
