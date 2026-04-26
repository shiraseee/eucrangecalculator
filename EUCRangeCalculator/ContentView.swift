import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalculatorView()
                .tabItem {
                    Label("tab.calculator", systemImage: "function")
                }

            LiveModeView()
                .tabItem {
                    Label("tab.live", systemImage: "speedometer")
                }
        }
    }
}

#Preview {
    ContentView()
}
