CREATE OR REPLACE
PACKAGE UT_util IS

------------
--  OVERVIEW
--
--  This package contains the framework for PL/SQL unit tests.
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
--	GLOBAL PUBLIC EXCEPTIONS
----------------------------------------------------------


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
--	Identify the current test module
--
PROCEDURE module(theModule IN VARCHAR2);

----------------------------------------------------------
--	Test for equality of VARCHAR2
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				VARCHAR2,
				theComputed	IN				VARCHAR2,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				);

----------------------------------------------------------
--	Test for equality of BOOLEAN
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				BOOLEAN,
				theComputed	IN				BOOLEAN,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				);

----------------------------------------------------------
--	Test for equality of NUMBER
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				NUMBER,
				theComputed	IN				NUMBER,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				);

----------------------------------------------------------
--	Test for equality of DATE
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				DATE,
				theComputed	IN				DATE,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				);

----------------------------------------------------------
--	Test for equality of CLOB
--	We are using a different name to preventing problems
--	when mixing with eVARCHAR2 signature.
--
PROCEDURE eqLOB(theTitle	IN				VARCHAR2,
				theExpected	IN				CLOB,
				theComputed	IN				CLOB,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				);

----------------------------------------------------------
--	Test for equality of BLOB
--	We are using a different name to preventing problems
--	when mixing with eVARCHAR2 signature.
--
PROCEDURE eqLOB(theTitle	IN				VARCHAR2,
				theExpected	IN				BLOB,
				theComputed	IN				BLOB,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				);

----------------------------------------------------------
--	Test if the condition is TRUE
--
PROCEDURE ok(	theTitle	IN				VARCHAR2,
				theValue	IN				BOOLEAN
				);

----------------------------------------------------------
--	Test if the condition is FALSE
--
PROCEDURE ko(	theTitle	IN				VARCHAR2,
				theValue	IN				BOOLEAN
				);

---------------------------------------------------------
--	Convert to string
--
FUNCTION asString(theValue IN VARCHAR2) RETURN VARCHAR2;

----------------------------------------------------------
--	Convert to string
--
FUNCTION asString(theValue IN NUMBER) RETURN VARCHAR2;

----------------------------------------------------------
--	Convert to string
--
FUNCTION asString(theValue IN BOOLEAN) RETURN VARCHAR2;

----------------------------------------------------------
--	Convert to string
--
FUNCTION asString(theValue IN DATE) RETURN VARCHAR2;

----------------------------------------------------------
--	Convert a CLOB value to string
--	We are using a different name to preventing problems
--	when mixing with eVARCHAR2 signature.
--
FUNCTION asStringLOB(theValue IN CLOB) RETURN VARCHAR2;

----------------------------------------------------------
--	Convert a BLOB value to string
--	We are using a different name to preventing problems
--	when mixing with eVARCHAR2 signature.
--
FUNCTION asStringLOB(theValue IN BLOB) RETURN VARCHAR2;


END UT_util;
/
