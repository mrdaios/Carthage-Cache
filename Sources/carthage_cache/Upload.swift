//
//  File.swift
//
//
//  Created by dailingchi on 2020/8/19.
//

import CarthageKit
import Commandant
import Curry
import Foundation
import ReactiveSwift

struct UploadCommand: CommandProtocol {
    struct Options: OptionsProtocol {
        let cacheType: String
        let localPath: String
        let remotePath: String

        static func create(_ cacheType: String) -> (String) -> (String) -> Options {
            return { localPath in { remotePath in Options(cacheType: cacheType, localPath: localPath, remotePath: remotePath) } }
        }

        static func evaluate(_ m: CommandMode) -> Result<Options, CommandantError<CarthageError>> {
            return create
                <*> m <| Option(key: "cacheType", defaultValue: "gitlab", usage: "the cache type")
                <*> m <| Argument(defaultValue: "", usage: "the cache framework", usageParameter: "local path")
                <*> m <| Argument(defaultValue: "", usage: "the cache framework", usageParameter: "remote path")
        }

        // MARK: Gitlab

        func loadUploadRepo() -> String? {
            var repoURL: String?
            if cacheType == "gitlab" {
                let currentDirectoryPath = FileManager.default.currentDirectoryPath
                let directoryURL = URL(fileURLWithPath: currentDirectoryPath, isDirectory: true)
                let configFileURL = directoryURL.appendingPathComponent("carthage_cache.json")
                if let configInfo = try? JSONSerialization.jsonObject(with: Data(contentsOf: configFileURL), options: .allowFragments) as? [String: Any] {
                    repoURL = (configInfo["gitlab"] as? [String: Any])?["repo"] as? String
                }
            }
            return repoURL
        }

        func buildCachServer() -> CachServerable? {
            var cacheServer: CachServerable?
            if cacheType == "gitlab" {
                let currentDirectoryPath = NSHomeDirectory()
                let directoryURL = URL(fileURLWithPath: currentDirectoryPath, isDirectory: true)
                let configFileURL = directoryURL.appendingPathComponent(".carthage_cache.json")
                if let configInfo = try? JSONSerialization.jsonObject(with: Data(contentsOf: configFileURL), options: .allowFragments) as? [String: Any] {
                    guard let repoURL = loadUploadRepo() else {
                        return nil
                    }
                    let repoConfig = ((configInfo["gitlab"] as? [String: Any])?["sources"] as? [String: Any])?[repoURL] as? [String: Any]
                    cacheServer = GitLabCachServer(repo: repoURL, repoConfig: repoConfig ?? [:])
                }
            }
            return cacheServer
        }
    }

    let verb: String = "upload"
    let function: String = "push cache framework to somewhere."

    func run(_ options: Options) -> Result<Void, CarthageError> {
        guard options.localPath.count > 0 && options.remotePath.count > 0 else {
            return .failure(.internalError(description: "please input localpath and remotePath"))
        }
        guard (options.loadUploadRepo() ?? "").count > 0 else {
            return .failure(.internalError(description: "please config carthage_cache.json"))
        }
        guard let cacheServer = options.buildCachServer() else {
            return .failure(.internalError(description: "not support cacheType \(options.cacheType) or not found carthage_cache.json"))
        }
        return cacheServer.upload(localPath: options.localPath, remotePath: options.remotePath).waitOnCommand()
    }
}
