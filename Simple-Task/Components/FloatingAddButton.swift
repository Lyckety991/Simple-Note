//
//  FloatingAddButton.swift
//  Simple-Task
//
//  Created by Patrick Lanham on 11.02.25.
//

import SwiftUI

struct FloatingAddButton: View {
    @Binding var isShowingAddTaskSheet: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Button {
            isShowingAddTaskSheet.toggle()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(isDarkMode ? Color.black : Color.white)
                .frame(width: 60, height: 60)
                .background(isDarkMode ? Color.white : Color.black)
                .clipShape(Circle())
                .shadow(radius: 5)
        }
    }
}

// Vorschau mit Binding-Wert
#Preview {
    FloatingAddButton(isShowingAddTaskSheet: .constant(false))
}

