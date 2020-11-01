//
//  normal_activityApp.swift
//  normal_activity WatchKit Extension
//
//  Created by koki-ta on 2020/09/27.
//

import SwiftUI

@main
struct normal_activityApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(DeepViewModel())
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
