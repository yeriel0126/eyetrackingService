import SwiftUI
import PhotosUI

// MARK: - Store
@MainActor
class ScentDiaryStore: ObservableObject {
    @Published var selectedPerfume: Perfume?
    @Published var diaryText: String = ""
    @Published var selectedImage: UIImage?
    @Published var selectedEmotionTags: Set<EmotionTag> = []
    @Published var suggestedEmotionTags: [EmotionTag] = []
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    
    private let apiClient = APIClient.shared
    
    func analyzeText() async {
        guard !diaryText.isEmpty else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        do {
            let tags = try await apiClient.getEmotionTags(from: diaryText)
            suggestedEmotionTags = tags
        } catch {
            errorMessage = "감정 분석 중 오류가 발생했습니다: \(error.localizedDescription)"
        }
        
        isAnalyzing = false
    }
    
    func toggleEmotionTag(_ tag: EmotionTag) {
        if selectedEmotionTags.contains(tag) {
            selectedEmotionTags.remove(tag)
        } else {
            selectedEmotionTags.insert(tag)
        }
    }
    
    func saveDiary() async throws {
        // TODO: 이미지 업로드 및 일기 저장 로직 구현
        // 1. 이미지가 있다면 먼저 이미지를 업로드
        // 2. 이미지 URL과 함께 일기 데이터 저장
        // 3. 선택된 감정 태그도 함께 저장
    }
}

// MARK: - Views
struct NewScentDiaryView: View {
    @StateObject private var viewModel = NewScentDiaryViewModel()
    @StateObject private var scentDiaryViewModel = ScentDiaryViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    @State private var showingPerfumePicker = false
    @State private var showingAlert = false
    @State private var suggestedTags: [String] = []
    @State private var selectedEmotionTags: Set<String> = []
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isLoadingImage = false
    @State private var showingPerfumeMentions = false
    @State private var searchText = ""
    @State private var availablePerfumes: [Perfume] = []
    @State private var hashtags: Set<String> = []
    @State private var selectedPerfumeName: String = "" // 직접 선택한 향수명
    @FocusState private var isTextEditorFocused: Bool
    @State private var isAnalyzingEmotion = false
    @State private var showingImageEditor = false
    @State private var originalImage: UIImage? = nil
    @State private var customTagText = ""
    @State private var manualTags: Set<String> = []
    
    // 현재 사용자 정보
    private var currentUser: UserData? {
        authViewModel.user?.data
    }
    
    private var currentUserId: String {
        if let user = currentUser {
            return user.uid
        }
        // 로그인하지 않은 경우 기본값
        return UserDefaults.standard.string(forKey: "currentUserId") ?? UUID().uuidString
    }
    
    private var currentUserName: String {
        if let user = currentUser, let name = user.name {
            return name
        }
        // 로그인하지 않은 경우 기본값
        return UserDefaults.standard.string(forKey: "currentUserName") ?? "사용자"
    }
    
