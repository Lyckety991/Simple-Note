//
//  SimpleTaskWidget.swift
//  SimpleTaskWidget
//
//  Created by Patrick Lanham on 28.03.25.
//


import SwiftUI
import WidgetKit

struct SimpleTaskWidgetEntryView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        default:
            mediumWidgetView
        }
    }

    // 🔹 Kleine Widget-Ansicht: nur Gesamtanzahl
    var smallWidgetView: some View {
        VStack {
            Text("📋 Aufgaben")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("\(entry.tasks.count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.accentColor)

            Text("insgesamt")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)

    }

    // 🔸 Mittlere Widget-Ansicht bleibt wie gehabt
    var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("🗂️ Deine Tasks")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 10)

            if entry.tasks.isEmpty {
                Text("🎉 Keine Aufgaben")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 12) {
                    statBox(title: "Wichtig", count: entry.importantCount, color: .red)
                    statBox(title: "Arbeit", count: entry.workCount, color: .green)
                    statBox(title: "Privat", count: entry.privateCount, color: .blue)
                }

                Spacer(minLength: 3)

                Link(destination: URL(string: "simpletask://add")!) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Neue Aufgabe")
                            .font(.caption)
                            .bold()
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    func statBox(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(color)
                .bold()
            Text("\(count)")
                .font(.title3)
                .foregroundColor(.black)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.white))
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.2), radius: 2, x: 0, y: 2)
    }
}

struct SimpleTaskWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimpleTaskWidgetEntryView(entry: TaskEntry(
                date: Date(),
                tasks: [
                    TaskEntryItem(id: UUID(), title: "Test", category: "Arbeit")
                ],
                importantCount: 1,
                workCount: 1,
                privateCount: 1
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

            SimpleTaskWidgetEntryView(entry: TaskEntry(
                date: Date(),
                tasks: [
                    TaskEntryItem(id: UUID(), title: "Test", category: "Arbeit"),
                    TaskEntryItem(id: UUID(), title: "Zweiter", category: "Privat")
                ],
                importantCount: 1,
                workCount: 1,
                privateCount: 1
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}

