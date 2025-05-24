//
//  SettingsView.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 29.03.25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Darstellung
                Section(NSLocalizedString("appearanceSection", comment: "Appearance section")) {
                    toggleUIButton
                }

                // MARK: - Support
                Section(NSLocalizedString("supportSection", comment: "Support section")) {
                    mailButton
                }

                // MARK: - Informationen
                Section(NSLocalizedString("infoSection", comment: "App information section")) {
                    datenschutzButton
                    aboutButton
                    somerightsButton
                    usingConditionsButton
                }

                // MARK: - App-Info
                Section(NSLocalizedString("appInfoSection", comment: "App section")) {
                    HStack {
                        Text(NSLocalizedString("versionLabel", comment: "Version label"))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settingsTitle", comment: "Settings title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Buttons
    
    private var toggleUIButton: some View {
        Toggle(NSLocalizedString("darkModeToggle", comment: "Dark mode toggle"), isOn: $isDarkMode)
            .onChange(of: isDarkMode) { _, newValue in
                updateWindowTheme(isDarkMode: newValue)
            }
            .foregroundStyle(isDarkMode ? .white : .black)
            .tint(isDarkMode ? .white.opacity(0.50) : .black)
    }
    
    private var mailButton: some View {
        Button {
            let mailto = "mailto:mail@patrick-lanham.de?subject=Bug%20in%20SimpleTask&body=Beschreibe%20den%20Fehler%20hier..."
            if let url = URL(string: mailto) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                Text(NSLocalizedString("supportEmailButton", comment: "Support email button"))
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isDarkMode ? .white : .black)
            .cornerRadius(8)
        }
    }
    
    private var aboutButton: some View {
        LinkButton(
            icon: "chart.bar.horizontal.page.fill",
            text: NSLocalizedString("aboutButton", comment: "About the app")
        ) {
            guard let url = URL(string: "https://www.patrick-lanham.de") else { return }
            UIApplication.shared.open(url)
        }
    }
    
    private var datenschutzButton: some View {
        LinkButton(
            icon: "lock.shield.fill",
            text: NSLocalizedString("privacyPolicyButton", comment: "Privacy policy button")
        ) {
            guard let url = URL(string: "https://www.patrick-lanham.de/datenschutz.html") else { return }
            UIApplication.shared.open(url)
        }
    }
    
    private var somerightsButton: some View {
        LinkButton(
            icon: "exclamationmark.shield.fill",
            text: NSLocalizedString("legalNoticeButton", comment: "Legal notice button")
        ) {
            guard let url = URL(string: "https://www.patrick-lanham.de/datenschutz.html") else { return }
            UIApplication.shared.open(url)
        }
    }
    
    private var usingConditionsButton: some View {
        LinkButton(
            icon: "lock.document.fill",
            text: NSLocalizedString("termsButton", comment: "Terms of use button")
        ) {
            guard let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") else { return }
            UIApplication.shared.open(url)
        }
    }
    
    private func updateWindowTheme(isDarkMode: Bool) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first?
            .overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
}

#Preview {
    SettingsView()
}
