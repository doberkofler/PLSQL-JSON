v0.4.1 - December 22, 2016
* 0.4.1 (Dieter Oberkofler)
* Improved the performance when working with CLOB values by 10 to 100 times depending on the actual CLOB length. (Dieter Oberkofler)

v0.4.0 - December 8, 2016
* 0.4.0 (Dieter Oberkofler)
* Added support for CLOB properties. (Dieter Oberkofler)
* Added support to update properties. (Dieter Oberkofler)
* Added a new module json_sql that allows to dynamically generate a json representation of the rows in a select with bind variables. (Dieter Oberkofler)

v0.3.1 - March 16, 2016
* 0.3.1 (Dieter Oberkofler)
* Fixed a problem when escaping a string that ends with CHR(10). (Dieter Oberkofler)

v0.3.0 - December 15, 2014
* 0.3.0 (Dieter Oberkofler)
* Improved the performance of object_to_clob and array_to_clob by up to 400%. (Dieter Oberkofler)
* Added a few special values tests. (Dieter Oberkofler)

v0.2.0 - June 19, 2014
* 0.2.0 (Dieter Oberkofler)
* Now using 3 individual parse methods in json_parser allowing to parse an object, an array or any of the two. (Dieter Oberkofler)
* Added a new constructor to json_array allowing to parse a JSON string representing an array. Proposed by matthias-oe. (Dieter Oberkofler)
* Added a new constructor to json_value allowing to parse a JSON string representing an object or an array. (Dieter Oberkofler)
* Added unit tests for the new functionality. (Dieter Oberkofler)

v0.1.0 - April 26, 2014
* 0.1.0 (Dieter Oberkofler)
* Added support for DATE types.
* Added support for JSONP.

v0.0.1 - September 24, 2013
* 0.0.1 (Dieter Oberkofler)
* Initial release of plsql_json.
