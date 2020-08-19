//
//  Push.swift
//  carthage_cache
//
//  Created by mrdaios on 2020/8/14.
//
import CarthageKit
import Commandant
import Curry
import Foundation
import ReactiveSwift

struct PushCommand: CommandProtocol {
    struct Options: OptionsProtocol {
        let cacheType: String
        let repo: String
        let tag: String

        let framework: String?

        static func create(_ cacheType: String) -> (String) -> (String) -> (String) -> Options {
            return { repo in { tag in { framework in Options(cacheType: cacheType, repo: repo, tag: tag, framework: framework) } }}
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<CarthageError>> {
            return create
                <*> m <| Option(key: "cacheType", defaultValue: "gitlab", usage: "the cache type")
                <*> m <| Option(key: "repo", defaultValue: "", usage: "the cache type")
                <*> m <| Option(key: "tag", defaultValue: "", usage: "the cache tag")
                <*> m <| Argument(defaultValue: "", usage: "the cache framework", usageParameter: "cache framework")
        }

        // MARK: Gitlab

        func buildCachServer() -> CachServerable? {
            var cacheServer: CachServerable?
            if cacheType == "gitlab" {
                let currentDirectoryPath = NSHomeDirectory()
                let directoryURL = URL(fileURLWithPath: currentDirectoryPath, isDirectory: true)
                let configFileURL = directoryURL.appendingPathComponent(".carthage_cache.json")
                if let configInfo = try? JSONSerialization.jsonObject(with: Data(contentsOf: configFileURL), options: .allowFragments) as? [String: Any] {
                    let repoConfig = ((configInfo["gitlab"] as? [String: Any])?["sources"] as? [String: Any])?[repo] as? [String: Any]
                    cacheServer = GitLabCachServer(repo: repo, repoConfig: repoConfig ?? [:])
                }
            }
            return cacheServer
        }
    }

    let verb: String = "push"
    let function: String = "push cache framework to somewhere."

    func run(_ options: Options) -> Result<Void, CarthageError> {
        guard options.repo.count > 0 else {
            return .failure(.internalError(description: "please input repo"))
        }
        guard let cacheServer = options.buildCachServer() else {
            return .failure(.internalError(description: "not support cacheType \(options.cacheType) or not found carthage_cache.json"))
        }
        guard let framework = options.framework, framework.count > 0 else {
            return .failure(.internalError(description: "please input framework name"))
        }
        guard FileManager.default.fileExists(atPath: FileManager.default.currentDirectoryPath.appending("/Carthage/Build"), isDirectory: nil) else {
            return .failure(.internalError(description: "please run in project dir."))
        }
        guard let versionFile = loadVersionFileWith(framework, inDirectory: FileManager.default.currentDirectoryPath.appending("/Carthage/Build")) else {
            return .failure(.internalError(description: "not found framework, please carthage build."))
        }
        var uploadVersionFile = versionFile
        if options.tag.count > 0 {
            uploadVersionFile = VersionFile(commitish: options.tag, macOS: versionFile.macOS, iOS: versionFile.iOS, watchOS: versionFile.watchOS, tvOS: versionFile.tvOS)
        }
        return cacheServer.upload(uploadVersionFile, projectDirectory: FileManager.default.currentDirectoryPath).waitOnCommand()
    }
}
