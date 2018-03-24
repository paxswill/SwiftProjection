# Changelog

## [1.0.4] - 2018-03-24
### Added
* `inputIsAngular` and `outputIsAngular` properties on `Projection`, exposing
  the output of `proj_angular_input` and `proj_angular_output` respectively.

## [1.0.3] - 2018-03-24
### Added
* `longitude` and `latitude` properties on `ProjectionCoordinate`
* `asCLLocationCoordinate2D()` function on `ProjectionCoordinate` to ease usage
  with other APIs.

## [1.0.2] - 2018-03-24
### Changes
* Minimum iOS version raised to 9.0, mainly because the test suite is failing
  to run on 8.0.
* Quick and Nimble have been removed from the base spec requirements. They're
  only used in the test suite, and were only included to allow the test spec to
work with `pod lib lint` on CocoaPods <= 1.4.0.

## [1.0.1] - 2018-03-22
### Fixed
* Tests fixed to use new `transform(coordinate:)` signature.

## [1.0.0] - 2018-03-22
* Initial Release of SwiftProjection. This framework is a thin bridge between
Swift and PROJ, focusing on the new API introduced in PROJ v5.0.0.
