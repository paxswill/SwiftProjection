//
//  Context.swift
//  PROJ.Swift
//
//  Created by Will Ross on 3/9/18.
//  Copyright © 2018 Will Ross. All rights reserved.
//

import Foundation
import Threadly

internal let projContext = ThreadLocal(create: { ProjectionContext() })

internal class ProjectionContext {
    // Wrapping the context in a Swift class to get memory management
    internal let context: OpaquePointer

    public var currentError: ProjectionError? {
        let errorNumber = proj_context_errno(context)
        guard errorNumber != 0 else {
            return nil
        }
        return ProjectionError.LibraryError(code: errorNumber)
    }

    init() {
        context = proj_context_create()
        pj_ctx_set_fileapi(context, get_bundle_fileapi())
        // Not checking for errors here, as if this is throwing error, we have larger problems
        // TODO: Add logging for errors here
    }

    deinit {
        proj_context_destroy(context)
    }
}
