//
//  Point.swift
//  PROJ.Swift
//
//  Created by Will Ross on 3/8/18.
//  Copyright © 2018 Will Ross. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

public protocol ConvertibleCoordinate {
    func getCoordinate() -> ProjectionCoordinate
}

public struct ProjectionCoordinate: ConvertibleCoordinate, Equatable {
    public var u: Double
    public var v: Double
    public var w: Double
    public var t: Double

    public init(u: Double, v: Double, w: Double = 0.0, t: Double = 0.0) {
        self.u = u
        self.v = v
        self.w = w
        self.t = t
    }

    public init(latitude: Double, longitude: Double, altitude: Double = 0.0, time: Double = 0.0) {
        self.init(u: longitude, v: latitude, w: altitude, t: time)
    }

    internal init(_ projCoordinate: PJ_COORD) {
        self.init(
            u: projCoordinate.uvwt.u,
            v: projCoordinate.uvwt.v,
            w: projCoordinate.uvwt.w,
            t: projCoordinate.uvwt.t
        )
    }

    public func getCoordinate() -> ProjectionCoordinate {
        return self
    }

    internal func getProjCoordinate() -> PJ_COORD {
        return proj_coord(u, v, w, t)
    }
}

extension CLLocationCoordinate2D: ConvertibleCoordinate {
    public func getCoordinate() -> ProjectionCoordinate {
        return ProjectionCoordinate(latitude: self.latitude, longitude: self.longitude)
    }
}

extension MKMapPoint: ConvertibleCoordinate {
    public func getCoordinate() -> ProjectionCoordinate {
        let coordinate = MKCoordinateForMapPoint(self)
        return coordinate.getCoordinate()
    }
}
