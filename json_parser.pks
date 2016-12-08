CREATE OR REPLACE
PACKAGE json_parser IS

------------
--  OVERVIEW
--
--  ...
--
--

-----------
--  EXAMPLE
--
--

-------------
--  RESOURCES
--
--

----------------------------------------------------------
--	GLOBAL PUBLIC TYPES
----------------------------------------------------------

--	scanner tokens: '{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL
TYPE rToken IS RECORD
(
	type_name		VARCHAR2(7),
	line			PLS_INTEGER,
	col				PLS_INTEGER,
	data			VARCHAR2(32767),
	data_overflow	clob
);

TYPE lTokens IS TABLE OF rToken INDEX BY PLS_INTEGER;
TYPE json_src IS RECORD (len NUMBER, offset NUMBER, src VARCHAR2(32767), s_clob CLOB);

----------------------------------------------------------
--	GLOBAL PUBLIC CONSTANTS
----------------------------------------------------------

---------------------------------------------------------
--	GLOBAL VARIABLES
----------------------------------------------------------

json_strict BOOLEAN NOT NULL := FALSE;

----------------------------------------------------------
--	GLOBAL PUBLIC MODULES
----------------------------------------------------------

FUNCTION parser(str CLOB) RETURN json_nodes;
FUNCTION parse_list(str CLOB) RETURN json_nodes;
FUNCTION parse_any(str CLOB) RETURN json_nodes;

END json_parser;
/
