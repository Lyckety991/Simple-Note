import SwiftUI

struct TaskCard: View {
    @ObservedObject var task: PrivateTask
    var onDelete: (PrivateTask) -> Void

    @State private var now = Date()
    @AppStorage("isDarkMode") private var isDarkMode = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(task.taskCategory.color)
                .frame(width: 6)
                .cornerRadius(3, corners: [.topRight, .bottomRight])

            VStack(alignment: .leading, spacing: 6) {
                // Titel
                Text(task.title ?? "")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 2)

                // Beschreibung
                if let desc = task.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                
                // ToDo-Liste
                if !task.todosArray.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(task.todosArray.prefix(5)) { todo in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 14)) // Dezentere Größe
                                    .foregroundColor(todo.isDone ? .green : .gray)
                                Text(todo.title ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .strikethrough(todo.isDone)
                                    .opacity(todo.isDone ? 0.6 : 1.0)
                            }
                        }
                        if task.todosArray.count > 5 {
                            Text("…weitere \(task.todosArray.count - 5) Aufgabe(n)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Erinnerungs-Info
                if shouldShowReminderLabel {
                    let reminderTime = task.reminderOffset == 0.1
                        ? (task.date ?? Date())
                        : (task.date ?? Date()).addingTimeInterval(task.reminderOffset)
                    
                    let isReminderExpired = reminderTime <= now
                    
                    HStack(spacing: 4) {
                        Image(systemName: isReminderExpired ? "clock.badge.exclamationmark" : "clock.badge")
                        Text(isReminderExpired
                             ? NSLocalizedString("reminderExpiredLabel", comment: "")
                             : "\(formatDate(reminderTime))")
                    }
                    .font(.caption)
                    .foregroundColor(isReminderExpired ? .red : .orange)
                    .bold()
                    .padding(.top, 2)
                }

                // Fußzeile
                HStack {
                    if let createdDate = task.creationDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.plus")
                            Text(formatCreationDate(createdDate))
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: task.taskCategory.symbol)
                            .foregroundColor(task.taskCategory.color)
                        Text(task.taskCategory.displayName)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.taskCategory.color.opacity(0.15))
                    .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDarkMode ? Color(.systemGray5) : .white)
                .shadow(color: .black.opacity(0.07), radius: 3, x: 0, y: 1)
        )
        .onReceive(timer) { now = $0 }
    }

    private var shouldShowReminderLabel: Bool {
        guard let date = task.date else { return false }
        return task.reminderOffset != 0.0 && date > Date.distantPast
    }

    private func formatCreationDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy HH:mm"
        return formatter.string(from: date)
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
