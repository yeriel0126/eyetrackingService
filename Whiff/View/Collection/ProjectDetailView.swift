//
//  ProjectDetailView.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import SwiftUI

struct ProjectDetailView: View {
    let project: ProjectModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(project.name)
                .font(.title)
                .bold()

            Text("Created: \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundColor(.gray)

            if !project.tags.isEmpty {
                Text("Tags: #" + project.tags.joined(separator: "  #"))
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            Divider()

            if project.recommendedPerfumes.isEmpty {
                Text("No recommended perfumes in this project.")
                    .foregroundColor(.secondary)
            } else {
                List(project.recommendedPerfumes) { perfume in
                    NavigationLink(destination: PerfumeDetailView(perfume: perfume)) {
                        VStack(alignment: .leading) {
                            Text(perfume.name)
                                .font(.headline)
                            Text(perfume.brand)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Project")
    }
}

