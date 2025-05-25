import SwiftUI
import PhotosUI

struct NewScentDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NewScentDiaryViewModel()
    @State private var showingPerfumePicker = false
    @State private var showingImagePicker = false
    @State private var showingPerfumeDetail = false
    
    var body: some View {
        NavigationView {
            Form {
                // 향수 선택 섹션
                Section(header: Text("향수 (선택사항)")) {
                    if let perfume = viewModel.selectedPerfume {
                        Button(action: {
                            showingPerfumeDetail = true
                        }) {
                            HStack {
                                Image(perfume.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                VStack(alignment: .leading) {
                                    Text(perfume.name)
                                        .font(.headline)
                                    Text(perfume.brand)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Button(action: {
                            viewModel.selectedPerfume = nil
                        }) {
                            Text("향수 제거하기")
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {
                            showingPerfumePicker = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("향수 추가하기")
                            }
                        }
                    }
                }
                
                // 이미지 선택 섹션
                Section(header: Text("이미지")) {
                    if let selectedImage = viewModel.selectedImage {
                        HStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("이미지 추가하기")
                            }
                        }
                    }
                }
                
                // 일기 내용 섹션
                Section(header: Text("시향 일기")) {
                    TextEditor(text: $viewModel.content)
                        .frame(height: 200)
                }
                
                // 태그 섹션
                Section(header: Text("태그 (선택사항)")) {
                    TextField("태그 입력 (예: #신나는 #여름)", text: $viewModel.tagInput)
                        .onSubmit {
                            viewModel.addTag()
                        }
                    
                    if !viewModel.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(viewModel.tags, id: \.self) { tag in
                                    HStack {
                                        Text("#\(tag)")
                                            .foregroundColor(.blue)
                                        
                                        Button(action: {
                                            viewModel.removeTag(tag)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                
                // 공개 설정 섹션
                Section(header: Text("공개 설정")) {
                    Toggle("공개", isOn: $viewModel.isPublic)
                }
            }
            .navigationTitle("새로운 시향 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        viewModel.saveDiary()
                        dismiss()
                    }
                    .disabled(viewModel.content.isEmpty)
                }
            }
            .sheet(isPresented: $showingPerfumePicker) {
                PerfumePickerView(selectedPerfume: $viewModel.selectedPerfume)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showingPerfumeDetail) {
                if let perfume = viewModel.selectedPerfume {
                    PerfumeDetailView(perfume: perfume)
                }
            }
        }
    }
}

class NewScentDiaryViewModel: ObservableObject {
    @Published var selectedPerfume: Perfume?
    @Published var selectedImage: UIImage?
    @Published var content: String = ""
    @Published var tagInput: String = ""
    @Published var tags: [String] = []
    @Published var isPublic: Bool = true
    
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
    
    func saveDiary() {
        // TODO: 실제 저장 로직 구현
        print("일기 저장: \(content)")
        print("태그: \(tags)")
        print("공개 여부: \(isPublic)")
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
} 