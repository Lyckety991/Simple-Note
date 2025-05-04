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
                Section(header: Text(NSLocalizedString("titleSection", comment: "Section header for title"))) {
                    TextField(
                        NSLocalizedString("titlePlaceholder", comment: "Placeholder for task title"),
                        text: $title
                    )
                }

                Section(header: Text(NSLocalizedString("descriptionSection", comment: "Section header for description"))) {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section(header: Text(NSLocalizedString("dueAndReminderSection", comment: "Section for date and reminder"))) {
                    DatePicker(
                        NSLocalizedString("dateLabel", comment: "Label for due date"),
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Picker(NSLocalizedString("reminderLabel", comment: "Label for reminder picker"), selection: $reminderOffset) {
                        Text(NSLocalizedString("noReminder", comment: "No reminder")).tag(0.0)
                        Text(NSLocalizedString("atDue", comment: "Reminder at due time")).tag(0.1)
                        Text(NSLocalizedString("5minBefore", comment: "5 minutes before")).tag(-300.0)
                        Text(NSLocalizedString("30minBefore", comment: "30 minutes before")).tag(-1800.0)
                        Text(NSLocalizedString("1hourBefore", comment: "1 hour before")).tag(-3600.0)
                        Text(NSLocalizedString("1dayBefore", comment: "1 day before")).tag(-86400.0)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(isDarkMode ? Color.white : Color.black)

                    if reminderOffset != 0 {
                        Text(String(format: NSLocalizedString("reminderPreview", comment: "Reminder preview text"), formatDate(date.addingTimeInterval(reminderOffset))))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if task.calendarEventID != nil {
                        Label(NSLocalizedString("reminderActive", comment: "Reminder active label"), systemImage: "bell.badge")
                            .font(.caption)
                            .foregroundColor(.green)
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
            )
        }
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
