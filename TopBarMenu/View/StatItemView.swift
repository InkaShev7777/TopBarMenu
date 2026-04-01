import Foundation
import SwiftUI

struct StatItemView: View {
    let icon: String
    let value: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text("\(Int(value))%")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 2)
    }
}
