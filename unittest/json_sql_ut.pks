CREATE OR REPLACE
PACKAGE json_sql_UT IS

--	$Id: json_sql_ut.pks 47795 2016-04-27 17:48:21Z doberkofler $

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
