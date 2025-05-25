import SwiftUI

struct HomeCardView: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
