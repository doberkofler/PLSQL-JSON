/*
 *
 * NAME
 *	unittest.sql
 *
 * AUTHOR
 *	Dieter Oberkofler
 *
 * FUNCTION
 *	Install and run the unit tests for the plsql_json module
 *
 */


-- environment
set pagesize 10000 linesize 10000 trimout on trimspool on

-- delete existing objects
whenever sqlerror continue
DROP TABLE UT_test_table;
DROP SEQUENCE UT_test_seq;
whenever sqlerror exit 1

-- install objects
CREATE TABLE UT_test_table
(
	ID					NUMBER			NOT NULL,		--	test id
	When				TIMESTAMP		NOT NULL,		--	timestamp
	Module				VARCHAR2(2000)	NOT NULL,		--	module name
	Title				CLOB			NOT NULL,		--	test name
	Success				CHAR(1)			NOT NULL		--	was test successful (1=yes, 0=no)
						CHECK(Success IN ('Y', 'N')),
	Result				CLOB,
	Expected			CLOB,
	Computed			CLOB
);
CREATE SEQUENCE UT_test_seq START WITH 1;

-- install the unit test framework
@@UT_util.pks
show errors
@@UT_util.pkb
show errors

-- load the unit tests
@@json_ut.pks
show errors
@@json_ut.pkb
show errors
@@json_sql_ut.pks
show errors
@@json_sql_ut.pkb
show errors

-- run the unit tests
BEGIN
	json_ut.prepare;
	json_ut.run;
	json_ut.cleanup;

	json_sql_ut.prepare;
	json_sql_ut.run;
	json_sql_ut.cleanup;
END;
/

-- show the results
SELECT 'Successful unit tests: '||C "Unit test results" FROM (SELECT COUNT(*) C FROM plsql_json.UT_test_table WHERE Success = 'Y')
UNION
SELECT 'Failed unit tests: '||C "Unit test results" FROM (SELECT COUNT(*) C FROM plsql_json.UT_test_table WHERE Success = 'N')
ORDER BY 1 DESC;

-- show the errors
column Module format a30
column Title format a30
column Result format a30
column Expected format a30
column Computed format a30
SELECT		ID, Module, Title, Result, Expected, Computed
FROM		UT_test_table
WHERE		Success = 'N'
ORDER BY	ID;

-- cleanup
whenever sqlerror continue
DROP TABLE UT_test_table;
DROP SEQUENCE UT_test_seq;
DROP PACKAGE json_ut;
DROP PACKAGE json_sql_ut;
DROP PACKAGE UT_util;
whenever sqlerror exit 1
