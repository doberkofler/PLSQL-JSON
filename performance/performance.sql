/*
 *
 * NAME
 *	performance.sql
 *
 * AUTHOR
 *	Dieter Oberkofler
 *
 * FUNCTION
 *	Install and run the performance compare between  the plsql_json module and pljson
 *
 */


----------------------------------------------------------
--	PREPARE
--
set termout      off
set echo         off
set define       on
set verify       on
set feedback     on
set heading      on
set pause        off
set trimout      on
set trimspool    on
set pagesize     10000
set linesize     10000
set long         32767
set longc        32767
set serveroutput on size 1000000
set appinfo      'performance.sql'
set timing       on
whenever sqlerror exit 1
whenever oserror exit 1


----------------------------------------------------------
--	UNINSTALL (WHATEVER MIGHT BE LEFT)
--
@@json_v1_0_4/uninstall.sql
@@../uninstall.sql


----------------------------------------------------------
--	TEST THE PLSQL_JSON MODULE
--

-- install plsql_json
@@../install.sql

set termout on
-- run the test
DECLARE
	aObj						json_object			:=	json_object();
	aSubObj						json_object			:=	json_object();
	aList						json_array			:=	json_array();
	aSubList					json_array			:=	json_array();
	aLob						CLOB				:=	empty_clob();

	startTime					BINARY_INTEGER;
	totalTime					BINARY_INTEGER		:= dbms_utility.get_time;

	i							BINARY_INTEGER;
BEGIN
	--	build a complex and big json object in memory
	startTime := dbms_utility.get_time;
	FOR i IN 1 .. 10 LOOP
		aSubObj := json_object();
		aSubObj.put('number', i);
		aSubList.append(aSubObj);
	END LOOP;
	FOR i IN 1 .. 1000 LOOP
		aObj := json_object();
		aObj.put('number', i);
		aObj.put('string', 'a nice little string');
		aObj.put('boolean', TRUE);
		aObj.put('list', aSubList.to_json_value());
		aList.append(aObj);
	END LOOP;
	dbms_output.put_line('plsql_json: Building json object: duration = "'||ROUND((dbms_utility.get_time - startTime) / 100, 3)||'"');

	--	serialize the json object to a clob
	dbms_lob.createtemporary(aLob, TRUE);
	aList.to_clob(aLob);
	dbms_output.put_line('plsql_json: Serialize json object into CLOB: duration = "'||ROUND((dbms_utility.get_time - startTime) / 100, 3)||'"');

    dbms_lob.freetemporary(aLob);

	dbms_output.put_line('plsql_json: Total duration = "'||ROUND((dbms_utility.get_time - totalTime) / 100, 3)||'"');
END;
/

-- uninstall
@@../uninstall.sql


----------------------------------------------------------
--	TEST THE PLJSON MODULE
--

-- install pljson
@@json_v1_0_4/install.sql

set termout on
-- run the test
DECLARE
	aObj						json				:=	json();
	aSubObj						json				:=	json();
	aList						json_list			:=	json_list();
	aSubList					json_list			:=	json_list();
	aLob						CLOB				:=	empty_clob();

	startTime					BINARY_INTEGER;
	totalTime					BINARY_INTEGER		:= dbms_utility.get_time;

	i							BINARY_INTEGER;
BEGIN
	--	build a complex and big json object in memory
	startTime := dbms_utility.get_time;
	FOR i IN 1 .. 10 LOOP
		aSubObj := json();
		aSubObj.put('number', i);
		aSubList.append(aSubObj.to_json_value());
	END LOOP;
	FOR i IN 1 .. 1000 LOOP
		aObj := json();
		aObj.put('number', i);
		aObj.put('string', 'a nice little string');
		aObj.put('boolean', TRUE);
		aObj.put('list1', aSubList.to_json_value());
		aObj.put('list2', aSubList.to_json_value());
		aList.append(aObj.to_json_value());
	END LOOP;
	dbms_output.put_line('plsql_json: Building json object: duration = "'||ROUND((dbms_utility.get_time - startTime) / 100, 3)||'"');

	--	serialize the json object to a clob
	dbms_lob.createtemporary(aLob, TRUE);
	aList.to_clob(aLob);
	dbms_output.put_line('plsql_json: Serialize json object into CLOB: duration = "'||ROUND((dbms_utility.get_time - startTime) / 100, 3)||'"');

    dbms_lob.freetemporary(aLob);

	dbms_output.put_line('plsql_json: Total duration = "'||ROUND((dbms_utility.get_time - totalTime) / 100, 3)||'"');
END;
/

-- uninstall
@@json_v1_0_4/uninstall.sql
