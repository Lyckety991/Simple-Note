//
//  NotificationManager.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 29.03.25.
//

import UserNotifications


enum NotificationError: Error {
    case permissionDenied
    case schedulingFailed(Error)
    case invalidDate
}

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    
    private let center = UNUserNotificationCenter.current()
    private var debugLoggingEnabled = true

    private init() {}
    
    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
          do {
              let granted = try await UNUserNotificationCenter.current()
                  .requestAuthorization(options: [.alert, .badge, .sound])
              print("🔔 Anfrage: \(granted ? "erlaubt" : "abgelehnt")")
              return granted
          } catch {
              print("❌ Fehler bei Anfrage: \(error.localizedDescription)")
              return false
          }
      }
  
    // MARK: - Scheduling
    func scheduleNotification(
        title: String,
        body: String,
        at date: Date
    ) async throws -> String {
        guard date > Date() else {
            throw NotificationError.invalidDate
        }
        
        // Erstelle Notification-Content korrekt
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Erstelle Trigger mit aktuellem Kalender
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        
        let id = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await center.add(request)
            log("✅ Erinnerung geplant für \(date.formatted()), ID: \(id)")
            await listPendingNotifications()
            return id
        } catch {
            log("Fehler beim Planen: \(error.localizedDescription)")
            throw NotificationError.schedulingFailed(error)
        }
    }
    // MARK: - Cancellation
    func cancelNotification(withID id: String) async {
         center.removePendingNotificationRequests(withIdentifiers: [id])
        log("🗑️ Notification mit ID \(id) gelöscht")
    }
    
    func cancelAllNotifications() async {
         center.removeAllPendingNotificationRequests()
        log("🧹 Alle Benachrichtigungen gelöscht")
    }

    // MARK: - Debugging
    func listPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        log("📬 Ausstehende Notifications (\(requests.count)):")
        requests.forEach {
            log(" - ID: \($0.identifier), Trigger: \($0.trigger?.description ?? "Kein Trigger")")
        }
    }
    
    // MARK: - Helper
    private func log(_ message: String) {
        guard debugLoggingEnabled else { return }
        print("[NotificationManager] \(message)")
    }
}
