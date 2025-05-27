import SwiftUI

struct TaskCard: View {
    @ObservedObject var task: PrivateTask
    var onDelete: (PrivateTask) -> Void

    @State private var now = Date()
    @AppStorage("isDarkMode") private var isDarkMode = false

    // Timer zur Aktualisierung alle 20 Sekunden
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(task.taskCategory.color)
                .frame(width: 6)
                .cornerRadius(3, corners: [.topRight, .bottomRight])

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.title ?? "")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                }

                if let desc = task.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 📌 Nur anzeigen, nicht interaktiv
                if !task.todosArray.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(task.todosArray.prefix(3)) { todo in
                            HStack(spacing: 8) {
                                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(todo.isDone ? .green : .gray)
                                Text(todo.title ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .strikethrough(todo.isDone)
                            }
                        }
                        if task.todosArray.count > 3 {
                            Text("…weitere \(task.todosArray.count - 3) ToDo(s)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }

                
                
                

                if shouldShowReminderLabel {
                    let reminderTime = task.reminderOffset == 0.1 ? (task.date ?? Date()) : (task.date ?? Date()).addingTimeInterval(task.reminderOffset)
                    let isReminderExpired = reminderTime <= now

                    HStack {
                        if isReminderExpired {
                            Label(NSLocalizedString("reminderExpiredLabel", comment: "Label when reminder is expired"), systemImage: "clock.badge.exclamationmark")
                                .foregroundColor(.red)
                                .bold()
                        } else {
                            Label {
                                Text(NSLocalizedString("reminderActiveLabel", comment: "")) +
                                Text(" \(formatDate(reminderTime))")
                            } icon: {
                                Image(systemName: "clock.badge")
                            }
                            .foregroundColor(.orange)
                            .bold()


                        }
                    }
                    .font(.caption)
                }

                HStack {
                    if let createdDate = task.creationDate {
                        Label(
                            String(format: NSLocalizedString("createdOnLabel", comment: "Label showing creation date of the task"),
                                   formatCreationDate(createdDate)),
                            systemImage: "calendar.badge.plus"
                        )
                        .font(.caption2)
                        .bold()
                    }

                    Spacer()
                    Label(task.taskCategory.displayName, systemImage: task.taskCategory.symbol)
                        .categoryBadge(color: task.taskCategory.color)
                        
                        .bold()
                        
                }
                .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(.systemGray5) : .white)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .onReceive(timer) { now = $0 }
    }

    private var shouldShowReminderLabel: Bool {
        guard let date = task.date else { return false }
        return task.reminderOffset != 0.0 && task.reminderOffset != -1.0 && date > Date.distantPast
    }

    private func formatCreationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.timeZone = .current
        formatter.locale = .current
        return formatter.string(from: date)
    }
}

extension View {
    func categoryBadge(color: Color) -> some View {
        self
            .font(.caption)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview("Aktive Erinnerung") {
    let context = TaskDataModel.preview.persistentContainer.viewContext
    let task = PrivateTask(context: context)
    task.title = "Geburtstagsfeier"
    task.date = Date().addingTimeInterval(3600 * 3)
    task.reminderOffset = -1800
    task.category = TaskCategory.privat.rawValue
    task.creationDate = Date()

    return TaskCard(task: task) { _ in }
        .environment(\.managedObjectContext, context)
        .padding()
}

#Preview("Abgelaufene Erinnerung") {
    let context = TaskDataModel.preview.persistentContainer.viewContext
    let task = PrivateTask(context: context)
    task.title = "Müll rausbringen"
    task.date = Date().addingTimeInterval(-3600)
    task.reminderOffset = -300
    task.category = TaskCategory.wichtig.rawValue
    task.creationDate = Date()

    return TaskCard(task: task) { _ in }
        .environment(\.managedObjectContext, context)
        .padding()
}
