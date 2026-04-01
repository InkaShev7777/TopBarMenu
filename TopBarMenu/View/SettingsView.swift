import SwiftUI

struct SettingsView: View {
    @State var isShowRGB: Bool = false // use the core data for reminding the state
    
    var body: some View {
        VStack {
            
            HStack {
                Text("TopBarMenu")
                    .font(.largeTitle)
            }
            .padding(.top, 40)
            
            Spacer()
            
            VStack {
                HStack {
                    Text("Show RGB colors in tab")
                    
                    Spacer()
                    
                    Toggle("", isOn: $isShowRGB)
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Frequency of data updates")
                    
                    Spacer()
                    
                    TimePeacker()
                }
                .padding(.horizontal)
            }
            
            Spacer()
            Spacer()
        }
        .frame(width: 300, height: 500)
        .navigationTitle("Settings")
    }
}

struct TimePeacker: View {
    @State private var selected = ""
    
    let options = ["1 sec", "5 sec", "10 sec", "15 sec", "20 sec"]
    
    init() {
        self.selected = options[0]
    }
    
    var body: some View {
        Picker("", selection: $selected) {
            ForEach(options, id: \.self) { option in
                Text(option)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    SettingsView()
}
