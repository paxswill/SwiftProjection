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

    private var info: PJ_PROJ_INFO {
        if _info == nil {
            pj_set_ctx(projection, projContext.inner.value.context)
            _info = proj_pj_info(projection)
        }
        return _info!
    }

    public var inverse: Projection? {
        guard hasInverse else {
            return nil
        }
        if _inverse == nil {
            let isForward = defaultDirection == PJ_FWD
            _inverse = Projection(projection: self, defaultForward: !isForward)
        }
        return _inverse
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

    public var debugDescription: String {
        return definition
    }

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
        return pipeline[0]
    }

    internal var pipelineSteps: [String] {
        guard isPipeline else {
            return []
        }
        return Array(pipeline.suffix(from: 1))
    }

    private init(projString: String, defaultForward: Bool) {
        projection = proj_create(projContext.inner.value.context, projString)
        self.defaultDirection = defaultForward ? PJ_FWD : PJ_INV
    }

    public convenience init(projString: String) {
        self.init(projString: projString, defaultForward: true)
    }

    public convenience init(identifier: String) {
        self.init(projString: "+init=\(identifier)")
    }

    private convenience init(projection: Projection, defaultForward: Bool) {
        self.init(projString: projection.definition, defaultForward: defaultForward)
    }

    deinit {
        proj_destroy(projection)
    }

    private func transform(_ convertibleCoordinate: ConvertibleCoordinate, direction: PJ_DIRECTION) -> ProjectionCoordinate {
        // Set the context for the PJ at the beginning of every function in case we're running in a different thread
        pj_set_ctx(projection, projContext.inner.value.context)
        let coordinate = convertibleCoordinate.getCoordinate()
        let projCoordinate = coordinate.getProjCoordinate()
        let transformed = proj_trans(projection, direction, projCoordinate)
        return ProjectionCoordinate(transformed)
    }

    public func transform(_ convertibleCoordinate: ConvertibleCoordinate) -> ProjectionCoordinate {
        return self.transform(convertibleCoordinate, direction: defaultDirection)
    }

    public func asPipeline() -> Projection {
        if isPipeline {
            return self
        }
        var pipelineDefinition = "proj=pipeline step \(definition)"
        if defaultDirection == PJ_INV {
            pipelineDefinition.append(" inv")
        }
        return Projection(projString: pipelineDefinition)
    }

    public func appendStep(projString: String) -> Projection {
        guard isPipeline else {
            return asPipeline().appendStep(projString: projString)
        }
        let newDefinition = "\(definition) step \(projString)"
        return Projection(projString: newDefinition)
    }

    public func appendStep(projection: Projection) -> Projection {
        return self.appendStep(projString: projection.definition)
    }
}
