//
//  TestProjection.swift
//  Proj.Swift-Unit-Tests
//
//  Created by Will Ross on 3/13/18.
//

import Quick
import Nimble
import CoreLocation
@testable import Proj

class ProjectionSpec: QuickSpec {
    override func spec() {
        describe("a projection") {
            it("can be created from a proj string") {
                let projString = "+proj=merc +lat_ts=56.5 +ellps=GRS80"
                let pj = Projection(projString: projString)
                // PROJ canonicalizes definitions strings to not include the '+' signs
                let canonical = projString.replacingOccurrences(of: "+", with: "")
                expect(pj.definition).to(equal(canonical))
                // This also exercises bundle-reader (to read the defaults file), but doesn't fail if it doesn't work.
            }
            it("can be created from a well known identitifer") {
                // This is indirectly testing the bundle-reader functionality
                let initString = "epsg:3857"
                let canonical = "init=epsg:3857 proj=merc a=6378137 b=6378137 lat_ts=0.0 lon_0=0.0 x_0=0.0 y_0=0 k=1.0 units=m nadgrids=@null no_defs"
                let pj = Projection(identifier: initString)
                expect(pj.definition).to(equal(canonical))
            }
            context("transforms coordinates") {
                let pj = Projection(projString: "+proj=merc +lat_ts=56.5 +ellps=GRS80")
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
                    let output = pj.transform(geodetic)
                    expectProjected(output)
                }
                it("can use be inverted") {
                    let output = pj.inverse!.transform(projected)
                    expectGeodetic(output)
                    // The definition is the same, just the direction is different
                    expect(pj.definition) == pj.inverse!.definition
                }
                it("can use the gt operator to transform") {
                    let output = geodetic > pj
                    expectProjected(output)
                }
                xit("can use the gt and neg operators to do an inverse transform") {
                    // TODO: Continue here, implement negation operator
                    let output = projected > (-pj)!
                    expectGeodetic(output)
                }
                // TODO continue here
            }
        }
    }
}
