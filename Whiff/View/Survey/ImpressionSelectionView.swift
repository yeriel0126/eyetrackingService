import SwiftUI

struct ImpressionSelectionView: View {
    @Binding var selectedImpression: String?
    var onNext: () -> Void
    var onBack: () -> Void

    let impressions: [Option] = [
        .init(name: "Confident", imageName: "confident_img"),
        .init(name: "Elegant", imageName: "elegant_img"),
        .init(name: "Pure", imageName: "pure_img"),
        .init(name: "Friendly", imageName: "friendly_img"),
        .init(name: "Mysterious", imageName: "mysterious_img"),
        .init(name: "Fresh", imageName: "fresh_img")
    ]

    var body: some View {
        SelectionGridView(
            options: impressions,
            selectedOption: $selectedImpression,
            title: "어떤 인상을 주고 싶으신가요?",
            onNext: onNext,
            onBack: onBack
        )
    }
} 