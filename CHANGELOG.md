# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).


## [?.?.?] - ????-??-??

### Added
### Changed
### Fixed


## [0.7.1] - 2020-03-11

### Fixed
- Fixed an alignment problem in the pretty output of json.


## [0.7.0] - 2020-03-09

### Changed
- Added output configuration option `newline_char` for the end of line style and `indentation_char` for the indentation style.


## [0.6.0] - 2020-03-09

### Changed
- Added api `get_default_options`, `get_options` and `set_options` to `json_utils`package to configure (`Pretty`, `ascii_output` and `escape_solitus`) the output.
- Added support for formatted (pretty) json output with the option `Pretty`.


### Fixed
- Fixed another error when converting `\f` and `\r`.


## [0.5.0] - 2020-03-08

### Changed
- No longer install debug module by default.
- Removed package `json_cost` and `json_clob`.
- Removed the obsolete performance tests.


### Fixed
- Required naming changes to run on current Oracle versions that now also have json support.
- Fixed an error when converting `\f` and `\r`.


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
