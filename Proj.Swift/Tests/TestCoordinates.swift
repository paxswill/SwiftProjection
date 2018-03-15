//
//  TestCoordinates.swift
//  Proj.Swift_Tests
//
//  Created by Will Ross on 3/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import CoreLocation
@testable import Proj

class CoordinatesSpec: QuickSpec {
    override func spec() {
        describe("a projection coordinate") {
            var coord: ProjectionCoordinate!
            beforeEach {
                coord = ProjectionCoordinate(u: 1, v: 2, w: 3, t: 4)
            }
            it("has u") {
                expect(coord.u).to(equal(1))
            }
            it("has v") {
                expect(coord.v).to(equal(2))
            }
            it("has w") {
                expect(coord.w).to(equal(3))
            }
            it("has t") {
                expect(coord.t).to(equal(4))
            }
            context("when only given 2D values") {
                var coord: ProjectionCoordinate!
                beforeEach {
                    coord = ProjectionCoordinate(u: 9, v: 18)
                }
                it("defaults w to 0") {
                    expect(coord.w).to(equal(0))
                }
                it("defaults t to 0") {
                    expect(coord.t).to(equal(0))
                }
            }
            context("when given a lat/lon") {
                var coord: ProjectionCoordinate!
                beforeEach {
                    coord = ProjectionCoordinate(latitude: 44, longitude: -130.5, altitude: 30, time: 0)
                }
                it("has latitude as v in radians") {
                    expect(coord.v) ≈ 0.767945 ± 0.00001
                }
                it("has longitude as u in radians") {
                    expect(coord.u) ≈ -2.2776547 ± 0.00001
                }
            }
            it("returns itself for getCoordinate") {
                expect(coord.getCoordinate()).to(equal(coord))
            }
            it("is convertible") {
                expect(coord).to(beAKindOf(ConvertibleCoordinate.self))
            }
            it("can return a PJ_COORD") {
                let returned = coord.getProjCoordinate()
                expect(returned).to(beAKindOf(PJ_COORD.self))
                expect(returned.uvwt.u).to(equal(coord.u))
                expect(returned.uvwt.v).to(equal(coord.v))
                expect(returned.uvwt.w).to(equal(coord.w))
                expect(returned.uvwt.t).to(equal(coord.t))
            }
        }
        describe("a CoreLocation coordinate") {
            it("can be converted") {
                let clCoord = CLLocationCoordinate2DMake(77.54, -32.1)
                expect(clCoord.getCoordinate()).to(equal(
                    ProjectionCoordinate(latitude: 77.54, longitude: -32.1)
                ))
            }
        }
    }
}
