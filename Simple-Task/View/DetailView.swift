//
//  DetailView.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 09.02.25.
//
import SwiftUI

/// Detailansicht zur Bearbeitung einer bestehenden Aufgabe.
struct DetailView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    let task: PrivateTask

    @Environment(\.dismiss) private var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false

    // States mit Initialisierung via init
    @State private var title: String
    @State private var description: String
    @State private var date: Date
    @State private var category: TaskCategory?
    @State private var reminderOffset: TimeInterval
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var isDueDateEnabled: Bool = false
    
    //Neu
    @State private var showEmptyTitleAlert = false
    @State private var showInvalidReminderAlert = false
    
    @State private var newTodoText: String = ""
    @State private var refreshTrigger = UUID()


    init(task: PrivateTask) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _description = State(initialValue: task.desc ?? "")
        _date = State(initialValue: task.date ?? Date())
        _category = State(initialValue: task.taskCategory)
        _reminderOffset = State(initialValue: task.reminderOffset)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(NSLocalizedString("noteTitleSection", comment: "Section header for title"))) {
                    TextField(
                        NSLocalizedString("titlePlaceholder", comment: "Placeholder for task title"),
                        text: $title
                    )
                    .focused($isTextFieldFocused)
                }

                Section(header: Text(NSLocalizedString("descriptionSection", comment: "Section header for description"))) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
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
                
                
                // MARK: - Todo Bereich
                // Zusätzliche Todo´s hinzufügen
                Section("Neues ToDo hinzufügen") {
                    HStack {
                        TextField("Neues ToDo...", text: $newTodoText)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            Task {
                                await addTodo()
                            }
                            
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                
                
                //Bestehende ToDos abarbeiten
                Section(header: Text("Aufgabenliste")) {
                    if task.todosArray.isEmpty {
                        Text("Keine ToDos vorhanden.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(task.todosArray) { todo in
                            HStack {
                                Button(action: {
                                    todo.isDone.toggle()
                                    refreshTrigger = UUID()
                                    Task {
                                        await viewModel.saveContext()
                                    }
                                }) {
                                    Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(todo.isDone ? .green : .gray)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text(todo.title ?? "")
                                    .strikethrough(todo.isDone)
                                    .foregroundColor(.primary)

                                Spacer()

                                Button(role: .destructive) {
                                    task.managedObjectContext?.delete(todo)
                                    refreshTrigger = UUID()
                                    Task {
                                        await viewModel.saveContext()
                                    }
                                    
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .id(refreshTrigger)
                    }
                }


                Section(header: Text(NSLocalizedString("dueAndReminderSection", comment: "Section for date and reminder"))) {
                    
                    Toggle(isOn: $isDueDateEnabled) {
                        Label(
                            NSLocalizedString("editReminderToggle", comment: "Toggle label for enabling reminder editing"),
                            systemImage: "calendar.badge.clock"
                        )
                        .foregroundStyle(isDarkMode ? .white : .black)
                    }
                    .tint(isDarkMode ? .white.opacity(0.50) : .black)

                    if isDueDateEnabled {
                        
                        DatePicker(
                            NSLocalizedString("dateLabel", comment: "Label for due date"),
                            selection: $date,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        
                        Picker(NSLocalizedString("reminderLabel", comment: "Label for reminder picker"), selection: $reminderOffset) {
                            Text(NSLocalizedString("noReminder", comment: "No reminder")).tag(0.0)
                            // Option 2: Bestehende Erinnerung löschen
                               if task.calendarEventID != nil {  
                                   Text(NSLocalizedString("cancelNote", comment: "Cancel"))
                                       .tag(-9999.0)
                               }
                            Text(NSLocalizedString("atDue", comment: "Reminder at due time")).tag(0.1)
                            Text(NSLocalizedString("5minBefore", comment: "5 minutes before")).tag(-300.0)
                            Text(NSLocalizedString("30minBefore", comment: "30 minutes before")).tag(-1800.0)
                            Text(NSLocalizedString("1hourBefore", comment: "1 hour before")).tag(-3600.0)
                            Text(NSLocalizedString("1dayBefore", comment: "1 day before")).tag(-86400.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(isDarkMode ? .white : .black)
                        
                       
                    }
                   
                    }
                // Optische Einblendung ob eine Benachrichtigung an ist oder wann sie aktiv ist
                if let date = task.date, task.calendarEventID != nil {
                    let reminderDate = date.addingTimeInterval(task.reminderOffset)
                    
                    if reminderOffset != 0.0 {
                        let reminderDate = reminderOffset == 0.1 ? date : date.addingTimeInterval(reminderOffset)
                        Text(String(format: NSLocalizedString("reminderTimeLabel", comment: "Label for reminder date"), formatDate(reminderDate)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                


                    
                    if reminderDate > Date() {
                        Label(NSLocalizedString("reminderActive", comment: "Reminder active label"), systemImage: "bell.badge")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Label(NSLocalizedString("reminderExpired", comment: "Reminder expired label"), systemImage: "bell.slash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                    
                    Section(header: Text(NSLocalizedString("categorySection", comment: "Section header for category"))) {
                        Picker(
                            NSLocalizedString("categoryPickerLabel", comment: "Label for category picker"),
                            selection: Binding(
                                get: { category ?? .sonstiges },
                                set: { category = $0 }
                            )
                        ) {
                            ForEach(TaskCategory.allCases) { cat in
                                Label(cat.displayName, systemImage: cat.symbol).tag(cat)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                    }
                    
                    
                
            }
            .navigationTitle(NSLocalizedString("editNoteTitle", comment: "Navigation title for editing a task"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("cancelButton", comment: "Cancel button")) {
                    dismiss()
                }
                .foregroundStyle(isDarkMode ? .white : .black),
                trailing: Button(NSLocalizedString("saveButton", comment: "Save button")) {
                    Task {
                        ///Logik um den leeren Titel abzufangen
                        if title.trimmingCharacters(in: .whitespaces).isEmpty {
                                   showEmptyTitleAlert = true
                                   UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                   return
                               }
                        
                        // Erinnerungszeit prüfen (wenn gesetzt)
                               let reminderDate = reminderOffset == 0.1 ? date : date.addingTimeInterval(reminderOffset)
                               if reminderOffset != 0.0 && reminderDate < Date() {
                                   showInvalidReminderAlert = true
                                   UINotificationFeedbackGenerator().notificationOccurred(.error)
                                   return
                               }

                        
                        await viewModel.updateTask(
                            task,
                            title: title,
                            desc: description,
                            isInCalendar: task.isInCalendar,
                            date: date,
                            category: category ?? .sonstiges,
                            reminderOffset: reminderOffset
                        )
                        dismiss()
                    }
                }
                .foregroundStyle(isDarkMode ? .white : .black)
                .alert(
                    NSLocalizedString("invalidReminderTitle", comment: ""),
                    isPresented: $showInvalidReminderAlert
                ) {
                    Button(NSLocalizedString("ok", comment: "OK button"), role: .cancel) {}
                } message: {
                    Text(NSLocalizedString("invalidReminderMessage", comment: ""))
                }

                //Alert für die leere Titel Logik
                .alert(
                    NSLocalizedString("emptyTitleAlertTitle", comment: "Title for empty title alert"),
                    isPresented: $showEmptyTitleAlert
                ) {
                    Button(NSLocalizedString("ok", comment: "OK button"), role: .cancel) {}
                } message: {
                    Text(NSLocalizedString("emptyTitleAlertMessage", comment: "Message for empty title alert"))
                }

            )
        }
    }
    
    private func addTodo() async {
        guard let context = task.managedObjectContext else { return }

        await MainActor.run {
            let todo = ToDoItem(context: context)
            todo.id = UUID()
            todo.title = newTodoText
            todo.isDone = false
            todo.createdAt = Date()
            todo.task = task

            newTodoText = ""
            refreshTrigger = UUID() // 🟢 erzwingt Neuzeichnung
        }

        await viewModel.saveContext()
    }



    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    struct DetailViewPreviewWrapper: View {
        @StateObject private var viewModel = TaskViewModel(manager: TaskDataModel.preview)

        var body: some View {
            let context = TaskDataModel.preview.persistentContainer.viewContext
            let sampleTask = PrivateTask(context: context)
            sampleTask.id = UUID()
            sampleTask.title = "Preview-Titel"
            sampleTask.desc = "Vorschau-Beschreibung"
            sampleTask.date = Date()
            sampleTask.category = TaskCategory.wichtig.rawValue

            return DetailView(task: sampleTask)
                .environmentObject(viewModel)
        }
    }

    return DetailViewPreviewWrapper()
}
