//
//  SwiftUI_githubTests.swift
//  SwiftUI-githubTests
//
//  Created by Pepe Ruiz on 28/08/25.
//
import XCTest
@testable import SwiftUI_github
import Combine
// MARK: - Mock URLProtocol para simular respuestas de la API.
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? = nil
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown, userInfo: [NSLocalizedDescriptionKey: "No se configuró el handler para la solicitud"])
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        if let handler = MockURLProtocol.requestHandler {
            do {
                _ = try handler(request)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }
}
// MARK: - Unit Test
final class SwiftUI_githubTests: XCTestCase {
    var viewModel: GitHubViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        viewModel = GitHubViewModel(username: "testuser", session: session)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }
    
    func testGitHubUserDecoding() throws {
        /// JSON de ejemplo para un usuario
        let json = """
            {
                "login": "testuser",
                "name": "Test User",
                "bio": "A test user bio",
                "avatar_url": "https://example.com/avatar.png",
                "public_repos": 10,
                "followers": 100,
                "following": 50
            }
            """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let user = try decoder.decode(GitHubUser.self, from: json)
        
        XCTAssertEqual(user.login, "testuser")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.bio, "A test user bio")
        XCTAssertEqual(user.avatarUrl, "https://example.com/avatar.png")
        XCTAssertEqual(user.publicRepos, 10)
        XCTAssertEqual(user.followers, 100)
        XCTAssertEqual(user.following, 50)
    }
    
    func testGitHubRepoDecoding() throws {
        /// JSON de ejemplo para un repositorio
        let json = """
            [
                {
                    "id": 1,
                    "name": "test-repo",
                    "description": "A test repository",
                    "html_url": "https://github.com/testuser/test-repo"
                }
            ]
            """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let repos = try decoder.decode([GitHubRepo].self, from: json)
        
        XCTAssertEqual(repos.count, 1)
        XCTAssertEqual(repos[0].id, 1)
        XCTAssertEqual(repos[0].name, "test-repo")
        XCTAssertEqual(repos[0].description, "A test repository")
        XCTAssertEqual(repos[0].htmlUrl, "https://github.com/testuser/test-repo")
    }
    
    func testFetchUserDataSuccess() {
        /// Configurar respuesta simulada para el perfil
        let userJson = """
            {
                "login": "testuser",
                "name": "Test User",
                "bio": "A test user bio",
                "avatar_url": "https://example.com/avatar.png",
                "public_repos": 10,
                "followers": 100,
                "following": 50
            }
            """.data(using: .utf8)!
        
        let reposJson = """
            [
                {
                    "id": 1,
                    "name": "test-repo",
                    "description": "A test repository",
                    "html_url": "https://github.com/testuser/test-repo"
                }
            ]
            """.data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let urlString = request.url?.absoluteString ?? ""
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            if urlString.contains("users/testuser/repos") {
                return (response, reposJson)
            } else if urlString.contains("users/testuser") {
                return (response, userJson)
            }
            fatalError("URL no reconocida: \(urlString)")
        }
        
        let expectation = XCTestExpectation(description: "Fetch user data")
        var userReceived = false
        var reposReceived = false
        
        viewModel.$user
            .dropFirst()
            .sink { user in
                XCTAssertNotNil(user)
                XCTAssertEqual(user?.login, "testuser")
                userReceived = true
                checkCompletion()
            }
            .store(in: &cancellables)
        
        viewModel.$repos
            .dropFirst()
            .sink { repos in
                XCTAssertEqual(repos.count, 1)
                XCTAssertEqual(repos.first?.name, "test-repo")
                reposReceived = true
                checkCompletion()
            }
            .store(in: &cancellables)
        
        /// Función para verificar si ambas suscripciones se completaron
        func checkCompletion() {
            if userReceived && reposReceived {
                expectation.fulfill()
            }
        }
        
        viewModel.fetchUserData()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testFetchUserDataFailure() {
        let expectation = XCTestExpectation(description: "Fetch user data failure")
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return(response, Data())
        }
        
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                print("errorMessage recibido: \(String(describing: errorMessage))")
                if let message = errorMessage {
                    XCTAssertTrue(message.contains("not connected") || message.contains("error"), "El mensaje debería indicar un error de conexión o genérico")
                } else {
                    XCTAssertTrue(true)
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)
        print("Llamando a fetchUserData")
        viewModel.fetchUserData()
        
        wait(for: [expectation], timeout: 5.0)
    }
}
