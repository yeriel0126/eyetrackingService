import SwiftUI

struct SurveyView: View {
    @StateObject private var viewModel = SurveyViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 향수 선택 섹션
                Section(header: Text("향수")) {
                    if let perfume = viewModel.selectedPerfume {
                        HStack {
                            Text(perfume.name)
                            Spacer()
                            Text(perfume.brand)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button("향수 선택하기") {
                            viewModel.showingPerfumePicker = true
                        }
                    }
                }
                
                // 일기 내용 섹션
                Section(header: Text("일기")) {
                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 100)
                }
                
                // 태그 섹션
                Section(header: Text("태그")) {
                    HStack {
                        TextField("태그 입력", text: $viewModel.tagInput)
                            .onSubmit {
                                viewModel.addTag()
                            }
                        
                        Button("추가") {
                            viewModel.addTag()
                        }
                    }
                    
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.tags, id: \.self) { tag in
                            TagView(tag: tag) {
                                viewModel.removeTag(tag)
                            }
                        }
                    }
                }
                
                // 공개 설정 섹션
                Section {
                    Toggle("공개", isOn: $viewModel.isPublic)
                }
            }
            .navigationTitle("새로운 향수 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        Task {
                            do {
                                try await viewModel.saveDiary()
                                dismiss()
                            } catch {
                                viewModel.error = error
                                viewModel.showingAlert = true
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .sheet(isPresented: $viewModel.showingPerfumePicker) {
                PerfumePickerView(selectedPerfume: $viewModel.selectedPerfume)
            }
            .alert("오류", isPresented: $viewModel.showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "")
            }
        }
    }
}

class SurveyViewModel: ObservableObject {
    @Published var selectedPerfume: Perfume?
    @Published var content: String = ""
    @Published var tagInput: String = ""
    @Published var tags: [String] = []
    @Published var isPublic: Bool = true
    @Published var error: Error?
    @Published var isLoading = false
    @Published var showingPerfumePicker = false
    @Published var showingAlert = false
    
    private let apiClient = APIClient.shared
    
    func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            tagInput = ""
        }
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    func saveDiary() async throws {
        guard !content.isEmpty else {
            throw DiaryError.emptyContent
        }
        
        guard let perfume = selectedPerfume else {
            throw DiaryError.noPerfumeSelected
        }
        
        isLoading = true
        error = nil
        
        do {
            let diary = ScentDiaryModel(
                id: UUID().uuidString,
                userId: UserDefaults.standard.string(forKey: "userId") ?? "",
                userName: UserDefaults.standard.string(forKey: "userName") ?? "사용자",
                perfumeId: perfume.id,
                perfumeName: perfume.name,
                brand: perfume.brand,
                content: content,
                tags: tags,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await apiClient.createDiary(diary: diary)
        } catch {
            self.error = error
            throw error
        }
        
        isLoading = false
    }
}

struct SurveyView_Previews: PreviewProvider {
    static var previews: some View {
        SurveyView()
    }
}
