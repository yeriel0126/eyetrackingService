//
//  PerfumeDetailView.swift
//  Whiff
//
//  Created by 신희영 on 5/20/25.
//
import SwiftUI

struct PerfumeDetailView: View {
    let perfume: Perfume

    var body: some View {
        VStack(spacing: 16) {
            Text(perfume.name)
                .font(.title)
                .bold()
            Text(perfume.brand)
                .font(.subheadline)
                .foregroundColor(.gray)

            Divider()

            Text("Top Notes: \(perfume.notes.top.joined(separator: ", "))")
            Text("Middle Notes: \(perfume.notes.middle.joined(separator: ", "))")
            Text("Base Notes: \(perfume.notes.base.joined(separator: ", "))")

            Spacer()
        }
        .padding()
        .navigationTitle("Perfume Detail")
    }
}

