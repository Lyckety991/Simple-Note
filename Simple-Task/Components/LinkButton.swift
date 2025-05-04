//
//  LinkButton.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 03.05.25.
//

import SwiftUI

struct LinkButton: View {
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(text)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isDarkMode ? .white : .black)
            .cornerRadius(8)
        }
    }
}

#Preview {
    LinkButton(icon: "mail", text: "Email", action: {})
}
