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
    
    func addProject(name: String, perfumes: [Perfume]) async {
        isLoading = true
        error = nil
        
        do {
            let newProject = try await apiClient.createProject(name: name, perfumes: perfumes)
            projects.insert(newProject, at: 0)
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
    
    func getFinalRecommendations(projectId: UUID) async -> [Perfume] {
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.getRecommendations(projectId: projectId.uuidString)
            isLoading = false
            return response
        } catch {
            self.error = error
            isLoading = false
            return []
        }
    }
}


