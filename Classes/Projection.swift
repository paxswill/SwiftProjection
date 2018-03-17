//
//  Projection.swift
//  PROJ.Swift
//
//  Created by Will Ross on 3/9/18.
//  Copyright © 2018 Will Ross. All rights reserved.
//

import Foundation

public class Projection: CustomDebugStringConvertible  {
    private let projection: OpaquePointer
    private var _info: PJ_PROJ_INFO? = nil
    private let defaultDirection: PJ_DIRECTION
    private var _inverse: Projection? = nil

    public var inverse: Projection? {
        guard hasInverse else {
            return nil
        }
        if _inverse == nil {
            let isForward = defaultDirection == PJ_FWD
            do {
                _inverse = try Projection(projection: self, defaultForward: !isForward)
            } catch {
                // if inverse returned nil, check currentError()
                return nil
            }
        }
        return _inverse
    }

    // MARK: - Projection Info

    private var info: PJ_PROJ_INFO {
        if _info == nil {
            pj_set_ctx(projection, projContext.inner.value.context)
            proj_errno_reset(projection)
            _info = proj_pj_info(projection)
        }
        return _info!
    }

    public var id: String {
        return String(utf8String: info.id)!
    }

    public var description: String {
        return String(utf8String: info.description)!
    }

    public var definition: String {
        return String(utf8String: info.definition)!
    }

    public var hasInverse: Bool {
        return info.has_inverse == 1
    }

    public var accuracy: Double? {
        guard info.accuracy != -1 else {
            return nil
        }
        return info.accuracy
    }

    // MARK: - Debugging and Errors

    public var debugDescription: String {
        return definition
    }

    public var currentError: ProjSwiftError? {
        // Do _not_ change the current context for the projection, it's already been set by whatever caused the error.
        let errorNumber = proj_errno(projection)
        guard errorNumber != 0 else {
            return nil
        }
        return ProjSwiftError.LibraryError(code: errorNumber)
    }

    // MARK: - Pipeline introspection

    internal var isPipeline: Bool {
        return id == "pipeline"
    }

    private var pipeline: [String] {
        guard isPipeline else {
            return [definition]
        }
        let words = definition.split(separator: " ")
        var steps: [String] = []
        var currentStep = ""
        for word in words {
            if word == "step" {
                // The last character is a space, trim it off
                currentStep = String(currentStep.dropLast())
                steps.append(currentStep)
                currentStep = ""
            } else {
                currentStep.append(contentsOf: word)
                currentStep.append(" ")
            }
        }
        // Append the last step
        currentStep = String(currentStep.dropLast())
        steps.append(currentStep)
        return steps
    }

    internal var pipelineGlobals: String {
        guard isPipeline else {
            return definition
        }
        return pipeline[0]
    }

    internal var pipelineSteps: [String] {
        guard isPipeline else {
            return []
        }
        return Array(pipeline.suffix(from: 1))
    }

    // MARK: - Initializers

    private init(projString: String, defaultForward: Bool) throws {
        let context = projContext.inner.value
        self.defaultDirection = defaultForward ? PJ_FWD : PJ_INV
        if let pj = proj_create(context.context, projString) {
            projection = pj
        } else {
            // There's an error, projection initialization failed.
            throw context.currentError!
        }
    }

    public convenience init(projString: String) throws {
        try self.init(projString: projString, defaultForward: true)
    }

    public convenience init(identifier: String) throws {
        try self.init(projString: "+init=\(identifier)")
    }

    private convenience init(projection: Projection, defaultForward: Bool) throws {
        try self.init(projString: projection.definition, defaultForward: defaultForward)
    }

    deinit {
        proj_destroy(projection)
    }

    // MARK: - Transforms

    private func transform(_ convertibleCoordinate: ConvertibleCoordinate, direction: PJ_DIRECTION) throws -> ProjectionCoordinate {
        // Set the context for the PJ at the beginning of every function in case we're running in a different thread
        pj_set_ctx(projection, projContext.inner.value.context)
        proj_errno_reset(projection)
        let coordinate = convertibleCoordinate.getCoordinate()
        let projCoordinate = coordinate.getProjCoordinate()
        let transformed = proj_trans(projection, direction, projCoordinate)
        if let error = currentError {
            throw error
        }
        return ProjectionCoordinate(transformed)
    }

    public func transform(_ convertibleCoordinate: ConvertibleCoordinate) throws -> ProjectionCoordinate {
        return try self.transform(convertibleCoordinate, direction: defaultDirection)
    }

    // MARK: - Constructing Pipelines

    public func asPipeline() throws -> Projection {
        if isPipeline {
            return self
        }
        var pipelineDefinition = "proj=pipeline step \(definition)"
        if defaultDirection == PJ_INV {
            pipelineDefinition.append(" inv")
        }
        return try Projection(projString: pipelineDefinition)
    }

    public func appendStep(projString: String) throws -> Projection {
        guard isPipeline else {
            return try asPipeline().appendStep(projString: projString)
        }
        let newDefinition = "\(definition) step \(projString)"
        return try Projection(projString: newDefinition)
    }

    public func appendStep(projection: Projection) throws -> Projection {
        return try self.appendStep(projString: projection.definition)
    }
}
