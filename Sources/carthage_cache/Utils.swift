//
//  Utils.swift
//  carthage_cache
//
//  Created by mrdaios on 2020/8/17.
//

import CarthageKit
import Foundation

func loadVersionFileWith(_ frameWorkName: String, inDirectory: String) -> VersionFile? {
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: inDirectory) else {
        return nil
    }
    guard let frameWorkVersionFile = (files.first { $0.lowercased() == ".\(frameWorkName.lowercased()).version" }) else {
        return nil
    }

    guard let versionFilrURL = NSURL(fileURLWithPath: inDirectory).appendingPathComponent(frameWorkVersionFile) else {
        return nil
    }
    return VersionFile(url: versionFilrURL)
}
