//
//  ProjectStore.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import Foundation
import SwiftUI

@MainActor
class ProjectStore: ObservableObject {
    @Published var projects: [ProjectModel] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let apiClient = APIClient.shared
    
    init() {
        Task {
            await fetchProjects()
        }
    }
    
    func createProject(name: String, perfumes: [Perfume]) async throws {
        guard !name.isEmpty else {
            throw APIError.invalidInput("프로젝트 이름을 입력해주세요.")
        }
        
        guard !perfumes.isEmpty else {
            throw APIError.invalidInput("최소 하나 이상의 향수를 선택해주세요.")
        }
        
        // Perfume 배열을 PreferenceRating 배열로 변환
        let preferences = perfumes.map { perfume in
            PreferenceRating(
                perfumeId: perfume.id,
                rating: 0, // 기본값으로 0 설정
                notes: "" // 빈 문자열로 초기화
            )
        }
        
        let project = try await apiClient.createProject(name: name, preferences: preferences)
        projects.append(project)
    }
    
    func fetchProjects() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedProjects = try await apiClient.getProjects()
            self.projects = fetchedProjects
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func updateProject(_ project: ProjectModel) async {
        isLoading = true
        error = nil
        
        do {
            let updatedProject = try await apiClient.updateProject(project)
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = updatedProject
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func deleteProject(id: String) async {
        isLoading = true
        error = nil
        
        do {
            try await apiClient.deleteProject(id: id)
            projects.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func submitPreferenceRatings(projectId: UUID, ratings: [UUID: Int]) async {
        isLoading = true
        error = nil
        
        do {
            try await apiClient.submitPreferences(projectId: projectId.uuidString, preferences: ratings.map { PreferenceRating(perfumeId: $0.key.uuidString, rating: $0.value) })
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func getFinalRecommendations(projectId: UUID) async throws -> [Perfume] {
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.getRecommendations(projectId: projectId.uuidString)
            isLoading = false
            return response
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
}


