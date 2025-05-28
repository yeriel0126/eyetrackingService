//
//  ProjectDetailView.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import SwiftUI
import Foundation

struct ProjectDetailView: View {
    let project: ProjectModel
    @State private var showingAddNote = false
    @State private var selectedPerfume: PerfumeRecommendation?
    @State private var isFavorite: Bool
    
    init(project: ProjectModel) {
        self.project = project
        _isFavorite = State(initialValue: project.isFavorite)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 프로젝트 정보
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(project.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            isFavorite.toggle()
                            var updatedProject = project
                            updatedProject.isFavorite = isFavorite
                            ProjectManager.shared.updateProject(updatedProject)
                        }) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundColor(isFavorite ? .yellow : .gray)
                        }
                    }
                    
                    Text("Created: \(project.createdAt.formatted())")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // 추천 향수 목록
                VStack(alignment: .leading, spacing: 16) {
                    Text("추천 향수")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(project.recommendations) { perfume in
                        PerfumeRecommendationCard(perfume: perfume)
                            .onTapGesture {
                                selectedPerfume = perfume
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .sheet(item: $selectedPerfume) { perfume in
            PerfumeDetailView(perfume: perfume)
        }
        .onAppear {
            // 프로젝트 데이터 로드
            if let savedProject = ProjectManager.shared.getProject(id: project.id) {
                isFavorite = savedProject.isFavorite
            }
        }
    }
}

struct PerfumeRecommendationCard: View {
    let perfume: PerfumeRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(perfume.name)
                .font(.headline)
            
            Text(perfume.brand)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let notes = perfume.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRecommendations = [
            PerfumeRecommendation(
                id: "1",
                name: "Sample Perfume 1",
                brand: "Sample Brand",
                notes: "Top: Bergamot, Lemon\nMiddle: Jasmine, Rose\nBase: Sandalwood, Musk",
                imageUrl: nil,
                score: 0.85,
                emotionTags: ["신나는", "상쾌한", "시트러스"],
                similarity: "0.85"
            ),
            PerfumeRecommendation(
                id: "2",
                name: "Sample Perfume 2",
                brand: "Another Brand",
                notes: "Top: Orange, Grapefruit\nMiddle: Lavender, Rose\nBase: Vanilla, Amber",
                imageUrl: nil,
                score: 0.75,
                emotionTags: ["차분한", "로맨틱한", "우드"],
                similarity: "0.75"
            )
        ]
        
        let now = Date()
        
        return ProjectDetailView(project: ProjectModel(
            id: "1",
            name: "Sample Project",
            userId: "user1",
            preferences: [],
            recommendations: sampleRecommendations,
            createdAt: now,
            updatedAt: now,
            tags: ["sample", "test"],
            isFavorite: false
        ))
    }
}

