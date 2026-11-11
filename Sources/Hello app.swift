import SwiftUI

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup {
            Text("otis woz here <3")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}
