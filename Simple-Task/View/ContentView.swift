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


struct ContentView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var selectedCategory: TaskCategory? = nil
    @State private var showingAddSheet = false
    @State private var selectedTask: PrivateTask?
    @State private var showingSettingsView = false

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
        }
    }

    private var filteredTasks: [PrivateTask] {
        guard let selectedCategory = selectedCategory else { return taskViewModel.tasks }
        return taskViewModel.tasks.filter { $0.category == selectedCategory.rawValue }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: isDarkMode ? [.black, .gray.opacity(0.5)] : [.white.opacity(0.30), .gray.opacity(0.10)]),
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
