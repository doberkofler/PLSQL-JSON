CREATE OR REPLACE
PACKAGE BODY json_sql_UT IS

--	$Id: json_sql_ut.pkb 49652 2016-12-08 18:17:30Z doberkofler $

----------------------------------------------------------
--	PRIVATE TYPES
----------------------------------------------------------

----------------------------------------------------------
--	PRIVATE CONSTANTS
----------------------------------------------------------

TODAY		CONSTANT	DATE			:=	TRUNC(SYSDATE);

----------------------------------------------------------
--	LOCAL MODULES
----------------------------------------------------------

FUNCTION toJSON(theDate IN DATE) RETURN VARCHAR2;

----------------------------------------------------------
--	GLOBAL MODULES
----------------------------------------------------------

----------------------------------------------------------
--	test a dynamic select statement returning objects (private)
--
PROCEDURE UT_object
IS
	ROW_1	CONSTANT	VARCHAR2(2000)	:=	'{"ID":1,"NAME":"john doe","BIRTHDAY":"'||toJSON(TODAY)||'"}';
	ROW_2	CONSTANT	VARCHAR2(2000)	:=	'{"ID":2,"NAME":"robin williams","BIRTHDAY":"'||toJSON(TODAY+1)||'"}';
	ROW_3	CONSTANT	VARCHAR2(2000)	:=	'{"ID":3,"NAME":"martin donovan","BIRTHDAY":"'||toJSON(TODAY+2)||'"}';

	aSql				VARCHAR2(2000);
	aBinding			json_object		:=	json_object();
	aLob				CLOB			:=	empty_clob();
BEGIN
	UT_util.module('UT_object');

	-- allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	-- select all rows
	aSql := 'SELECT * FROM temp_json_sql_ut ORDER BY id';
	json_sql.get(theSqlStatement=>aSql, format=>json_sql.FORMAT_OBJ).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{"rows":['||ROW_1||','||ROW_2||','||ROW_3||']}'),
					theNullOK	=>	TRUE
					);

	-- select one row
	aSql := 'SELECT * FROM temp_json_sql_ut WHERE id = 2';
	json_sql.get(theSqlStatement=>aSql, format=>json_sql.FORMAT_OBJ).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{"rows":['||ROW_2||']}'),
					theNullOK	=>	TRUE
					);

	-- select one row using bind variables
	aSql := 'SELECT * FROM temp_json_sql_ut WHERE id = :id';
	aBinding.put('id', 3);
	json_sql.get(theSqlStatement=>aSql, theBinding=>aBinding, format=>json_sql.FORMAT_OBJ).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{"rows":['||ROW_3||']}'),
					theNullOK	=>	TRUE
					);

	-- select no row
	aSql := 'SELECT * FROM temp_json_sql_ut WHERE id = 0';
	json_sql.get(theSqlStatement=>aSql, format=>json_sql.FORMAT_OBJ).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{"rows":[]}'),
					theNullOK	=>	TRUE
					);

	--	cleanup
	dbms_lob.freetemporary(aLob);
END UT_object;

----------------------------------------------------------
--	test a dynamic select statement returning arrays (private)
--
PROCEDURE UT_array
IS
	COLS	CONSTANT	VARCHAR2(2000)	:=	'"cols":["ID","NAME","BIRTHDAY"]';
	ROW_1	CONSTANT	VARCHAR2(2000)	:=	'[1,"john doe","'||toJSON(TODAY)||'"]';
	ROW_2	CONSTANT	VARCHAR2(2000)	:=	'[2,"robin williams","'||toJSON(TODAY+1)||'"]';
	ROW_3	CONSTANT	VARCHAR2(2000)	:=	'[3,"martin donovan","'||toJSON(TODAY+2)||'"]';

	aSql				VARCHAR2(2000);
	aBinding			json_object		:=	json_object();
	aLob				CLOB			:=	empty_clob();
BEGIN
	UT_util.module('UT_array');

	-- allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	-- select all rows
	aSql := 'SELECT * FROM temp_json_sql_ut ORDER BY id';
	json_sql.get(theSqlStatement=>aSql).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{'||COLS||',"rows":['||ROW_1||','||ROW_2||','||ROW_3||']}'),
					theNullOK	=>	TRUE
					);

	-- select one row
	aSql := 'SELECT * FROM temp_json_sql_ut WHERE id = 2';
	json_sql.get(theSqlStatement=>aSql).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{'||COLS||',"rows":['||ROW_2||']}'),
					theNullOK	=>	TRUE
					);

	-- select one row using bind variables
	aSql := 'SELECT * FROM temp_json_sql_ut WHERE id = :id';
	aBinding.put('id', 3);
	json_sql.get(theSqlStatement=>aSql, theBinding=>aBinding).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{'||COLS||',"rows":['||ROW_3||']}'),
					theNullOK	=>	TRUE
					);

	-- select no row
	aSql := 'SELECT * FROM temp_json_sql_ut WHERE id = 0';
	json_sql.get(theSqlStatement=>aSql).to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aSql,
					theComputed	=>	aLob,
					theExpected	=>	TO_CLOB('{'||COLS||',"rows":[]}'),
					theNullOK	=>	TRUE
					);

	--	cleanup
	dbms_lob.freetemporary(aLob);
END UT_array;

----------------------------------------------------------
--	toJSON (private)
--
FUNCTION toJSON(theDate IN DATE) RETURN VARCHAR2
IS
BEGIN
	RETURN TO_CHAR(theDate, 'FXYYYY-MM-DD"T"HH24:MI:SS');
END toJSON;

----------------------------------------------------------
--	Run unit tests
--
PROCEDURE run
IS
BEGIN
	UT_object;
	UT_array;
END run;

----------------------------------------------------------
--	Prepare unit test
--
PROCEDURE prepare
IS
BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE temp_json_sql_ut';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	EXECUTE IMMEDIATE 'CREATE TABLE temp_json_sql_ut (id NUMBER, name VARCHAR2(30), birthday DATE)';
	EXECUTE IMMEDIATE 'INSERT INTO temp_json_sql_ut VALUES (:1, :2, :3)' USING 1, 'john doe', TODAY;
	EXECUTE IMMEDIATE 'INSERT INTO temp_json_sql_ut VALUES (:1, :2, :3)' USING 2, 'robin williams', TODAY + 1;
	EXECUTE IMMEDIATE 'INSERT INTO temp_json_sql_ut VALUES (:1, :2, :3)' USING 3, 'martin donovan', TODAY + 2;
END prepare;

----------------------------------------------------------
--	Cleanup unit test
--
PROCEDURE cleanup
IS
BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE temp_json_sql_ut';
END cleanup;

END json_sql_UT;
/
