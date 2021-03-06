CREATE OR REPLACE
PACKAGE json_sql_UT IS

------------
--  OVERVIEW
--
--  Unit tests for the PL/SQL JSON library dynamic SQL interface
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

----------------------------------------------------------
--	GLOBAL PUBLIC CONSTANTS
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL PUBLIC VARIABLES
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL PUBLIC MODULES
----------------------------------------------------------

----------------------------------------------------------
--	Run unit tests
--
PROCEDURE prepare;
PROCEDURE run;
PROCEDURE cleanup;

END json_sql_UT;
/