    private var currentUserProfileImage: String {
        if let user = currentUser, let picture = user.picture {
            return picture
        }
        // 로그인하지 않은 경우 기본값
        return UserDefaults.standard.string(forKey: "currentUserProfileImage") ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                CustomNavigationBar()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // 사진 선택 영역 (상단 고정)
                        PhotoSelectionArea()
                        
                        // 구분선
                        Divider()
                            .padding(.vertical, 8)
                        
                        // 텍스트 입력 영역
                        PostContentArea()
                        
                        // 감정 태그 섹션 (항상 표시)
                        EmotionTagArea()
                        
                        // 설정 영역
                        SettingsArea()
                        
                        // 하단 여백
                        Color.clear.frame(height: 100)
                    }
                }
                
                // 하단 고정 저장 버튼
                BottomSaveButton()
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .alert("오류", isPresented: $scentDiaryViewModel.showError) {
                Button("확인") {
                    scentDiaryViewModel.clearError()
                }
            } message: {
                Text(scentDiaryViewModel.error?.localizedDescription ?? "알 수 없는 오류가 발생했습니다.")
            }
            .sheet(isPresented: $showingImageEditor) {
                if let originalImage = originalImage {
                    ImageEditorView(originalImage: originalImage) { editedImage in
                        selectedImage = editedImage
                        showingImageEditor = false
                    } onCancel: {
                        showingImageEditor = false
                    }
                }
            }
        }
        .task {
            await loadAvailablePerfumes()
        }
    }
    
    // MARK: - 하위 뷰들
    
    @ViewBuilder
    private func CustomNavigationBar() -> some View {
        HStack {
            Button("취소") {
                                dismiss()
            }
            .foregroundColor(.primary)
            
            Spacer()
            
            Text("새 게시물")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    @ViewBuilder
    private func PhotoSelectionArea() -> some View {
        VStack(spacing: 0) {
            if let selectedImage = selectedImage {
                // 선택된 이미지 표시
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: UIScreen.main.bounds.width) // 정사각형
                    .clipped()
                    .overlay(
                        // 이미지 편집 버튼
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    originalImage = selectedImage
                                    showingImageEditor = true
                                }) {
                                    Image(systemName: "crop")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Spacer()
                                PhotosPicker(
                                    selection: $selectedItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Image(systemName: "photo")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                                .padding(.bottom, 12)
                                .padding(.trailing, 12)
                            }
                        }
                    )
            } else if isLoadingImage {
                // 로딩 상태
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text("이미지 로딩 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
            } else {
                // 사진 선택 프롬프트
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("사진 추가")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("터치하여 갤러리에서 사진을 선택하세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private func PostContentArea() -> some View {
        VStack(spacing: 12) {
            // 사용자 헤더
            HStack(spacing: 12) {
                if !currentUserProfileImage.isEmpty {
                    AsyncImage(url: URL(string: currentUserProfileImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentUserName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("지금")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            // 텍스트 입력 영역
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(minHeight: 120)
                    
                    if viewModel.content.isEmpty && !isTextEditorFocused {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("오늘의 향수와 함께한 이야기를 들려주세요...")
                                .foregroundColor(.secondary)
                            
                            Text("@향수이름 으로 향수를 언급해보세요!")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $viewModel.content)
                        .focused($isTextEditorFocused)
                        .background(Color.clear)
                        .frame(minHeight: 120)
                        .padding(.horizontal, 8)
                        .onChange(of: viewModel.content) { _, _ in
                            updateSuggestedTags()
                            detectHashtags()
                        }
                }
                
                // 해시태그 표시
                if !hashtags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // 해시태그 표시
                            ForEach(Array(hashtags), id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Image(systemName: "number")
                                        .font(.caption)
                                    Text(tag)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // 향수 선택 영역
                VStack(alignment: .leading, spacing: 8) {
                    Text("향수 선택")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if selectedPerfumeName.isEmpty {
                        Button(action: {
                            showingPerfumeMentions = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                Text("향수 선택하기")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.blue)
                                Text(selectedPerfumeName)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                            
                            Spacer()
                            
                            Button(action: {
                                showingPerfumeMentions = true
                            }) {
                                Text("변경")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                selectedPerfumeName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showingPerfumeMentions) {
            PerfumeSearchView(
                availablePerfumes: availablePerfumes,
                onPerfumeSelected: { perfume in
                    selectedPerfumeName = perfume.name
                    print("✅ [향수 선택] 선택된 향수: \(perfume.name)")
                    showingPerfumeMentions = false
                }
            )
        }
    }
    
    @ViewBuilder
    private func EmotionTagArea() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("감정 태그")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // AI 분석 상태 및 결과
            VStack(alignment: .leading, spacing: 12) {
                // AI 상태 표시
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                        .font(.caption)
                    
                    if isAnalyzingEmotion {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("AI가 텍스트 기반으로 감정 태그를 찾고 있습니다...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("텍스트를 입력하면 AI가 감정을 분석해드려요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if suggestedTags.isEmpty {
                        Text("더 자세한 내용을 작성하면 AI가 감정을 분석해드려요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("AI가 추천하는 감정 태그")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // AI 추천 태그들
                if !suggestedTags.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80))
                    ], spacing: 8) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button(action: {
                                toggleEmotionTag(tag)
                            }) {
                                HStack(spacing: 4) {
                                    if selectedEmotionTags.contains(tag) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                    }
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedEmotionTags.contains(tag) ? Color.purple : Color(.systemGray5))
                                .foregroundColor(selectedEmotionTags.contains(tag) ? .white : .primary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedEmotionTags.contains(tag) ? Color.purple : Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 구분선
            Divider()
                .padding(.horizontal)
            
            // 사용자 직접 입력 섹션
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("직접 태그 추가")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(.horizontal)
                
                // 태그 입력 필드
                HStack(spacing: 12) {
                    TextField("태그 입력 (예: 상쾌한, 달콤한)", text: $customTagText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            addCustomTag()
                        }
                    
                    Button("추가") {
                        addCustomTag()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(customTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .clipShape(Capsule())
                    .disabled(customTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                
                // 사용자가 추가한 태그들
                if !manualTags.isEmpty {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80))
                    ], spacing: 8) {
                        ForEach(Array(manualTags), id: \.self) { tag in
                            Button(action: {
                                removeManualTag(tag)
                            }) {
                                HStack(spacing: 4) {
                            Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 선택된 모든 태그 요약
            if !selectedEmotionTags.isEmpty || !manualTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("선택된 태그 (\(selectedEmotionTags.count + manualTags.count)개)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Text(Array(selectedEmotionTags.union(manualTags)).joined(separator: " • "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color.green.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func SettingsArea() -> some View {
        VStack(spacing: 16) {
            // 공개 설정
            HStack {
                Image(systemName: viewModel.isPublic ? "globe" : "lock.fill")
                    .foregroundColor(viewModel.isPublic ? .blue : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isPublic ? "공개 게시물" : "비공개 게시물")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(viewModel.isPublic ? "다른 사용자들이 이 게시물을 볼 수 있습니다" : "나만 볼 수 있는 비공개 게시물입니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isPublic)
                    .labelsHidden()
                    .onChange(of: viewModel.isPublic) { oldValue, newValue in
                        print("🔐 [UI Toggle 변경] \(oldValue) → \(newValue)")
                        print("🔐 [UI Toggle 변경] 현재 상태: \(newValue ? "공개" : "비공개")")
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    @ViewBuilder
    private func BottomSaveButton() -> some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: saveDiary) {
                HStack {
                    if scentDiaryViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(scentDiaryViewModel.isLoading ? "게시 중..." : "게시하기")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSave || scentDiaryViewModel.isLoading)
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - 계산 속성
    
    private var canSave: Bool {
        let hasContent = !viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = selectedImage != nil
        
        // 내용이나 이미지 중 하나만 있으면 게시 가능
        return hasContent || hasImage
    }
    
    // MARK: - 메서드
    
    private func updateSuggestedTags() {
        // 백엔드 AI 기반 감정 태그 추천 사용
        Task {
            await analyzeSentimentAndSuggestTags()
        }
    }
    
    /// 백엔드 AI를 활용한 감정 분석 및 태그 추천
    @MainActor
    private func analyzeSentimentAndSuggestTags() async {
        let content = viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 내용이 없거나 너무 짧으면 분석하지 않음
        guard !content.isEmpty && content.count >= 5 else {
            suggestedTags = []
            isAnalyzingEmotion = false
            return
        }
        
        // 로딩 상태 시작
        isAnalyzingEmotion = true
        
        // 약간의 지연 (사용자가 타이핑을 멈출 때까지 기다림)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1초 디바운스
        
        // 타이핑이 계속되고 있다면 분석하지 않음
        guard content == viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines) else {
            isAnalyzingEmotion = false
            return
        }
        
        do {
            print("🤖 [AI 감정 분석] 텍스트 분석 시작: '\(content.prefix(50))...'")
            
            // 백엔드 AI API를 통한 감정 태그 추천
            let emotionTags = try await APIClient.shared.getEmotionTags(from: content)
            
            // EmotionTag에서 String으로 변환
            suggestedTags = emotionTags.map { $0.name }
            
            print("✅ [AI 감정 분석] 추천 태그: \(suggestedTags)")
            
        } catch {
            print("⚠️ [AI 감정 분석] 백엔드 실패, 로컬 분석으로 폴백: \(error)")
            
            // 백엔드 실패 시 로컬 키워드 기반 폴백
            suggestedTags = scentDiaryViewModel.suggestEmotionTags(for: content)
            
            print("🔄 [로컬 감정 분석] 추천 태그: \(suggestedTags)")
        }
        
        // 로딩 상태 종료
        isAnalyzingEmotion = false
    }
    
    private func toggleEmotionTag(_ tag: String) {
        if selectedEmotionTags.contains(tag) {
            selectedEmotionTags.remove(tag)
        } else {
            selectedEmotionTags.insert(tag)
        }
    }
    

    
    private func addCustomTag() {
        let tag = customTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !tag.isEmpty && !manualTags.contains(tag) && !selectedEmotionTags.contains(tag) else { 
            return 
        }
        
        manualTags.insert(tag)
        customTagText = ""
    }
    
    private func removeManualTag(_ tag: String) {
        manualTags.remove(tag)
    }
    
    private func addHashtag() {
        // 간단한 해시태그 추가 기능 - 일반적인 태그들 제안
        let commonTags = ["일상", "데이터", "출근", "여행", "휴식", "기분좋은", "상쾌한", "따뜻한", "시원한", "우아한"]
        let availableTags = commonTags.filter { !hashtags.contains($0) }
        
        if let randomTag = availableTags.randomElement() {
            if viewModel.content.isEmpty {
                viewModel.content = "#\(randomTag) "
            } else {
                viewModel.content += " #\(randomTag)"
            }
            hashtags.insert(randomTag)
        }
    }
    
    private func loadAvailablePerfumes() async {
        do {
            let networkManager = NetworkManager.shared
            availablePerfumes = try await networkManager.fetchPerfumes()
        } catch {
            print("향수 로딩 실패: \(error)")
            availablePerfumes = PerfumeDataUtils.createSamplePerfumes()
        }
    }
    
    private func saveDiary() {
        // 해시태그 감지 업데이트
        detectHashtags()
        
        // 직접 선택한 향수명 사용, 없으면 기본값
        let perfumeName = selectedPerfumeName.isEmpty ? "향수 없음" : selectedPerfumeName
        
        // AI 추천 태그, 사용자 직접 입력 태그, 해시태그를 모두 합쳐서 저장
        let allTags = Array(selectedEmotionTags) + Array(manualTags) + Array(hashtags)
        
        // 현재 사용자 정보를 UserDefaults에 저장 (프로필 연동용)
        UserDefaults.standard.set(currentUserId, forKey: "currentUserId")
        UserDefaults.standard.set(currentUserName, forKey: "currentUserName")
        UserDefaults.standard.set(currentUserProfileImage, forKey: "currentUserProfileImage")
        UserDefaults.standard.synchronize()
        
        print("💾 [사용자 정보 저장] ID: \(currentUserId)")
        print("💾 [사용자 정보 저장] 이름: \(currentUserName)")
        print("💾 [사용자 정보 저장] 프로필: \(currentUserProfileImage)")
        print("🔐 [공개 설정 확인] viewModel.isPublic: \(viewModel.isPublic)")
        print("🔐 [공개 설정 확인] UI Toggle 상태: \(viewModel.isPublic ? "공개" : "비공개")")
        
        print("📝 [일기 내용 확인] 원본 내용: '\(viewModel.content)'")
        print("📝 [일기 내용 확인] 트림 후: '\(viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines))'")
        print("📝 [향수 확인] 선택한 향수명: '\(perfumeName)'")
        print("📝 [태그 확인] 모든 태그: \(allTags)")
        print("📝 [해시태그 확인] 해시태그: \(hashtags)")
        print("📝 [이미지 확인] 이미지 있음: \(selectedImage != nil)")
        
        if allTags.isEmpty {
            print("⚠️ [태그 경고] 태그가 하나도 없습니다!")
        }
        if viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️ [내용 경고] 일기 내용이 비어있습니다!")
        }
        
        Task {
            let success = await scentDiaryViewModel.createDiary(
                userId: currentUserId,
                perfumeName: perfumeName,
                content: viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines),
                isPublic: viewModel.isPublic,
                emotionTags: allTags,
                selectedImage: selectedImage
            )
            
            if success {
                print("✅ [NewScentDiaryView] 시향 일기 게시 성공")
                
                // createDiary에서 이미 피드에 실시간 추가되므로 fetchDiaries 호출 불필요
                // await scentDiaryViewModel.fetchDiaries() // 제거
                
                // 탭 이동
                await MainActor.run {
                    selectedTab = 1 // 시향 일기 탭 (인덱스 1)
                    dismiss()
                }
            } else {
                print("❌ [NewScentDiaryView] 시향 일기 게시 실패")
            }
        }
    }
    
    private func detectHashtags() {
        // # 기호로 시작하는 해시태그 감지
        let hashPattern = "#([\\p{L}\\p{N}가-힣]+)"
        let hashRegex = try? NSRegularExpression(pattern: hashPattern, options: [])
        let range = NSRange(location: 0, length: viewModel.content.utf16.count)
        
        var newHashtags: Set<String> = []
        
        hashRegex?.enumerateMatches(in: viewModel.content, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range(at: 1),
               let range = Range(matchRange, in: viewModel.content) {
                let hashtagText = String(viewModel.content[range]).trimmingCharacters(in: .whitespaces)
                if !hashtagText.isEmpty {
                    newHashtags.insert(hashtagText)
                }
            }
        }
        
        hashtags = newHashtags
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { 
            selectedImage = nil
            return 
        }
        
        await MainActor.run {
            isLoadingImage = true
        }
        
        do {
            // Data 타입으로 로드한 후 UIImage로 변환
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    originalImage = uiImage  // 원본 이미지 저장
                    selectedImage = uiImage  // 임시로 표시
                    isLoadingImage = false
                    showingImageEditor = true  // 편집 화면으로 이동
                }
                print("✅ [이미지 로딩] Data 변환으로 성공, 편집 화면 표시")
                return
            }
            
            // 데이터 로드 실패
            print("❌ [이미지 로딩] 데이터 로드 실패 또는 이미지 변환 실패")
            await MainActor.run {
                selectedImage = nil
                originalImage = nil
                isLoadingImage = false
            }
            
        } catch {
            print("❌ [이미지 로딩] 오류 발생: \(error.localizedDescription)")
            await MainActor.run {
                selectedImage = nil
                originalImage = nil
                isLoadingImage = false
            }
        }
    }
}

// MARK: - Perfume Search View
private struct PerfumeSearchView: View {
    let availablePerfumes: [Perfume]
    let onPerfumeSelected: (Perfume) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredPerfumes) { perfume in
                    Button(action: {
                        onPerfumeSelected(perfume)
                    }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: perfume.imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(perfume.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(perfume.brand)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "향수 검색")
            .navigationTitle("향수 언급")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredPerfumes: [Perfume] {
        if searchText.isEmpty {
            return Array(availablePerfumes.prefix(20)) // 처음 20개만 표시
        } else {
            return availablePerfumes.filter { perfume in
                perfume.name.localizedCaseInsensitiveContains(searchText) ||
                perfume.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct NewScentDiaryView_Previews: PreviewProvider {
    static var previews: some View {
        NewScentDiaryView(selectedTab: .constant(0))
            .environmentObject(AuthViewModel())
    }
}

// MARK: - Image Editor View
struct ImageEditorView: View {
    let originalImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0.0
    @State private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var showingAspectRatios = false
    @State private var selectedAspectRatio: AspectRatio = .square
    
    enum AspectRatio: String, CaseIterable {
        case original = "원본"
        case square = "1:1"
        case portrait = "4:5"
        case landscape = "16:9"
        
        var ratio: CGFloat? {
            switch self {
            case .original: return nil
            case .square: return 1.0
            case .portrait: return 4.0/5.0
            case .landscape: return 16.0/9.0
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 네비게이션
                HStack {
                    Button("취소") {
                        onCancel()
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    Text("편집")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        print("✅ [이미지 편집] 완료 버튼 클릭됨")
                        saveEditedImage()
                    }) {
                        Text("완료")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 100, height: 50)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .frame(width: 100, height: 50)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // 이미지 편집 영역
                GeometryReader { geometry in
                    ZStack {
                        Color(.systemBackground)
                        
                        // 크롭 오버레이가 있는 이미지
                        CroppableImageView(
                            image: originalImage,
                            scale: $scale,
                            offset: $offset,
                            rotation: $rotation,
                            aspectRatio: selectedAspectRatio.ratio,
                            availableSize: geometry.size
                        )
                    }
                }
                
                // 하단 컨트롤
                VStack(spacing: 16) {
                    // 비율 선택 버튼들
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(AspectRatio.allCases, id: \.self) { ratio in
                                Button(action: {
                                    selectedAspectRatio = ratio
                                    resetTransform()
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: getAspectRatioIcon(ratio))
                                            .font(.title2)
                                        Text(ratio.rawValue)
                                            .font(.caption)
                                    }
                                    .foregroundColor(selectedAspectRatio == ratio ? .blue : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 조정 슬라이더들
                    VStack(spacing: 12) {
                        // 확대/축소
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                                .foregroundColor(.secondary)
                            Slider(value: $scale, in: 0.5...3.0)
                                .accentColor(.blue)
                            Image(systemName: "plus.magnifyingglass")
                                .foregroundColor(.secondary)
                        }
                        
                        // 회전
                        HStack {
                            Image(systemName: "rotate.left")
                                .foregroundColor(.secondary)
                            Slider(value: $rotation, in: -180...180)
                                .accentColor(.blue)
                            Image(systemName: "rotate.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 리셋 버튼
                    Button("초기화") {
                        resetTransform()
                    }
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }
    
    private func getAspectRatioIcon(_ ratio: AspectRatio) -> String {
        switch ratio {
        case .original: return "rectangle"
        case .square: return "square"
        case .portrait: return "rectangle.portrait"
        case .landscape: return "rectangle"
        }
    }
    
    private func resetTransform() {
        withAnimation(.easeInOut(duration: 0.3)) {
            scale = 1.0
            offset = .zero
            rotation = 0.0
        }
    }
    
    private func saveEditedImage() {
        print("✅ [이미지 편집] saveEditedImage 호출됨")
        
        // 편집된 이미지 생성
        let editedImage = generateEditedImage()
        print("✅ [이미지 편집] 편집된 이미지 생성 완료: \(editedImage.size)")
        
        onSave(editedImage)
        print("✅ [이미지 편집] onSave 콜백 호출 완료")
    }
    
    private func generateEditedImage() -> UIImage {
        print("🖼️ [이미지 편집] 크롭 시작")
        
        // 1. 원본 이미지의 orientation을 고려한 정규화된 이미지 생성
        let normalizedImage = normalizeImageOrientation(originalImage)
        let originalSize = normalizedImage.size
        
        print("🖼️ [원본 이미지] 크기: \(originalSize)")
        print("🖼️ [편집 상태] scale: \(scale), offset: \(offset), rotation: \(rotation)")
        
        // 2. 화면 크기 및 편집 영역 계산
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height - 400 // 상단 네비게이션 + 하단 컨트롤 제외
        let padding: CGFloat = 40
        
        // 실제 편집 가능한 영역 크기
        let availableWidth = screenWidth - padding * 2
        let availableHeight = screenHeight - padding * 2
        
        // 이미지가 .aspectRatio(contentMode: .fit)로 표시되므로 실제 표시 크기 계산
        let imageAspectRatio = originalSize.width / originalSize.height
        let containerAspectRatio = availableWidth / availableHeight
        
        let displaySize: CGSize
        if imageAspectRatio > containerAspectRatio {
            // 이미지가 더 넓음 - 가용 너비에 맞춤
            displaySize = CGSize(width: availableWidth, height: availableWidth / imageAspectRatio)
        } else {
            // 이미지가 더 높음 - 가용 높이에 맞춤
            displaySize = CGSize(width: availableHeight * imageAspectRatio, height: availableHeight)
        }
        
        print("🖼️ [이미지 표시 크기] \(displaySize)")
        
        // 3. 크롭 오버레이 크기 계산 (선택된 비율에 따라)
        let cropOverlaySize: CGSize
        if let ratio = selectedAspectRatio.ratio {
            if ratio == 1.0 {
                // 정사각형
                let size = min(availableWidth, availableHeight)
                cropOverlaySize = CGSize(width: size, height: size)
            } else if ratio < 1.0 {
                // 세로형 (4:5 등)
                let width = min(availableWidth, availableHeight * ratio)
                let height = width / ratio
                cropOverlaySize = CGSize(width: width, height: height)
            } else {
                // 가로형 (16:9 등)
                let height = min(availableHeight, availableWidth / ratio)
                let width = height * ratio
                cropOverlaySize = CGSize(width: width, height: height)
            }
        } else {
            // 원본 비율
            let size = min(availableWidth, availableHeight)
            cropOverlaySize = CGSize(width: size, height: size)
        }
        print("🖼️ [크롭 오버레이 크기] \(cropOverlaySize)")
        
        // 4. 스케일 및 오프셋을 원본 이미지 좌표계로 변환
        let imageToDisplayRatio = min(originalSize.width / displaySize.width, originalSize.height / displaySize.height)
        
        // 사용자 변환값을 원본 이미지 좌표계로 변환
        let scaledImageSize = CGSize(
            width: displaySize.width * scale,
            height: displaySize.height * scale
        )
        
        // 화면 중앙에서 크롭 영역까지의 오프셋을 원본 좌표로 변환
        let offsetInOriginalX = offset.width * imageToDisplayRatio
        let offsetInOriginalY = offset.height * imageToDisplayRatio
        
        // 크롭 영역 크기를 원본 이미지 좌표로 변환
        let cropSizeInOriginalWidth = cropOverlaySize.width * imageToDisplayRatio / scale
        let cropSizeInOriginalHeight = cropOverlaySize.height * imageToDisplayRatio / scale
        
        // 원본 이미지에서의 크롭 영역 중심점
        let centerX = originalSize.width / 2 - offsetInOriginalX
        let centerY = originalSize.height / 2 - offsetInOriginalY
        
        // 크롭 영역 경계 계산
        let cropX = max(0, centerX - cropSizeInOriginalWidth / 2)
        let cropY = max(0, centerY - cropSizeInOriginalHeight / 2)
        let cropWidth = min(cropSizeInOriginalWidth, originalSize.width - cropX)
        let cropHeight = min(cropSizeInOriginalHeight, originalSize.height - cropY)
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        print("🖼️ [최종 크롭 영역] \(cropRect)")
        
        // 5. 실제 크롭 수행
        guard let cgImage = normalizedImage.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            print("❌ [크롭 실패] 원본 반환")
            return originalImage
        }
        
        var croppedImage = UIImage(cgImage: croppedCGImage)
        
        // 6. 회전 적용 (필요한 경우)
        if abs(rotation) > 1.0 {
            croppedImage = rotateImage(croppedImage, by: rotation) ?? croppedImage
            print("🔄 [회전 적용] \(rotation)도")
        }
        
        // 7. 최종 크기로 리사이즈 (고품질 유지)
        let finalSize: CGFloat = 1080
        let finalImage: UIImage
        
        if selectedAspectRatio == .square {
            // 정사각형으로 리사이즈
            finalImage = resizeImageToSquare(croppedImage, size: finalSize)
        } else {
            // 선택된 비율에 맞춰 리사이즈
            finalImage = resizeImageToAspectRatio(croppedImage, aspectRatio: selectedAspectRatio, maxSize: finalSize)
        }
        
        print("✅ [크롭 완료] 최종 크기: \(finalImage.size)")
        return finalImage
    }
    
    /// UIImage의 orientation을 고려하여 정규화된 이미지 생성
    private func normalizeImageOrientation(_ image: UIImage) -> UIImage {
        // 이미지가 이미 정상 방향이면 그대로 반환
        if image.imageOrientation == .up {
            return image
        }
        
        // orientation을 고려하여 올바른 방향으로 렌더링
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    
    /// 이미지 회전 함수
    private func rotateImage(_ image: UIImage, by degrees: Double) -> UIImage? {
        let radians = degrees * .pi / 180.0
        
        // 회전된 이미지의 크기 계산
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        let cosValue = abs(cos(radians))
        let sinValue = abs(sin(radians))
        
        let rotatedWidth = cosValue * originalWidth + sinValue * originalHeight
        let rotatedHeight = sinValue * originalWidth + cosValue * originalHeight
        
        let rotatedSize = CGSize(width: rotatedWidth, height: rotatedHeight)
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        let rotatedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // 회전 중심을 이미지 중앙으로 이동
            cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            cgContext.rotate(by: radians)
            
            // 이미지 그리기
            image.draw(in: CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            ))
        }
        
        return rotatedImage
    }
    
    /// 이미지를 정사각형으로 리사이즈 (고품질)
    private func resizeImageToSquare(_ image: UIImage, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size),
            format: UIGraphicsImageRendererFormat.default()
        )
        
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        
        return resizedImage
    }
    
    /// 이미지를 지정된 비율로 리사이즈 (고품질)
    private func resizeImageToAspectRatio(_ image: UIImage, aspectRatio: AspectRatio, maxSize: CGFloat) -> UIImage {
        let targetSize = calculateTargetSize(for: image, aspectRatio: aspectRatio, maxSize: maxSize)
        
        let renderer = UIGraphicsImageRenderer(
            size: targetSize,
            format: UIGraphicsImageRendererFormat.default()
        )
        
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return resizedImage
    }
    
    /// 타겟 사이즈 계산 함수
    private func calculateTargetSize(for image: UIImage, aspectRatio: AspectRatio, maxSize: CGFloat) -> CGSize {
        if let ratio = aspectRatio.ratio {
            if ratio == 1.0 {
                // 정사각형
                return CGSize(width: maxSize, height: maxSize)
            } else if ratio < 1.0 {
                // 세로형 (4:5 등)
                let width = maxSize * ratio
                return CGSize(width: width, height: maxSize)
            } else {
                // 가로형 (16:9 등)
                let height = maxSize / ratio
                return CGSize(width: maxSize, height: height)
            }
        } else {
            // 원본 비율 유지
            let originalRatio = image.size.width / image.size.height
            if originalRatio > 1.0 {
                // 가로가 더 긴 경우
                let height = maxSize / originalRatio
                return CGSize(width: maxSize, height: height)
            } else {
                // 세로가 더 긴 경우
                let width = maxSize * originalRatio
                return CGSize(width: width, height: maxSize)
            }
        }
    }
}

// MARK: - Croppable Image View
struct CroppableImageView: View {
    let image: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var rotation: Double
    let aspectRatio: CGFloat?
    let availableSize: CGSize
    
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var lastRotation: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 이미지 (회전 기능 포함)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .offset(offset)
                    .clipped()
                
                // 크롭 오버레이
                CropOverlayView(aspectRatio: aspectRatio, availableSize: geometry.size)
            }
            .simultaneousGesture(
                // 드래그 제스처
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .simultaneousGesture(
                // 확대/축소 제스처
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(0.5, min(3.0, lastScale * value))
                    }
                    .onEnded { _ in
                        lastScale = scale
                    }
            )
            .simultaneousGesture(
                // 회전 제스처
                RotationGesture()
                    .onChanged { value in
                        rotation = lastRotation + value.degrees
                    }
                    .onEnded { _ in
                        lastRotation = rotation
                    }
            )
        }
    }
}

// MARK: - Crop Overlay View
struct CropOverlayView: View {
    let aspectRatio: CGFloat?
    let availableSize: CGSize
    
    var cropSize: CGSize {
        let padding: CGFloat = 40
        let maxWidth = availableSize.width - padding * 2
        let maxHeight = availableSize.height - padding * 2
        
        // 선택된 비율에 따라 크롭 영역 크기 결정
        if let ratio = aspectRatio {
            if ratio == 1.0 {
                // 정사각형
                let size = min(maxWidth, maxHeight)
                return CGSize(width: size, height: size)
            } else if ratio < 1.0 {
                // 세로형 (4:5 등)
                let width = min(maxWidth, maxHeight * ratio)
                let height = width / ratio
                return CGSize(width: width, height: height)
            } else {
                // 가로형 (16:9 등)
                let height = min(maxHeight, maxWidth / ratio)
                let width = height * ratio
                return CGSize(width: width, height: height)
            }
        } else {
            // 원본 비율 - 가능한 한 크게
            let size = min(maxWidth, maxHeight)
            return CGSize(width: size, height: size)
        }
    }
    
    var body: some View {
        ZStack {
            // 어두운 오버레이
            Color.black.opacity(0.5)
            
            // 크롭 영역 (투명)
            Rectangle()
                .frame(width: cropSize.width, height: cropSize.height)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .overlay(cropFrameOverlay)
    }
    
    @ViewBuilder
    private var cropFrameOverlay: some View {
        ZStack {
            // 외부 테두리
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropSize.width, height: cropSize.height)
            
            // 세로 가이드 라인
            verticalGridLines
            
            // 가로 가이드 라인
            horizontalGridLines
        }
    }
    
    @ViewBuilder
    private var verticalGridLines: some View {
        VStack(spacing: 0) {
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(height: cropSize.height / 3)
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(height: cropSize.height / 3)
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(height: cropSize.height / 3)
        }
        .frame(width: cropSize.width, height: cropSize.height)
    }
    
    @ViewBuilder
    private var horizontalGridLines: some View {
        HStack(spacing: 0) {
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: cropSize.width / 3)
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: cropSize.width / 3)
            Rectangle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                .frame(width: cropSize.width / 3)
        }
        .frame(width: cropSize.width, height: cropSize.height)
    }
} 