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

/**
 Any type conforming to `ConvertibleCoordinate` can be transformed by `Projection.transform`.
 `ProjectionCoordinate` is available as a default implementation, and extensions for `CLLocationCoordinate2D` and
 `MKMapPoint` are also available.
 */
public protocol ConvertibleCoordinate {

    /**
     Convert this value into a `ProjectionCoordinate`
     */
    func getCoordinate() -> ProjectionCoordinate
}

/**
 A concrete implementation of `ConvertibleCoordinate`, used as the return value of `Projection.transform()`
 */
public struct ProjectionCoordinate: ConvertibleCoordinate, Equatable {
    public var u: Double
    public var v: Double
    public var w: Double
    public var t: Double

    /**
     Create a coordinate. The components are multi-use in some cases (particularly `u` and `v`) and may depend on the
     context.

     - Note: if using `u` and `v` as longitude and latitude, the values should be in radians, not decimal degrees.
     Using `init(latitude:longitude:altitude:time)` is recommended in this case.

     - Parameters:
       - u: longitude, easting, or X component.
       - v: latitude, northing, or Y component.
       - w: vertical component. Defaults to 0.
       - t: temporal component. Defaults to 0.
     */
    public init(u: Double, v: Double, w: Double = 0.0, t: Double = 0.0) {
        self.u = u
        self.v = v
        self.w = w
        self.t = t
    }

    /**
     Create a coordinate using latitude and longitude. This initializer expects decimal degrees for the horizontal
     components, unlike `init(u:v:w:t)`.

     - Parameters:
       - latitude: latitude, in decimal degrees.
       - longitude: longitude, in decimal degrees.
       - altitude: altitude, in unspecified units. Defaults to 0.
       - time: time, in unspecified units. Defaults to 0.
     */
    public init(latitude: Double, longitude: Double, altitude: Double = 0.0, time: Double = 0.0) {
        let latRad = proj_torad(latitude)
        let lonRad = proj_torad(longitude)
        self.init(u: lonRad, v: latRad, w: altitude, t: time)
    }

    /**
     An internal initializer that sources it's data from a given `PJ_COORD`. The PJ_UVWT form is used to access the data
     (not that it should matter).
     */
    internal init(_ projCoordinate: PJ_COORD) {
        self.init(
            u: projCoordinate.uvwt.u,
            v: projCoordinate.uvwt.v,
            w: projCoordinate.uvwt.w,
            t: projCoordinate.uvwt.t
        )
    }

    /**
     Required for conformance to `ConvertibleCoordinate`. Just returns `self`.
     */
    public func getCoordinate() -> ProjectionCoordinate {
        return self
    }

    /**
     Internal function that returns a `PJ_COORD` structure with this structure's `u`, `v`, `w` and `t` values.
     */
    internal func getProjCoordinate() -> PJ_COORD {
        return proj_coord(u, v, w, t)
    }
}

extension CLLocationCoordinate2D: ConvertibleCoordinate {

    /**
     Conforms `CLLocationCoordinate2D` to `ConvertibleCoordinate`. Just uses the latitude and longitude members of the
     coordinate to initialize the `ProjectionCoordinate`.
     */
    public func getCoordinate() -> ProjectionCoordinate {
        return ProjectionCoordinate(latitude: self.latitude, longitude: self.longitude)
    }
}

extension MKMapPoint: ConvertibleCoordinate {

    /**
     Conforms `MKMapPoint` to `ConvertibleCoordinate`.

     - Note: This implementation currently converts the map point to a `CLLocationCoordinate2D` and using that value to
     initialize the `ProjectionCoordinate`.
     */
    public func getCoordinate() -> ProjectionCoordinate {
        let coordinate = MKCoordinateForMapPoint(self)
        return coordinate.getCoordinate()
    }
}
