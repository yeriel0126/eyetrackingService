import SwiftUI

struct WeatherSelectionView: View {
    @Binding var selectedWeather: String?
    var onNext: () -> Void
    var onBack: () -> Void

    let weathers: [Option] = [
        .init(name: "Hot", imageName: "hot_img"),
        .init(name: "Cold", imageName: "cold_img"),
        .init(name: "Rainy", imageName: "rainy_img"),
        .init(name: "Any", imageName: "any_img")
    ]

    var body: some View {
        SelectionGridView(
            options: weathers,
            selectedOption: $selectedWeather,
            title: "어떤 날씨에 어울리는 향이 좋으신가요?",
            onNext: onNext,
            onBack: onBack
        )
    }
} 