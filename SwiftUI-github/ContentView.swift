//
//  ContentView.swift
//  SwiftUI-github
//
//  Created by Antonio Ruiz on 28/08/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GitHubViewModel(username: "pepecode1")
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando...")
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if let user = viewModel.user {
                    VStack(spacing: 20) {
                        AsyncImage(url: URL(string: user.avatarUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(.gray)
                                .frame(width: 100, height: 100)
                        }
                        
                        Text(user.name ?? user.login)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(user.bio ?? "Sin biografía")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        HStack {
                            VStack {
                                Text("\(viewModel.repos.count)")
                                    .font(.headline)
                                Text("Repos")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(user.followers)")
                                    .font(.headline)
                                Text("Seguidores")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(user.following)")
                                    .font(.headline)
                                Text("Siguiendo")
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Lista de repositorios
                        List(viewModel.repos) { repo in
                            VStack(alignment: .leading) {
                                Text(repo.name)
                                    .font(.headline)
                                Text(repo.description ?? "Sin descripción")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .listStyle(.plain)
                    }
                    .padding()
                }
            }
            .navigationTitle("Perfil de GitHub")
            .onAppear {
                viewModel.fetchUserData()
            }
        }
    }
}

// MARK: - Vista Previa
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
