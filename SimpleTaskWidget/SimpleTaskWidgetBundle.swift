//
//  SimpleTaskWidgetBundle.swift
//  SimpleTaskWidget
//
//  Created by Patrick Lanham on 28.03.25.
//

import WidgetKit
import SwiftUI

@main
struct SimpleTaskWidgetBundle: WidgetBundle {
    var body: some Widget {
       
        SimpleTaskWidgetControl()
        SimpleTaskWidgetLiveActivity()
    }
}
