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

    init() {
        context = proj_context_create()
        pj_ctx_set_fileapi(context, get_bundle_fileapi())
    }

    deinit {
        proj_context_destroy(context)
    }
}
