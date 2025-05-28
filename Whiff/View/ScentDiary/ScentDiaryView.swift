import SwiftUI
import Foundation

struct ScentDiaryView: View {
    @StateObject private var viewModel = ScentDiaryViewModel()
    @State private var showingNewDiarySheet = false
    @State private var selectedDiary: ScentDiaryModel?
    @State private var showingDiaryDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.sortedDiaries) { diary in
                            Button(action: {
                                selectedDiary = diary
                                showingDiaryDetail = true
                            }) {
                                ScentDiaryCard(diary: diary, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                
                // 일기 작성 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingNewDiarySheet = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("시향 일기")
            .sheet(isPresented: $showingNewDiarySheet) {
                NewScentDiaryView()
            }
            .sheet(isPresented: $showingDiaryDetail) {
                if let diary = selectedDiary {
                    ScentDiaryDetailView(diary: diary, viewModel: viewModel)
                }
            }
        }
    }
}

struct ScentDiaryCard: View {
    let diary: ScentDiaryModel
    @ObservedObject var viewModel: ScentDiaryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 사용자 정보
            HStack {
                Image(diary.userProfileImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(diary.userName)
                        .font(.headline)
                    Text(diary.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // 향수 정보와 일기 내용
            HStack(spacing: 12) {
                Image(diary.perfumeName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(diary.perfumeName)
                        .font(.subheadline)
                        .bold()
                    Text(diary.brand)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(diary.content)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }
            
            // 감정 태그
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(diary.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 좋아요, 댓글 버튼
            HStack {
                Button(action: {
                    Task {
                        await viewModel.toggleLike(diary.id)
                    }
                }) {
                    Label("\(diary.likes)", systemImage: viewModel.isLiked(diary.id) ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked(diary.id) ? .red : .gray)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Label("\(diary.comments)", systemImage: "message")
                }
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ScentDiaryDetailView: View {
    let diary: ScentDiaryModel
    @ObservedObject var viewModel: ScentDiaryViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 사용자 정보
                    HStack {
                        Image(diary.userProfileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(diary.userName)
                                .font(.headline)
                            Text(diary.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // 향수 정보
                    HStack(spacing: 16) {
                        Image(diary.perfumeName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(diary.perfumeName)
                                .font(.title3)
                                .bold()
                            Text(diary.brand)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Divider()
                    
                    // 일기 내용
                    Text(diary.content)
                        .font(.body)
                        .lineSpacing(8)
                    
                    // 감정 태그
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(diary.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // 좋아요, 댓글 섹션
                    VStack(spacing: 16) {
                        HStack {
                            Button(action: {
                                Task {
                                    await viewModel.toggleLike(diary.id)
                                }
                            }) {
                                Label("\(diary.likes)", systemImage: viewModel.isLiked(diary.id) ? "heart.fill" : "heart")
                                    .foregroundColor(viewModel.isLiked(diary.id) ? .red : .gray)
                            }
                            
                            Spacer()
                            
                            Label("\(diary.comments)", systemImage: "message")
                                .foregroundColor(.gray)
                        }
                        
                        // 댓글 목록
                        ForEach(0..<3) { _ in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("사용자 이름")
                                        .font(.subheadline)
                                        .bold()
                                    Text("댓글 내용이 여기에 표시됩니다.")
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("시향 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: 공유 기능 구현
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

struct PerfumePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPerfume: Perfume?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                // TODO: 실제 향수 데이터로 대체
                ForEach(0..<10) { _ in
                    Button(action: {
                        // TODO: 향수 선택 로직 구현
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            VStack(alignment: .leading) {
                                Text("향수 이름")
                                    .font(.headline)
                                Text("브랜드")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "향수 검색")
            .navigationTitle("향수 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScentDiaryView_Previews: PreviewProvider {
    static var previews: some View {
        ScentDiaryView()
    }
} 