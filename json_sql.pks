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
--	1) Simple select
--
--	1.1) from code
--	BEGIN
--		json_sql.htp('select * from user_tables order by table_name');
--	END;
--
--	1.2) from browser
--	json_sql.htp?sqlCmd=select * from user_tables order by table_name
--
--
--	2) Select with bind variables and format rows as objects
--
--	2.1) from code
--	DECLARE
--		aBind json_object := json_object();
--	BEGIN
--		aBind.put('name', 'F');
--		json_sql.htp(sqlCmd=>'select * from user_tables where UPPER(table_name) > :name', sqlBind=>aBind, format=>json_sql.FORMAT_OBJ);
--	END;
--
--	2.2) from browser
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
NULL_OBJECT CONSTANT	json_object := json_object();

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
--	Execute sql statement and return a josn object
--
FUNCTION get(theSqlStatement VARCHAR2, theBinding json_object DEFAULT NULL_OBJECT, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN json_object;

----------------------------------------------------------
--	Execute sql statement and output a json structure
--
PROCEDURE htp(sqlCmd VARCHAR2, sqlBind IN VARCHAR2 DEFAULT NULL, format IN VARCHAR2 DEFAULT FORMAT_TAB);

END json_sql;
/
