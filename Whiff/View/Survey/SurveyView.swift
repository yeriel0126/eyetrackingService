import SwiftUI

struct SurveyView: View {
    let projectName: String
    @State private var step = 1
    @State private var selectedGender: String?
    @State private var selectedSeason: String?
    @State private var selectedTime: String?
    @State private var selectedImpression: String?
    @State private var selectedActivity: String?
    @State private var selectedWeather: String?
    @EnvironmentObject var projectStore: ProjectStore

    var body: some View {
        VStack {
            switch step {
            case 1:
                GenderSelectionView(selectedGender: $selectedGender) {
                    step = 2
                }

            case 2:
                SeasonSelectionView(selectedSeason: $selectedSeason, onNext: {
                    step = 3
                }, onBack: {
                    step = 1
                })

            case 3:
                TimeSelectionView(selectedTime: $selectedTime, onNext: {
                    step = 4
                }, onBack: {
                    step = 2
                })
                
            case 4:
                ImpressionSelectionView(selectedImpression: $selectedImpression, onNext: {
                    step = 5
                }, onBack: {
                    step = 3
                })
                
            case 5:
                ActivitySelectionView(selectedActivity: $selectedActivity, onNext: {
                    step = 6
                }, onBack: {
                    step = 4
                })
                
            case 6:
                WeatherSelectionView(selectedWeather: $selectedWeather, onNext: {
                    step = 7
                }, onBack: {
                    step = 5
                })

            case 7:
                RecommendationResultView(
                    projectName: projectName,
                    gender: selectedGender ?? "",
                    season: selectedSeason ?? "",
                    time: selectedTime ?? "",
                    impression: selectedImpression ?? "",
                    activity: selectedActivity ?? "",
                    weather: selectedWeather ?? ""
                )
                .environmentObject(projectStore)

            default:
                EmptyView()
            }
        }
    }
}
