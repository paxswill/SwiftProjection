//
//  Error.swift
//  Pods
//
//  Created by Will Ross on 3/16/18.
//

public enum ProjectionError: Error, CustomStringConvertible {
    case LibraryError(code: Int32)

    public var description: String {
        // Once PROJ 5.1.0 is released, pj_strerrno can be replaced with proj_errno_string (they have same signature)
        switch self {
        case let .LibraryError(code):
            var message = "(no error description found)"
            if let errorDescription = pj_strerrno(code) {
                if let projDescription = String(utf8String: errorDescription) {
                    message = projDescription
                }
            }
            return "PROJ error \(code): \(message)"
        }
    }
}
