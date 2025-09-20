//
//  TestApp01App.swift
//  TestApp01
//
//  Created by Malavika on 20/09/25.
//

import SwiftUI

@main
struct TestApp01App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
