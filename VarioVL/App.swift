import SwiftUI

@main
struct VarioVLApp: App {
    @StateObject private var modele = Modele()

    var body: some Scene {
        WindowGroup {
            Ecran()
                .environmentObject(modele)
                .onAppear { modele.demarrer() }
        }
    }
}
