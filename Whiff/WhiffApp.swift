//
//  WhiffApp.swift
//  Whiff
//
//  Created by 신희영 on 2025/05/20.
//

import SwiftUI

@main
struct WhiffApp: App {
    @StateObject private var projectStore = ProjectStore()
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(projectStore)
                .environmentObject(authViewModel)
        }
    }
}
