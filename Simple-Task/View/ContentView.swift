import SwiftUI
import UIKit // Wichtig für Haptic Feedback

/// Enum zur Kategorisierung von Aufgaben.
/// Wird für Filterung, Anzeige und Symbolzuweisung verwendet.
import SwiftUI

enum TaskCategory: String, CaseIterable, Identifiable {
    case privat
    case arbeit
    case wichtig
    case sonstiges

    var id: String { self.rawValue }

    var symbol: String {
        switch self {
        case .privat: return "house"
        case .arbeit: return "briefcase"
        case .wichtig: return "exclamationmark.triangle"
        case .sonstiges: return "tag"
        }
    }

    var color: Color {
        switch self {
        case .privat: return .blue
        case .arbeit: return .green
        case .wichtig: return .orange
        case .sonstiges: return .gray
        }
    }

    /// Lokalisiert angezeigter Name
    var displayName: String {
        switch self {
        case .privat: return NSLocalizedString("categoryPrivate", comment: "Private tasks category")
        case .arbeit: return NSLocalizedString("categoryWork", comment: "Work tasks category")
        case .wichtig: return NSLocalizedString("categoryImportant", comment: "Important tasks category")
        case .sonstiges: return NSLocalizedString("categoryOther", comment: "Other tasks category")
        }
    }
}


enum SortOption: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case creationDateAsc
    case creationDateDesc
    case dueDateAsc
    case dueDateDesc
    case withReminder

    var label: String {
        switch self {
        case .creationDateAsc:
            return NSLocalizedString("sort_created_asc", comment: "Sort by creation date ascending")
        case .creationDateDesc:
            return NSLocalizedString("sort_created_desc", comment: "Sort by creation date descending")
        case .dueDateAsc:
            return NSLocalizedString("sort_due_asc", comment: "Sort by due date ascending")
        case .dueDateDesc:
            return NSLocalizedString("sort_due_desc", comment: "Sort by due date descending")
        case .withReminder:
            return NSLocalizedString("sort_with_reminder", comment: "Sort by tasks with reminders")
        }
    }

    var systemImage: String {
        switch self {
        case .creationDateAsc: return "calendar.badge.plus"
        case .creationDateDesc: return "calendar.badge.minus"
        case .dueDateAsc: return "calendar"
        case .dueDateDesc: return "calendar.circle.fill"
        case .withReminder: return "bell"
        }
    }
}



struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedCategory: TaskCategory? = nil
    @State private var showingAddSheet = false
    @State private var selectedTask: PrivateTask?
    @State private var showingSettingsView = false
    @State private var sortOption: SortOption? = nil


    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 0) {
                    categoryPicker
                    Divider()
                    taskList
                }
                HStack {
                    FloatingAddButton(isShowingAddTaskSheet: $showingAddSheet)
                        .padding(.bottom, 10)
                        .padding(.top, 10)
                }
            }
            .navigationTitle(NSLocalizedString("yourNotesTitle", comment: "Navigation title for notes overview"))
            .toolbar { toolbarItems }
            .background(backgroundGradient)
            .sheet(isPresented: $showingAddSheet) {
                AddTaskSheet(viewModel: taskViewModel, isShowingSheet: $showingAddSheet, selectedDate: Date())
            }
            .sheet(isPresented: $showingSettingsView) {
                SettingsView().environmentObject(taskViewModel)
            }
            .sheet(item: $selectedTask) { task in
                DetailView(task: task).environmentObject(taskViewModel)
            }
        }
    }

    private var categoryPicker: some View {
        Picker(NSLocalizedString("categoryPickerTitle", comment: "Title for task category picker"), selection: $selectedCategory) {
            Text(NSLocalizedString("allCategories", comment: "All categories")).tag(TaskCategory?.none)
            ForEach(TaskCategory.allCases) { category in
                Label(NSLocalizedString(category.displayName, comment: "Task category"), systemImage: category.symbol)
                    .tag(category as TaskCategory?)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                TaskCard(task: task) { taskToDelete in
                        
                    Task {
                        await MainActor.run {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        await taskViewModel.deleteTask(taskToDelete)
                    }
                }
                .scrollTargetLayout()
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .background(Color.clear)
                .cornerRadius(10)
                .onTapGesture { selectedTask = task }
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteTasks)

            if filteredTasks.isEmpty {
                emptyState
            }
        }
        .refreshable {
             taskViewModel.fetchTasks()
        }
        .scrollTargetBehavior(.viewAligned)
        .listStyle(.plain)
        .listRowBackground(Color.clear)
        .scrollContentBackground(.hidden)
        .padding(.top, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .symbolEffect(.bounce, options: .repeating)
                .foregroundStyle(isDarkMode ? .white : .black)

            VStack(spacing: 8) {
                Text(NSLocalizedString("noNotesFound", comment: "No notes found message"))
                    .font(.title3.bold())
                Text(String(format: NSLocalizedString("addNewNoteHint", comment: "Hint to add new note"), "➕"))

                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(Color.clear)
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                showingSettingsView = true
            } label: {
                Image(systemName: "gear")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isDarkMode ? .white : .black)
            }

            Button {
                isDarkMode.toggle()
                updateWindowTheme()
            } label: {
                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                    .foregroundStyle(isDarkMode ? .white : .black)
            }
            Menu {
                Picker(NSLocalizedString("sort_menu_title", comment: "Title for sort menu"), selection: $sortOption) {
                    Text(NSLocalizedString("sort_none", comment: "No sorting")).tag(SortOption?.none)
                    ForEach(SortOption.allCases) { option in
                        Label(option.label, systemImage: option.systemImage)
                            .tag(Optional(option))
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isDarkMode ? .white : .black)
            }

        }
    }

    private var filteredTasks: [PrivateTask] {
        var tasks = taskViewModel.tasks

        // Optional: Kategorie filtern
        if let selectedCategory = selectedCategory {
            tasks = tasks.filter { $0.category == selectedCategory.rawValue }
        }

        // Sortierung
        if let option = sortOption {
            switch option {
            case .creationDateAsc:
                tasks.sort { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
            case .creationDateDesc:
                tasks.sort { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
            case .dueDateAsc:
                tasks.sort { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
            case .dueDateDesc:
                tasks.sort { ($0.date ?? .distantFuture) > ($1.date ?? .distantFuture) }
            case .withReminder:
                tasks = tasks.filter {
                    $0.calendarEventID != nil &&
                    $0.date?.addingTimeInterval($0.reminderOffset) ?? .distantPast > Date()
                }

            }
        } else {
            //Neuste werden bis oben angezeigt
            tasks.sort { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        }

        return tasks
    }


    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: isDarkMode ? [.black, .gray.opacity(0.11)] : [.white.opacity(0.60), .gray.opacity(0.10)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func updateWindowTheme() {
        if let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first {
            window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        Task {
            await MainActor.run {
                offsets.forEach { index in
                    if let task = filteredTasks[safe: index] {
                        Task {
                            await taskViewModel.deleteTask(task)
                        }
                    }
                }
            }
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    let viewModel = TaskViewModel(manager: TaskDataModel.preview)
    let task = PrivateTask(context: viewModel.manager.persistentContainer.viewContext)
    task.id = UUID()
    task.title = "Testaufgabe"
    task.date = Date()
    task.category = TaskCategory.arbeit.rawValue

    return ContentView()
        .environmentObject(viewModel)
}
