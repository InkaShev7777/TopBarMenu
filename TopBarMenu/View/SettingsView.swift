import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings of app")
                .font(.title)
                .padding()
            
            Divider()
            
            Text("Здесь можно будет добавить настройки")
            Spacer()
        }
        .frame(width: 300, height: 500)
    }
}

#Preview {
    SettingsView()
}
