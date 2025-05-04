//
//  Simple_TaskApp.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 18.01.25.
//

import SwiftUI

@main
struct Simple_TaskApp: App {
    @StateObject private var taskViewModel = TaskViewModel(manager: TaskDataModel())
    @AppStorage("isDarkMode") private var isDarkMode = false

   
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(taskViewModel)
                .environment(\.managedObjectContext, taskViewModel.manager.persistentContainer.viewContext)
                .onAppear {
                    taskViewModel.loadData()
                    // UI-Stil setzen
                    applyTheme()
                    Task {
                        await requestNotifications()
                    }
                    
                   
                }
            

        }
        
        
    }
    
    private func requestNotifications() async {
        let granted = await NotificationManager.shared.requestAuthorization()
        await MainActor.run {
            print("🔁 Notification-Berechtigung gespeichert: \(granted)")
            taskViewModel.notificationsEnabled = granted
        }
    }

      
      private func applyTheme() {
          if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
              windowScene.windows.first?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
          }
      }
    
    
    
}

