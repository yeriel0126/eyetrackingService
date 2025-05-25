//
//  CollectionView.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var showingDeleteAlert = false
    @State private var projectToDelete: ProjectModel?

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("My Collection")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                if projectStore.projects.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No saved projects yet.")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
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
                                .padding(.vertical, 4)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    projectToDelete = project
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.horizontal)
            .navigationBarHidden(true)
            .alert("Delete Project", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let project = projectToDelete {
                        deleteProject(project)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this project? This action cannot be undone.")
            }
            .task {
                await loadProjects()
            }
        }
    }

    private func loadProjects() async {
        // TODO: 백엔드에서 프로젝트 목록 로드
    }

    private func deleteProject(_ project: ProjectModel) {
        // TODO: 백엔드에서 프로젝트 삭제
        if let index = projectStore.projects.firstIndex(where: { $0.id == project.id }) {
            projectStore.projects.remove(at: index)
        }
    }
}

