import SwiftUI

struct DiaryWritingView: View {
    @Binding var diaryText: String
    @Binding var selectedEmotionTags: Set<EmotionTag>
    let suggestedEmotionTags: [EmotionTag]
    let isAnalyzing: Bool
    let errorMessage: String?
    let onAnalyze: () -> Void
    let onTagSelected: (EmotionTag) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시향 일기")
                .font(.headline)
            
            TextEditor(text: $diaryText)
                .frame(height: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: diaryText) { oldValue, newValue in
                    onAnalyze()
                }
            
            if isAnalyzing {
                ProgressView("감정 태그 분석 중...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if !suggestedEmotionTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("추천 감정 태그")
                        .font(.subheadline)
                    
                    FlowLayoutView(spacing: 8) {
                        ForEach(suggestedEmotionTags) { tag in
                            EmotionTagButton(
                                tag: tag,
                                isSelected: selectedEmotionTags.contains(tag),
                                onTap: {
                                    onTagSelected(tag)
                                }
                            )
                        }
                    }
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}

struct DiaryWritingView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryWritingView(
            diaryText: .constant("오늘의 시향 일기..."),
            selectedEmotionTags: .constant([]),
            suggestedEmotionTags: [
                EmotionTag(id: "1", name: "행복", confidence: 0.9, category: "긍정", description: "기쁨과 만족감을 느끼는 상태"),
                EmotionTag(id: "2", name: "평온", confidence: 0.8, category: "긍정", description: "마음이 차분하고 안정된 상태")
            ],
            isAnalyzing: false,
            errorMessage: nil,
            onAnalyze: {},
            onTagSelected: { _ in }
        )
        .padding()
    }
} 