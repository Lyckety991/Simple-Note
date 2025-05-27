//
//  AddTaskSheet.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 18.01.25.
//

import SwiftUI

struct AddTaskSheet: View {
    
    /// Sheet-Ansicht zum Erstellen einer neuen Aufgabe.
    /// Enthält Eingabefelder für Titel, Beschreibung, Kategorie und speichert die Aufgabe über das `TaskViewModel`.
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isShowingSheet: Bool

    @State private var taskTitle = ""
    @State private var desc = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedCategory: TaskCategory = .privat
    @State var selectedDate: Date
    @State private var reminderOffset: TimeInterval = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    //Neu
    @State private var isDueDateEnabled: Bool = false
    @State var showInvalidReminderAlert: Bool = false
    @State private var showEmptyTitleAlert = false
    
    //Für die ToDoListe
    @State private var newTodoText: String = ""
    @State private var todos: [String] = []


    

    var body: some View {
        NavigationStack {
            List {
                // Eingabe für Aufgabentitel
                Section(NSLocalizedString("noteTitleSection", comment: "Section title for task title")) {
                    TextField(NSLocalizedString("taskPlaceholder", comment:"Placeholder for task title"), text: $taskTitle)
                        .focused($isTextFieldFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isTextFieldFocused = true
                            }
                        }
                       

                       
                }
                // Eingabe für Beschreibung
                Section(NSLocalizedString("descriptionSection", comment: "Section title for task description")) {
                    TextEditor(text: $desc)
                        .frame(height: 150)
                        .cornerRadius(8)
                        .focused($isTextFieldFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button(action: {
                                    isTextFieldFocused = false
                                }) {
                                    Label("Tastatur schließen", systemImage: "keyboard.chevron.compact.down")
                                }
                            }
                        }
                }
                
                Section(header: Text("Aufgabenliste")) {
                    VStack(spacing: 8) {
                        HStack {
                            TextField("Neues ToDo...", text: $newTodoText)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                todos.append(trimmed)
                                newTodoText = ""
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(Array(todos.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Image(systemName: "circle")
                                Text(item)
                                Spacer()
                                Button(action: {
                                    todos.remove(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                
                // Bereich für das Fälligkeitsdatum und der Erinnerung
                Section(NSLocalizedString("dueAndReminderSection", comment: "Section title for due date and reminder")) {

                    Toggle(isOn: $isDueDateEnabled) {
                        Label(
                            NSLocalizedString("enableDueDateToggle", comment: "Toggle label for enabling due date"),
                            systemImage: "calendar.badge.clock"
                        )
                        .foregroundStyle(isDarkMode ? .white : .black)
                    }
                    .tint(isDarkMode ? .white.opacity(0.50) : .black)

                    

                    if isDueDateEnabled {
                        DatePicker(
                            NSLocalizedString("dateLabel", comment: "Label for due date"),
                            selection: $selectedDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        Picker(
                            NSLocalizedString("reminderLabel", comment: "Label for reminder picker"),
                            selection: $reminderOffset
                        ) {
                            Text(NSLocalizedString("noReminder", comment: "No reminder")).tag(0.0)
                            Text(NSLocalizedString("atDue", comment: "Reminder at due time")).tag(0.1)
                            Text(NSLocalizedString("5minBefore", comment: "5 minutes before")).tag(-300.0)
                            Text(NSLocalizedString("30minBefore", comment: "30 minutes before")).tag(-1800.0)
                            Text(NSLocalizedString("1hourBefore", comment: "1 hour before")).tag(-3600.0)
                            Text(NSLocalizedString("1dayBefore", comment: "1 day before")).tag(-86400.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(isDarkMode ? .white : .black)

                        if reminderOffset != 0.0 {
                            let reminderDate = reminderOffset == 0.1 ? selectedDate : selectedDate.addingTimeInterval(reminderOffset)
                            Text(String(format: NSLocalizedString("reminderTimeLabel", comment: "Label for reminder date"), formatDate(reminderDate)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                    }
                }

                
                // Auswahl der Kategorie via Segmented Picker
                Section(NSLocalizedString("categorySection", comment: "Section title for category picker")) {
                    Picker("Kategorie", selection: $selectedCategory) {
                        ForEach(TaskCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.symbol).tag(category)
                        }
                       
                    }
                    
                    .pickerStyle(SegmentedPickerStyle())
                }

                
            }
            
            .padding(.horizontal, 2)
            .navigationTitle(NSLocalizedString("newNoteTitle", comment: "Title for new note view"))
            .navigationBarItems(leading: Button(NSLocalizedString("cancel", comment: "Cancel button")) {
                isShowingSheet = false
               
            }
                .foregroundStyle(isDarkMode ? .white : .black))

            .navigationBarItems(trailing:
                                    // Speichern-Button
                                Button(action: {
                                    Task {
                                        do {
                                            if taskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                                                await MainActor.run {
                                                    showEmptyTitleAlert = true
                                                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                                }
                                                return
                                            }

                                            //guard !taskTitle.isEmpty else { return }
                                            let deadline = selectedDate
                                            let reminderDate = selectedDate.addingTimeInterval(reminderOffset)
                                            
                                            if reminderOffset != 0.0 && reminderDate < Date() {
                                                // Feedback und Abbruch
                                                await MainActor.run {
                                                    showInvalidReminderAlert = true
                                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                                }
                                                print("⚠️ Ungültiger Erinnerungszeitpunkt (liegt in der Vergangenheit)")
                                                return
                                            }
                                            
                                            // 1. Task erstellen (mit try await)
                                            let newTask = try await viewModel.createTask(
                                                title: taskTitle,
                                                desc: desc,
                                                date: deadline,
                                                category: selectedCategory,
                                                reminderOffset: reminderOffset,
                                                todos: todos
                                                
                                            )
                                            
                                          
                                            
                                          
                                            
                                            // 4. UI Updates auf MainActor
                                            await MainActor.run {
                                                hideKeyboard()
                                                
                                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                            }
                                            
                                            // 5. Sheet schließen mit Verzögerung
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                dismiss()
                                               
                                                isShowingSheet = false
                                                
                                            }
                                            
                                             viewModel.fetchTasks()
                                            
                                        } catch {
                                            await MainActor.run {
                                                // 6. Fehlerbehandlung in der UI
                                                
                                                UINotificationFeedbackGenerator().notificationOccurred(.error)
                                            }
                                        }
                                    }
                                    }) {
                                        Text(NSLocalizedString("saveButton", comment: "Save button title"))
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            
                                            .foregroundColor(isDarkMode ? .white : .black)
                                            .cornerRadius(8)
                                    }
                                    //.disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                                    //Empty title alert
                                    .alert(
                                        NSLocalizedString("emptyTitleAlertTitle", comment: "Title for empty title alert"),
                                        isPresented: $showEmptyTitleAlert
                                    ) {
                                        Button(NSLocalizedString("ok", comment: "OK button"), role: .cancel) {}
                                    } message: {
                                        Text(NSLocalizedString("emptyTitleAlertMessage", comment: "Message for empty title alert"))
                                    }
                                    //Invalid time alert
                                    .alert(
                                        NSLocalizedString("invalidReminderTitle", comment: "Title for invalid reminder alert"),
                                        isPresented: $showInvalidReminderAlert
                                    ) {
                                        Button(NSLocalizedString("ok", comment: "OK button for alerts"), role: .cancel) {}
                                    } message: {
                                        Text(NSLocalizedString("invalidReminderMessage", comment: "Message for invalid reminder"))
                                    }
                                


            
            
            )
            
            
            
        }
        
        
      
    }
    
}
// Preview für SwiftUI Canvas
struct AddTaskSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskSheet(
            viewModel: TaskViewModel(manager: TaskDataModel.preview),
            isShowingSheet: .constant(true), selectedDate: Date()
        )
    }
}

// Tastaturausblendung für SwiftUI
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
        /// Formatierter Datumstext (medium style, lokalisiert)
        func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
}

// Erweiterung für Typ-sicheren Zugriff auf Kategorie
extension PrivateTask {
    var taskCategory: TaskCategory {
        get { TaskCategory(rawValue: category ?? "") ?? .sonstiges }
        set { category = newValue.rawValue }
    }
}
