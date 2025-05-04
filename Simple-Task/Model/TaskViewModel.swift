//
//  TaskViewModel.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 18.01.25.
//
import Foundation
import CoreData
import UIKit
import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    let manager: TaskDataModel
    private var cancellables = Set<AnyCancellable>()
    
    @Published var tasks: [PrivateTask] = []
    @Published var isDataLoaded = false
    @Published var errorMessage: String?
    @Published var notificationsEnabled: Bool = false

    
    init(manager: TaskDataModel) {
        self.manager = manager
        loadData()
    }

    // MARK: - Notification Handling
    func checkNotificationsEnabled() async -> Bool {
        return await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Data Management
    func loadData() {
        DispatchQueue.global(qos: .background).async {
            self.manager.loadCoreData { [weak self] result in
                DispatchQueue.main.async {
                    self?.isDataLoaded = result
                    self?.fetchTasks()
                }
            }
        }
    }
    
    func createTask(
        title: String,
        desc: String,
        date: Date,
        category: TaskCategory,
        reminderOffset: TimeInterval = 0
    ) async throws -> PrivateTask { // 👈 throws hinzufügen
        let newTask = PrivateTask(context: manager.persistentContainer.viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.desc = desc
        newTask.date = date
        newTask.category = category.rawValue
        newTask.reminderOffset = reminderOffset
        
        let notificationsAllowed = await checkNotificationsEnabled()
        
        if reminderOffset != 0 && notificationsAllowed {
            let reminderDate = date.addingTimeInterval(reminderOffset)
            do {
                // 👇 try vor await hinzufügen
                let id = try await NotificationManager.shared.scheduleNotification(
                    title: title,
                    body: "Fällig um \(formatDate(date))",
                    at: reminderDate
                )
                newTask.calendarEventID = id
            } catch {
                print("⚠️ Benachrichtigung konnte nicht erstellt werden: \(error)")
                throw error
            }
        }
        
        await saveContext()
         fetchTasks()
        TaskStorageHelper.saveTasksToWidget(tasks)
        return newTask
    }
    
    func fetchTasks(with searchText: String = "", isDone: Bool? = nil) {
        let request: NSFetchRequest<PrivateTask> = PrivateTask.fetchRequest()
        var predicates: [NSPredicate] = []
        
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", searchText))
        }
        
        if let isDone = isDone {
            predicates.append(NSPredicate(format: "isDone == %@", NSNumber(value: isDone)))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        do {
            let result = try manager.persistentContainer.viewContext.fetch(request)
            DispatchQueue.main.async {
                self.tasks = result
            }
        } catch {
            handleError(error, message: "Fehler beim Laden der Aufgaben")
        }
    }
    
    func deleteTask(_ task: PrivateTask) async {
        let context = manager.persistentContainer.viewContext
        context.delete(task)
        await UINotificationFeedbackGenerator().notificationOccurred(.warning)
        
        if let eventID = task.calendarEventID {
            await NotificationManager.shared.cancelNotification(withID: eventID)
        }
        
        await saveContext()
        fetchTasks()
        TaskStorageHelper.saveTasksToWidget(tasks)
    }
    
    // MARK: - Update Task with Async/Await
    func updateTask(
        _ task: PrivateTask,
        title: String,
        desc: String,
        isInCalendar: Bool,
        date: Date,
        category: TaskCategory,
        reminderOffset: TimeInterval
    ) async {
        let oldOffset = task.reminderOffset
        let oldID = task.calendarEventID
        
        await MainActor.run {
            task.title = title
            task.desc = desc
            task.isInCalendar = isInCalendar
            task.date = date
            task.category = category.rawValue
            task.reminderOffset = reminderOffset
        }
        
        let notificationsAllowed = await checkNotificationsEnabled()
        let reminderDate = date.addingTimeInterval(reminderOffset)
        let offsetChanged = abs(reminderOffset - oldOffset) > 0.001
        
        do {
            
            
            try await handleNotificationUpdates(
                task: task,
                oldOffset: oldOffset,
                oldID: oldID,
                reminderDate: reminderDate,
                offsetChanged: offsetChanged,
                notificationsAllowed: notificationsAllowed,
                title: title
            )
        } catch {
            print("Fehler bei Benachrichtigungsupdate: \(error)")
        }
        
        await saveContext()
        fetchTasks()
        TaskStorageHelper.saveTasksToWidget(tasks)
    }
    
    // MARK: - Private Methods
    private func handleNotificationUpdates(
        task: PrivateTask,
        oldOffset: TimeInterval,
        oldID: String?,
        reminderDate: Date,
        offsetChanged: Bool,
        notificationsAllowed: Bool,
        title: String
    ) async throws { // 👈 throws hinzufügen
        // Fall 1: Erinnerung deaktiviert
        if oldOffset != 0 && task.reminderOffset == 0 {
            await removeExistingNotification(oldID: oldID)
            await MainActor.run {
                task.calendarEventID = nil
            }
        }
        // Fall 2: Reminder geändert & Berechtigung vorhanden
        else if offsetChanged && notificationsAllowed {
            try await updateExistingNotification( // 👈 try hinzufügen
                task: task,
                oldID: oldID,
                reminderDate: reminderDate,
                title: title
            )
        }
        // Fall 3: Keine Berechtigung
        else if offsetChanged && !notificationsAllowed {
            print("🛑 Erinnerung nicht erlaubt – keine neue geplant")
            await removeExistingNotification(oldID: oldID)
        }
    }
    
    private func updateExistingNotification(
        task: PrivateTask,
        oldID: String?,
        reminderDate: Date,
        title: String
    ) async throws { // 👈 throws hinzufügen
        await removeExistingNotification(oldID: oldID)
        
        if reminderDate > Date() {
            do {
                // 👇 try vor await hinzufügen
                let id = try await NotificationManager.shared.scheduleNotification(
                    title: title,
                    body: "Fällig um \(formatDate(reminderDate))",
                    at: reminderDate
                )
                await MainActor.run {
                    task.calendarEventID = id
                }
                print("✅ Neue Erinnerung geplant für \(reminderDate), ID: \(id)")
            } catch {
                print("⚠️ Fehler beim Planen der Benachrichtigung: \(error)")
                throw error
            }
        } else {
            print("⚠️ Erinnerung liegt in der Vergangenheit – nicht geplant")
            await MainActor.run {
                task.calendarEventID = nil
            }
        }
    }
    
    private func removeExistingNotification(oldID: String?) async {
        guard let oldID = oldID else { return }
        await NotificationManager.shared.cancelNotification(withID: oldID)
        print("🗑️ Notification gelöscht (ID: \(oldID))")
    }
    
    // Im TaskViewModel
    func saveContext() async {
        await MainActor.run { // Sicherstellen, dass wir im MainThread arbeiten
            let context = manager.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
    
    private func handleError(_ error: Error, message: String) {
        DispatchQueue.main.async {
            self.errorMessage = "\(message): \(error.localizedDescription)"
        }
    }
}
