# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [?.?.?] - ????-??-??

### Added
### Changed
### Fixed


## [0.5.0] - 2020-03-08

### Changed
- No longer install debug module by default.
- Removed package json_cost and json_clob.


### Fixed
- Required naming changes to run on current Oracle versions that now also have json support.


## [0.4.1] - 2016-12-22

### Changed
- Improved the performance when working with CLOB values by 10 to 100 times depending on the actual CLOB length. (Dieter Oberkofler)


## [0.4.0] - 2016-12-8

### Added
- Added support for CLOB properties. (Dieter Oberkofler)
- Added support to update properties. (Dieter Oberkofler)
- Added a new module json_sql that allows to dynamically generate a json representation of the rows in a select with bind variables. (Dieter Oberkofler)


## [0.3.1] - 2016-03-16

### Fixed
- Fixed a problem when escaping a string that ends with CHR(10). (Dieter Oberkofler)


## [0.3.0] - 2014-12-15

### Added
- Improved the performance of object_to_clob and array_to_clob by up to 400%. (Dieter Oberkofler)
- Added a few special values tests. (Dieter Oberkofler)


## [0.2.0] - 2014-06-19

### Added
- Now using 3 individual parse methods in json_parser allowing to parse an object, an array or any of the two. (Dieter Oberkofler)
- Added a new constructor to json_array allowing to parse a JSON string representing an array. Proposed by matthias-oe. (Dieter Oberkofler)
- Added a new constructor to json_value allowing to parse a JSON string representing an object or an array. (Dieter Oberkofler)
- Added unit tests for the new functionality. (Dieter Oberkofler)


## [0.1.0] - 2014-04-26

### Added
- Added support for DATE types.
- Added support for JSONP.


## [0.0.1] - 2013-09-24

### Added
- Initial release of plsql_json.
