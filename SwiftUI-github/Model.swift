//
//  Model.swift
//  SwiftUI-github
//
//  Created by Antonio Ruiz on 28/08/25.
//
import Foundation
/// Usuario git.
struct GitHubUser: Codable {
    let login: String
    let name: String?
    let bio: String?
    let avatarUrl: String
    let publicRepos: Int
    let followers: Int
    let following: Int
    
    enum CodingKeys: String, CodingKey {
        case login
        case name
        case bio
        case avatarUrl = "avatar_url"
        case publicRepos = "public_repos"
        case followers
        case following
    }
}

/// Repositorio git.
struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let htmlUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case htmlUrl = "html_url"
    }
}
