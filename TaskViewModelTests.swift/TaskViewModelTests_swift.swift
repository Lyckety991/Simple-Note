//
//  TaskViewModelTests_swift.swift
//  TaskViewModelTests.swift
//
//  Created by Patrick Lanham on 28.03.25.
//
import Testing
import Foundation
@testable import Simple_Task

struct TaskViewModelTests {

    private func createIsolatedViewModel() -> TaskViewModel {
        let manager = TaskDataModel(inMemory: true)
        return TaskViewModel(manager: manager)
    }

    @Test func testCreateTask_addsNewTaskToList() async throws {
        let viewModel = createIsolatedViewModel()
        #expect(viewModel.task.isEmpty)

        let task = viewModel.createTask(
            title: "Testaufgabe",
            desc: "Beschreibung",
            date: Date(),
            category: .arbeit
        )

        #expect(viewModel.task.count == 1)
        #expect(viewModel.task.first?.title == "Testaufgabe")
        #expect(viewModel.task.first?.taskCategory == .arbeit)

        // Optional: Prüfe ob ID für Notification existiert
        #expect(task.calendarEventID == nil) // da kein Offset gesetzt
    }

    @Test func testDeleteTask_removesTaskAndNotification() async throws {
        let viewModel = createIsolatedViewModel()

        let task = viewModel.createTask(
            title: "Mit Erinnerung",
            desc: "Wird gelöscht",
            date: Date().addingTimeInterval(3600),
            category: .sonstiges
        )
        task.calendarEventID = NotificationManager.shared.scheduleNotification(
            title: task.title ?? "",
            body: "Test",
            at: task.date ?? Date()
        )

        #expect(viewModel.task.count == 1)
        #expect(task.calendarEventID != nil)

        viewModel.deleteTask(task)
        #expect(viewModel.task.isEmpty)
    }

    @Test func testUpdateTask_updatesValuesCorrectly() async throws {
        let viewModel = createIsolatedViewModel()
        
        // 🔧 Sicherstellen, dass Notifications aktiviert sind
        viewModel.notificationsEnabled = true

        let task = viewModel.createTask(
            title: "Original",
            desc: "Alte Beschreibung",
            date: Date(),
            category: .privat
        )

        let newTitle = "Geändert"
        let newDesc = "Neue Beschreibung"
        let newDate = Date().addingTimeInterval(3600)
        let offset: TimeInterval = -300 // 5 Min vorher

        viewModel.updateTask(
            task,
            title: newTitle,
            desc: newDesc,
            isInCalendar: false,
            date: newDate,
            category: .arbeit,
            reminderOffset: offset
        )

        viewModel.fetchTask()

        #expect(task.title == newTitle)
        #expect(task.desc == newDesc)
        #expect(task.taskCategory == .arbeit)
        #expect(task.calendarEventID != nil) // ✅ Wichtig!
    }

}
