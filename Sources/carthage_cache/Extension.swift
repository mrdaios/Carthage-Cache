//
//  Extension.swift
//  carthage_cache
//
//  Created by mrdaios on 2020/8/14.
//
import CarthageKit
import Foundation
import ReactiveSwift
import ReactiveTask

extension SignalProducer where Error == CarthageError {
    /// Waits on a SignalProducer that implements the behavior of a CommandProtocol.
    internal func waitOnCommand() -> Result<Void, CarthageError> {
        let result = producer
            .then(SignalProducer<Void, CarthageError>.empty)
            .wait()

        Task.waitForAllTaskTermination()
        return .failure(result.error ?? CarthageError.internalError(description: "unkown error."))
    }
}
