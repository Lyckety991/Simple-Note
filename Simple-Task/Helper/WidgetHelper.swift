//
//  WidgetHelper.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 28.03.25.
//

import Foundation
import WidgetKit

struct TaskWidgetData: Codable {
    let important: Int
    let work: Int
    let privateTask: Int
}

struct TaskStorageHelper {
    static let appGroupID = "group.dev.patrick.SimpleTask"

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var widgetTaskURL: URL? {
        sharedContainerURL?.appendingPathComponent("nextTask.json")
    }

    // ✅ Neue Methode für mehrere Tasks
    static func saveTasksToWidget(_ tasks: [PrivateTask]) {
        guard let url = widgetTaskURL else { return }

        let items: [TaskEntryItem] = tasks.prefix(5).map {
            TaskEntryItem(
                id: $0.id ?? UUID(),
                title: $0.title ?? "Ohne Titel",
                category: $0.taskCategory.rawValue
            )
        }
        
        // 🧮 Kategorie-Zähler berechnen
              let important = tasks.filter { $0.taskCategory == .wichtig }.count
              let work = tasks.filter { $0.taskCategory == .arbeit }.count
              let privat = tasks.filter { $0.taskCategory == .privat }.count

        let entry = TaskEntry(
                  date: Date(),
                  tasks: items,
                  importantCount: important,
                  workCount: work,
                  privateCount: privat
              )


        do {
                  let data = try JSONEncoder().encode(entry)
                  try data.write(to: url)
                  WidgetCenter.shared.reloadAllTimelines()
                  print("✅ Widget-Daten gespeichert: \(items.count) Aufgaben, Wichtig: \(important), Arbeit: \(work), Privat: \(privat)")
              } catch {
                  print("❌ Fehler beim Speichern der Widget-Daten: \(error.localizedDescription)")
              }
    }
    
        /// Lädt die zuletzt gespeicherten Widget-Daten
       static func loadTasksFromWidget() -> TaskEntry? {
           guard let url = widgetTaskURL else { return nil }

           do {
               let data = try Data(contentsOf: url)
               let entry = try JSONDecoder().decode(TaskEntry.self, from: data)
               return entry
           } catch {
               print("❌ Fehler beim Laden der Widget-Daten: \(error.localizedDescription)")
               return nil
           }
       }
    
    
}
