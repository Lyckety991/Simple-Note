import SwiftUI

/// Visuelle Darstellung einer einzelnen Aufgabe.
/// Zeigt Titel, Beschreibung, Datum und Kategorie.
/// Enthält Farbakzent und Löschfunktion mit Bestätigung.



struct TaskCard: View {
    let task: PrivateTask
    var onDelete: (PrivateTask) -> Void
    @State private var showingAlert = false

    var body: some View {
        HStack(spacing: 0) {
            // Farblicher Streifen links
            Rectangle()
                .fill(task.taskCategory.color)
                .frame(width: 6)
                .cornerRadius(3, corners: [.topRight, .bottomRight])

            VStack(alignment: .leading, spacing: 8) {
                // Titel
                HStack {
                    Text(task.title ?? "Kein Titel")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Beschreibung (optional)
                if let desc = task.desc, !desc.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Datum und Kategorie
                HStack {
                    if let date = task.date {
                        Label(formatDate(date), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Label(task.taskCategory.displayName, systemImage: task.taskCategory.symbol)
                        .font(.caption)
                        .foregroundColor(task.taskCategory.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            task.taskCategory.color.opacity(0.1)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    /// Formatierter Datumstext
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
}

// Preview mit Beispielaufgabe
#Preview {
    let task = PrivateTask(context: TaskDataModel.preview.persistentContainer.viewContext)
    task.title = "Wichtige Aufgabe"
    task.desc = "Diese Aufgabe muss erledigt werden."
    task.date = Date()
    task.category = TaskCategory.wichtig.rawValue

    return TaskCard(task: task) { _ in }
        .padding()
        .previewLayout(.sizeThatFits)
}
