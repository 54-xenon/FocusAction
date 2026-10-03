//
//  FocusActionWidgetBundle.swift
//  FocusActionWidget
//

import WidgetKit
import SwiftUI

@main
struct FocusActionWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        HistoryWidget()
        FocusLiveActivity()
    }
}
