//
//  CachServer.swift
//  carthage_cache
//
//  Created by mrdaios on 2020/8/17.
//

import CarthageKit
import Foundation
import ReactiveSwift

protocol CachServerable {
    func upload(_ versionFile: VersionFile, projectDirectory: String) -> SignalProducer<Dictionary<String, Any>, CarthageError>
    func upload(localPath: String, remotePath: String) -> SignalProducer<Dictionary<String, Any>, CarthageError>
}

struct GitLabCachServer: CachServerable {
    let repo: String
    let repoConfig: [String: Any]

    init(repo: String, repoConfig: [String: Any]) {
        self.repo = repo
        self.repoConfig = repoConfig
    }

    func upload(localPath: String, remotePath: String) -> SignalProducer<[String: Any], CarthageError> {
        guard let commitURL = buildCommitURL() else {
            return SignalProducer(error: .internalError(description: "not found url."))
        }

        var commitJSON: [String: Any] = [:]
        commitJSON["start_branch"] = "master"
        commitJSON["branch"] = localPath
        commitJSON["commit_message"] = "[Auto Upload]\(localPath)"

        let uploadFileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true).appendingPathComponent(localPath)
        let data = try? Data(contentsOf: uploadFileURL).base64EncodedString()
        commitJSON["actions"] = [
            [
                "action": "create",
                "file_path": remotePath,
                "content": data,
                "encoding": "base64",
            ],
        ]

        var request = URLRequest(url: commitURL)
        request.httpMethod = "POST"
        if let token = repoConfig["PRIVATE-TOKEN"] as? String {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: commitJSON, options: .fragmentsAllowed)
        return uploadRequest(urlRequest: request)
    }

    func upload(_ versionFile: VersionFile, projectDirectory: String) -> SignalProducer<Dictionary<String, Any>, CarthageError> {
        guard let cachedFramework = versionFile.iOS?.first else {
            return SignalProducer(error: .internalError(description: "not found build framework."))
        }
        // create tmp zip
        guard let tempURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(cachedFramework.name)-\(versionFile.commitish).zip") else {
            return SignalProducer(error: .internalError(description: "create tmp zip failure."))
        }

        guard let commitURL = buildCommitURL() else {
            return SignalProducer(error: .internalError(description: "not found url."))
        }

        func buildCommitRequest() -> SignalProducer<[String: Any], CarthageError> {
            var commitJSON: [String: Any] = [:]
            commitJSON["start_branch"] = "master"
            commitJSON["branch"] = "\(cachedFramework.name)-\(versionFile.commitish)"
            commitJSON["commit_message"] = "[Auto Upload]\(cachedFramework.name)-\(versionFile.commitish)"

            let data = try? Data(contentsOf: tempURL).base64EncodedString()
            commitJSON["actions"] = [
                [
                    "action": "create",
                    "file_path": "Framework/\(cachedFramework.name)/\(cachedFramework.name)-\(versionFile.commitish).zip",
                    "content": data,
                    "encoding": "base64",
                ],
            ]

            var request = URLRequest(url: commitURL)
            request.httpMethod = "POST"
            if let token = repoConfig["PRIVATE-TOKEN"] as? String {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: commitJSON, options: .fragmentsAllowed)
            return uploadRequest(urlRequest: request)
        }

        return zip(paths: ["\(cachedFramework.name).framework"],
                   into: tempURL,
                   workingDirectory: projectDirectory.appending("/Carthage/Build/iOS"))
            .then(buildCommitRequest())
    }

    // MARK: Private

    private func uploadRequest(urlRequest: URLRequest) -> SignalProducer<[String: Any], CarthageError> {
        return URLSession.shared.reactive.data(with: urlRequest).attemptMap { (result) -> [String: Any] in
            guard let httpResponse = result.1 as? HTTPURLResponse else {
                throw CarthageError.internalError(description: "response not HTTPURLResponse.")
            }
            guard httpResponse.statusCode == 201,
                let jsonResult = try? JSONSerialization.jsonObject(with: result.0, options: .allowFragments) as? [String: Any] else {
                throw CarthageError.internalError(description: "response statucode not \(httpResponse.statusCode).\n jsonResult:\(String(data: result.0, encoding: .utf8) ?? "")")
            }
            return jsonResult
        }.mapError { (error) -> CarthageError in
            .internalError(description: error.description)
        }
    }

    private func buildCommitURL() -> URL? {
        guard let gitURL = URL(string: repo.components(separatedBy: ".git").first ?? "") else {
            return nil
        }
        let scheme = gitURL.scheme!
        let host = gitURL.host!
        let port = gitURL.port
        let projectPath = gitURL.pathComponents.dropFirst().joined(separator: "/").addingPercentEncoding(withAllowedCharacters: .urlUserAllowed)
        var listAPI = scheme
        listAPI.append("://")
        listAPI.append(host)
        if port != nil {
            listAPI.append(":\(port!)")
        }
        listAPI.append("/api/v4/projects")
        listAPI.append("/\(projectPath!)")
        listAPI.append("/repository/commits")
        return URL(string: listAPI)
    }
}
