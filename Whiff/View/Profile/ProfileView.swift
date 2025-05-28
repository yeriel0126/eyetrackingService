import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: ProjectModel?
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var userName: String = "사용자"
    @State private var showingNameEdit = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 프로필 헤더
                    HStack(spacing: 20) {
                        // 프로필 이미지
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.accentColor)
                            }
                        }
                        
                        // 프로필 정보
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(userName)
                                    .font(.title2)
                                    .bold()
                                
                                Button(action: {
                                    showingNameEdit = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Text("향수 컬렉션: \(projectStore.projects.count)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 구분선
                    Divider()
                    
                    // 컬렉션 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("My Collection")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            NavigationLink(destination: RecommendationsTabView()) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        if projectStore.projects.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("저장된 프로젝트가 없습니다.")
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(projectStore.projects) { project in
                                NavigationLink(destination: ProjectDetailView(project: project)) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(project.name)
                                            .font(.headline)
                                        Text(project.createdAt.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        if !project.tags.isEmpty {
                                            Text("#" + project.tags.joined(separator: "  #"))
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(12)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        projectToDelete = project
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 시향 일기 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("시향 일기")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            NavigationLink(destination: ScentDiaryView()) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 시향 일기 목록 (임시 데이터)
                        VStack(spacing: 12) {
                            ForEach(1...3, id: \.self) { _ in
                                HStack(spacing: 16) {
                                    Image(systemName: "book.closed.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("시향 일기 제목")
                                            .font(.headline)
                                        Text("2024.03.21")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("프로젝트 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let project = projectToDelete {
                        deleteProject(project)
                    }
                }
            } message: {
                Text("이 프로젝트를 삭제하시겠습니까?")
            }
            .alert("이름 변경", isPresented: $showingNameEdit) {
                TextField("이름", text: $userName)
                Button("취소", role: .cancel) { }
                Button("저장") { }
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
    
    private func deleteProject(_ project: ProjectModel) {
        Task {
            await projectStore.deleteProject(id: project.id)
        }
    }
} 