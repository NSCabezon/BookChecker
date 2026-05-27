import SwiftUI
import SwiftData

@main
struct BookCheckerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Book.self])
        // TODO: Cuando crees el iCloud container en App Store Connect, cambiar a:
        // ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.ivancabezon.BookChecker"))
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct RootView: View {
    var body: some View {
        TabView {
            ScannerView()
                .tabItem { Label("Scan", systemImage: "barcode.viewfinder") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
        }
    }
}
