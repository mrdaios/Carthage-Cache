//
//  File.swift
//
//
//  Created by mrdaios on 2020/8/14.
//

import CarthageKit
import Commandant

public struct VersionCommand: CommandProtocol {
    public typealias Options = VersionOptions

    public var verb: String
    public var function: String

    public func run(_ options: VersionOptions) -> Result<Void, CarthageError> {
        return Result.failure(.gitHubAPITimeout)
    }
}

public struct VersionOptions: OptionsProtocol {
    public typealias ClientError = CarthageError

    let lines: Int
    let verbose: Bool
    let logName: String

    static func create(_ lines: Int) -> (Bool) -> (String) -> VersionOptions {
        return { verbose in { logName in VersionOptions(lines: lines, verbose: verbose, logName: logName) } }
    }

    public static func evaluate(_ m: CommandMode) -> Result<VersionOptions, CommandantError<CarthageError>> {
        return create
            <*> m <| Option(key: "lines", defaultValue: 0, usage: "the number of lines to read from the logs")
            <*> m <| Option(key: "verbose", defaultValue: false, usage: "show verbose output")
            <*> m <| Argument(usage: "the log to read")
    }
}
