import SwiftUI

struct EmotionTagButton: View {
    let tag: EmotionTag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tag.name)
                        .font(.subheadline)
                        .bold()
                    Text("(\(Int(tag.confidence * 100))%)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let category = tag.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                if let description = tag.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
} 