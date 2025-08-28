//
//  ViewModel.swift
//  SwiftUI-github
//
//  Created by Pepe Ruiz on 28/08/25.
//
import SwiftUI
import Combine

class GitHubViewModel: ObservableObject {
    @Published var user: GitHubUser?
    @Published var repos: [GitHubRepo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let username: String
    
    init(username: String) {
        self.username = username
    }
    
    func fetchUserData() {
        isLoading = true
        errorMessage = nil
        
        /// Fetch perfil
        let userUrl = URL(string: "https://api.github.com/users/\(username)")!
        URLSession.shared.dataTaskPublisher(for: userUrl)
            .map(\.data)
            .decode(type: GitHubUser.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
        
        /// Fetch repositorios
        let reposUrl = URL(string: "https://api.github.com/users/\(username)/repos")!
        URLSession.shared.dataTaskPublisher(for: reposUrl)
            .map(\.data)
            .decode(type: [GitHubRepo].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] repos in
                self?.repos = repos.filter({ $0.name != self?.username })
            }
            .store(in: &cancellables)
    }
}
