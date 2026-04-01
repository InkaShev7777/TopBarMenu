import Foundation
import SwiftUI

struct MenuBarView: View {
    let cpu: Double
    let ram: Double
    let disk: Double
    
    var body: some View {
        HStack(spacing: 12) {
            StatItemView(icon: "cpu", value: cpu)
            StatItemView(icon: "memorychip", value: ram)
            StatItemView(icon: "server.rack", value: disk)
        }
        .padding(.horizontal, 6)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 24, maxHeight: 24)
        .foregroundColor(.white)
    }
}
