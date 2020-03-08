CREATE OR REPLACE
PACKAGE json_sql
IS

------------
--  OVERVIEW
--
--  This package allows to dynamically generate a json representation of the rows in a select.
--
--

-----------
--  EXAMPLE
--
--	2) Simple select
--
--	2.1) from code
--	BEGIN
--		json_sql.htp('select * from user_tables order by table_name');
--	END;
--
--	2.2) from browser
--	json_sql.htp?sqlCmd=select * from user_tables order by table_name
--
--
--	3) Select with bind variables and format rows as objects
--
--	3.1) from code
--	DECLARE
--		aBind jsonObject := jsonObject();
--	BEGIN
--		aBind.put('name', 'F');
--		json_sql.get(sqlCmd=>'select * from user_tables where UPPER(table_name) > :name', sqlBind=>aBind, format=>json_sql.FORMAT_OBJ).htp();
--	END;
--
--	3.2) from browser
--		json_sql.htp?sqlCmd=select+*+from+user_tables+where+UPPER(table_name)+%3e+%3aname&sqlbind={"name":"F"}&format=obj
--
--

-------------
--  RESOURCES
--
--

----------------------------------------------------------
--	GLOBAL PUBLIC EXCEPTIONS
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL PUBLIC TYPES
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL PUBLIC CONSTANTS
----------------------------------------------------------

-- format
FORMAT_TAB	CONSTANT	VARCHAR2(3)	:=	'TAB';
FORMAT_OBJ	CONSTANT	VARCHAR2(3)	:=	'OBJ';

-- null binding
NULL_OBJECT CONSTANT	jsonObject := jsonObject();

----------------------------------------------------------
--	GLOBAL PUBLIC ENUMERATIONS
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL PUBLIC VARIABLES
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL PUBLIC MODULES
----------------------------------------------------------

----------------------------------------------------------
--	Execute SYS_REFCURSOR and output a json structure
--
FUNCTION get(rc IN OUT SYS_REFCURSOR, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN jsonObject;

----------------------------------------------------------
--	Execute sql statement and return a josn object
--
FUNCTION get(sqlCmd VARCHAR2, sqlBind jsonObject DEFAULT NULL_OBJECT, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN jsonObject;

----------------------------------------------------------
--	Execute sql statement and output a json structure
--
PROCEDURE htp(sqlCmd VARCHAR2, sqlBind IN VARCHAR2 DEFAULT NULL, format IN VARCHAR2 DEFAULT FORMAT_TAB);

END json_sql;
/
