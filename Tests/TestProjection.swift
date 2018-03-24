//
//  TestProjection.swift
//  Proj.Swift-Unit-Tests
//
//  Created by Will Ross on 3/13/18.
//

import Quick
import Nimble
import CoreLocation
@testable import SwiftProjection

class ProjectionSpec: QuickSpec {
    override func spec() {
        describe("a projection") {
            it("can be created from a proj string") {
                let projString = "+proj=merc +lat_ts=56.5 +ellps=GRS80"
                let pj = try! Projection(projString: projString)
                // PROJ canonicalizes definitions strings to not include the '+' signs
                let canonical = projString.replacingOccurrences(of: "+", with: "")
                expect(pj.definition).to(equal(canonical))
                // This also exercises bundle-reader (to read the defaults file), but doesn't fail if it doesn't work.
            }
            it("can tell if the input is angular") {
                let projString = "+proj=merc +lat_ts=56.5 +ellps=GRS80"
                let pj = try! Projection(projString: projString)
                expect(pj.inputIsAngular).to(beTrue())
                expect(pj.inverse!.outputIsAngular).to(beTrue())
            }
            it("can tell if the output is angular") {
                let projString = "+proj=merc +lat_ts=56.5 +ellps=GRS80"
                let pj = try! Projection(projString: projString)
                expect(pj.outputIsAngular).to(beFalse())
                expect(pj.inverse!.inputIsAngular).to(beFalse())
            }
            context("when using an init file") {
                it("can be created from a well known identitifer") {
                    // This is indirectly testing the bundle-reader functionality
                    let initString = "epsg:3857"
                    let canonical = "init=epsg:3857 proj=merc a=6378137 b=6378137 lat_ts=0.0 lon_0=0.0 x_0=0.0 y_0=0 k=1.0 units=m nadgrids=@null no_defs"
                    let pj = try! Projection(identifier: initString)
                    expect(pj.definition).to(equal(canonical))
                }
                it("throws when the init file can't be found") {
                    expect { try Projection(identifier: "fooBar:1234") }.to(throwError(errorType: ProjectionError.self))
                }
                it("throws when the init file doesn't have the ID") {
                    // Using the bogus ID for EPSG:3857 form before it was standardized
                    expect { try Projection(identifier: "epsg:900913") }.to(throwError(errorType: ProjectionError.self))
                }
                it("throws when using a malformed indentifier") {
                    expect { try Projection(identifier: "epsg") }.to(throwError(errorType: ProjectionError.self))
                }
            }
            it("throws an error when given a bad proj string") {
                expect { try Projection(projString: "proj=pipeline") }.to(throwError(errorType: ProjectionError.self))
                // -24 is the constant for PJD_ERR_LAT_TS_LARGER_THAN_90 in projects.h (yes, peeking in the private API)
                expect { try Projection(projString: "proj=merc lat_ts=100") }.to(throwError(
                    ProjectionError.LibraryError(code: -24)))
            }
            context("when transforming coordinates") {
                let pj = try! Projection(projString: "+proj=merc +lat_ts=56.5 +ellps=GRS80")
                // Values generated from the `proj` CLI
                let geodetic = ProjectionCoordinate(latitude: 44.0, longitude: -130.5)
                let projected = ProjectionCoordinate(u: -8036823.1041, v: 3007198.8879)
                // It feels great to be able to write tests using ≈ and ±
                func expectGeodetic(_ output: ProjectionCoordinate) {
                    expect(output.u) ≈ geodetic.u
                    expect(output.v) ≈ geodetic.v
                }
                func expectProjected(_ output: ProjectionCoordinate) {
                    expect(output.u) ≈ projected.u
                    expect(output.v) ≈ projected.v
                }
                it("can use the transform() method") {
                    let output = try! pj.transform(coordinate: geodetic)
                    expectProjected(output)
                }
                it("can be inverted") {
                    let output = try! (pj.inverse!).transform(coordinate: projected)
                    expectGeodetic(output)
                    // The definition is the same, just the direction is different
                    expect(pj.definition) == pj.inverse!.definition
                }
                it("returns nil if asked for a non-existant inverse") {
                    let forwardPJ = try! Projection(projString: "proj=airy a=6378137")
                    expect(forwardPJ.hasInverse).to(beFalse())
                    expect(forwardPJ.inverse).to(beNil())
                }
            }
            context("when it's a pipeline") {
                let plainPJ = try! Projection(projString: "+proj=merc +lat_ts=56.5 ellps=GRS80")
                let pipelinePJ = try! Projection(projString: "+proj=pipeline +step +proj=merc +lat_ts=56.5 + ellps=GRS80")
                let complexPipeline = try! Projection(projString: "+proj=pipeline +ellps=GRS80 +step +proj=merc +step +proj=axisswap +order=2,1")
                it("can be asked if it's a pipeline") {
                    expect(plainPJ.isPipeline) == false
                    expect(pipelinePJ.isPipeline) == true
                }
                context("if being converted from a plain projections") {
                    it("can be a forward transform") {
                        let plainAsPipeline = try! plainPJ.asPipeline()
                        expect(plainAsPipeline.isPipeline) == true
                        expect(plainAsPipeline.pipelineSteps.count) == 1
                        expect(plainAsPipeline.pipelineSteps[0]) == plainPJ.definition
                    }
                    it("can be an inverse transform") {
                        let plainInversePipeline = try! plainPJ.inverse!.asPipeline()
                        expect(plainInversePipeline.isPipeline) == true
                        expect(plainInversePipeline.pipelineSteps.count) == 1
                        expect(plainInversePipeline.pipelineSteps[0]) == "\(plainPJ.definition) inv"
                    }
                }
                it("doesn't convert existing pipelines") {
                    expect(try! pipelinePJ.asPipeline()) === pipelinePJ
                }
                it("can enumerate the steps") {
                    expect(complexPipeline.pipelineSteps.count) == 2
                    expect(complexPipeline.pipelineSteps[0]) == "proj=merc"
                    expect(complexPipeline.pipelineSteps[1]) == "proj=axisswap order=2,1"
                }
                it("can show global settings") {
                    expect(complexPipeline.pipelineGlobals) == "proj=pipeline ellps=GRS80"
                }
                context("when being built incrementally") {
                    func testAppendString(_ pj: Projection) {
                        let newPipeline = try! pj.appendStep(projString: "proj=axisswap order=2,1")
                        expect(newPipeline.pipelineSteps[0]) == "proj=merc lat_ts=56.5 ellps=GRS80"
                        expect(newPipeline.pipelineSteps[1]) == "proj=axisswap order=2,1"
                    }
                    func testAppendProjection(_ pj: Projection) {
                        let newPipeline = try! pj.appendStep(
                            projection: try! Projection(projString: "proj=axisswap order=2,1 no_defs"))
                        expect(newPipeline.pipelineSteps[0]) == "proj=merc lat_ts=56.5 ellps=GRS80"
                        expect(newPipeline.pipelineSteps[1]) == "proj=axisswap order=2,1 no_defs"
                    }
                    context("when starting with a pipeline") {
                        it("can add steps as strings") {
                            testAppendString(pipelinePJ)
                        }
                        it("can add steps from projections") {
                            testAppendProjection(pipelinePJ)
                        }
                    }
                    context("when starting with a plain projection") {
                        it("can add steps as strings") {
                            testAppendString(plainPJ)
                        }
                        it("can add steps from projections") {
                            testAppendProjection(plainPJ)
                        }
                    }
                    context("when adding pipelines as steps") {
                        it("throws when adding constructed pipelines as steps") {
                            // This is not set in stone, there are ways around this. They're not done, but possible
                            // Again, peeking into projects.h for the definition of PJD_ERR_MALFORMED_PIPELINE
                            expect { try complexPipeline.appendStep(projection: pipelinePJ) }.to(
                                throwError(ProjectionError.LibraryError(code: -50)))
                        }
                    }
                }
            }
        }
    }
}
