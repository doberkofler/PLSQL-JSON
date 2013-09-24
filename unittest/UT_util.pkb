CREATE OR REPLACE
PACKAGE BODY UT_util IS

----------------------------------------------------------
--	PRIVATE TYPES
----------------------------------------------------------


----------------------------------------------------------
--	PRIVATE VARIABLES
----------------------------------------------------------

CurrentModule	VARCHAR2(2000);


----------------------------------------------------------
-- LOCAL MODULES
----------------------------------------------------------

PROCEDURE reportSuccess(theTitle IN VARCHAR2, theTest IN VARCHAR2, theExpected IN CLOB, theComputed IN CLOB);
PROCEDURE reportFailure(theTitle IN VARCHAR2, theTest IN VARCHAR2, theExpected IN CLOB, theComputed IN CLOB);
PROCEDURE console(theText IN VARCHAR2 DEFAULT NULL);


----------------------------------------------------------
-- GLOBAL MODULES
----------------------------------------------------------


----------------------------------------------------------
--	module
--
PROCEDURE module(theModule IN VARCHAR2)
IS
BEGIN
	CurrentModule := theModule;
END module;

----------------------------------------------------------
--	eq
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				VARCHAR2,
				theComputed	IN				VARCHAR2,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
BEGIN
	aOK		:= (NVL(theExpected = theComputed, FALSE)) OR (theExpected IS NULL AND theComputed IS NULL AND theNullOK);
	aTest	:= 'EQ(VARCHAR2): expected="' || asString(theExpected) || '" computed="' || asString(theComputed) || '" Null is OK: ' || CASE theNullOK WHEN TRUE THEN 'True' ELSE 'False' END || '.';

	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	END IF;
END eq;

----------------------------------------------------------
--	eq
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				BOOLEAN,
				theComputed	IN				BOOLEAN,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
BEGIN
	aOK		:= (NVL(theExpected = theComputed, FALSE)) OR (theExpected IS NULL AND theComputed IS NULL AND theNullOK);
	aTest	:= 'EQ(BOOLEAN): expected="' || asString(theExpected) || '" computed="' || asString(theComputed) || '" Null is OK: ' || CASE theNullOK WHEN TRUE THEN 'True' ELSE 'False' END || '.';

	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	END IF;
END eq;

----------------------------------------------------------
--	Test for equality of NUMBER
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				NUMBER,
				theComputed	IN				NUMBER,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
BEGIN
	aOK		:= (NVL(theExpected = theComputed, FALSE)) OR (theExpected IS NULL AND theComputed IS NULL AND theNullOK);
	aTest	:= 'EQ(NUMBER): expected="' || asString(theExpected) || '" computed="' || asString(theComputed) || '" Null is OK: ' || CASE theNullOK WHEN TRUE THEN 'True' ELSE 'False' END || '.';

	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	END IF;
END eq;

----------------------------------------------------------
--	Test for equality of DATE
--
PROCEDURE eq(	theTitle	IN				VARCHAR2,
				theExpected	IN				DATE,
				theComputed	IN				DATE,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
BEGIN
	aOK		:= (NVL(theExpected = theComputed, FALSE)) OR (theExpected IS NULL AND theComputed IS NULL AND theNullOK);
	aTest	:= 'EQ(DATE): expected="' || asString(theExpected) || '" computed="' || asString(theComputed) || '" Null is OK: ' || CASE theNullOK WHEN TRUE THEN 'True' ELSE 'False' END || '.';

	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>asString(theExpected), theComputed=>asString(theComputed));
	END IF;
END eq;

----------------------------------------------------------
--	Test for equality of CLOB
--
PROCEDURE eqLOB(theTitle	IN				VARCHAR2,
				theExpected	IN				CLOB,
				theComputed	IN				CLOB,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
	aResult		INTEGER;	
BEGIN
	--	are null allowed and are both lob's null ?
	IF (theNullOK AND theExpected IS NULL AND theComputed IS NULL) THEN
		aOK := TRUE;
		goto done;
	END IF;

	--	have both lob's a length of 0
	IF (dbms_lob.getlength(theExpected) = 0 AND dbms_lob.getlength(theComputed) = 0) THEN
		aOK := TRUE;
		goto done;
	END IF;

	--	compare the content of the lob's
	aResult := dbms_lob.compare(theExpected, theComputed);
	IF (aResult IS NULL) THEN
		RAISE VALUE_ERROR;
	END IF;
	aOK := (aResult = 0);

	--	format the results
	<<done>>

	aTest := 'EQ(CLOB): expected:"' || asStringLOB(theExpected) || '   computed:' || asStringLOB(theComputed) || '    Null is OK: ' || CASE theNullOK WHEN TRUE THEN 'True' ELSE 'False' END || '.';
	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>theExpected, theComputed=>theComputed);
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>theExpected, theComputed=>theComputed);
	END IF;
END eqLOB;

----------------------------------------------------------
--	Test for equality of BLOB
--
PROCEDURE eqLOB(theTitle	IN				VARCHAR2,
				theExpected	IN				BLOB,
				theComputed	IN				BLOB,
				theNullOK	IN				BOOLEAN		DEFAULT	FALSE
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
	aResult		INTEGER;	
BEGIN
	--	are null allowed and are both lob's null ?
	IF (theNullOK AND theExpected IS NULL AND theComputed IS NULL) THEN
		aOK := TRUE;
		goto done;
	END IF;

	--	have both lob's a length of 0
	IF (dbms_lob.getlength(theExpected) = 0 AND dbms_lob.getlength(theComputed) = 0) THEN
		aOK := TRUE;
		goto done;
	END IF;

	--	compare the content of the lob's
	aResult := dbms_lob.compare(theExpected, theComputed);
	IF (aResult IS NULL) THEN
		RAISE VALUE_ERROR;
	END IF;
	aOK := (aResult = 0);

	--	format the results
	<<done>>

	aTest := 'EQ(BLOB): expected:"' || asStringLOB(theExpected) || '   computed:' || asStringLOB(theComputed) || '    Null is OK: ' || CASE theNullOK WHEN TRUE THEN 'True' ELSE 'False' END || '.';
	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>NULL, theComputed=>NULL);
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>NULL, theComputed=>NULL);
	END IF;
END eqLOB;

----------------------------------------------------------
--	ok
--
PROCEDURE ok(	theTitle	IN				VARCHAR2,
				theValue	IN				BOOLEAN
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
BEGIN
	aOK		:= NVL(theValue, FALSE);
	aTest	:= 'OK condition "' || asString(theValue) || '".';

	IF (aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>NULL, theComputed=>NULL);
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>NULL, theComputed=>NULL);
	END IF;
END ok;

----------------------------------------------------------
--	ko
--
PROCEDURE ko(	theTitle	IN				VARCHAR2,
				theValue	IN				BOOLEAN
				)
IS
	aOK			BOOLEAN;
	aTest		CLOB;
BEGIN
	aOK		:= NVL(theValue, FALSE);
	aTest	:= 'OK condition "' || asString(theValue) || '".';

	IF (NOT aOK) THEN
		reportSuccess(theTitle=>theTitle, theTest=>aTest, theExpected=>NULL, theComputed=>NULL);
	ELSE
		reportFailure(theTitle=>theTitle, theTest=>aTest, theExpected=>NULL, theComputed=>NULL);
	END IF;
END ko;

----------------------------------------------------------
--	asString
--
FUNCTION asString(theValue IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
	RETURN NVL(theValue, '<NULL>');
END asString;

----------------------------------------------------------
--	asString
--
FUNCTION asString(theValue IN NUMBER) RETURN VARCHAR2
IS
BEGIN
	IF (theValue IS NOT NULL) THEN
		RETURN TO_CHAR(theValue, 'FM999999999999990D099999999', 'NLS_NUMERIC_CHARACTERS = ''.,''');
	ELSE
		RETURN '<NULL>';
	END IF;
END asString;

----------------------------------------------------------
--	asString
--
FUNCTION asString(theValue IN BOOLEAN) RETURN VARCHAR2
IS
BEGIN
	IF (theValue IS NOT NULL) THEN
		RETURN CASE theValue WHEN TRUE THEN 'TRUE' ELSE 'FALSE' END;
	ELSE
		RETURN '<NULL>';
	END IF;
END asString;

----------------------------------------------------------
--	asString
--
FUNCTION asString(theValue IN DATE) RETURN VARCHAR2
IS
BEGIN
	IF (theValue IS NOT NULL) THEN
		RETURN TO_CHAR(theValue, 'YYYY.MM.DD HH24:MI:SS');
	ELSE
		RETURN '<NULL>';
	END IF;
END asString;

----------------------------------------------------------
--	asStringLOB
--
FUNCTION asStringLOB(theValue IN CLOB) RETURN VARCHAR2
IS
	aSize	INTEGER;
	aAmount	INTEGER;
	aText	VARCHAR2(32767);
BEGIN
	IF (theValue IS NOT NULL) THEN
		aSize := dbms_lob.getlength(theValue);
		aText := 'length=('||aSize||')';
		IF (aSize > 0) THEN
			aAmount := LEAST(aSize, 100);
			aText := aText||' value=('||dbms_lob.substr(theValue, aAmount)||')';
		END IF;
	ELSE
		aText := '<NULL>';
	END IF;
	
	RETURN aText;
END asStringLOB;

----------------------------------------------------------
--	asStringLOB
--
FUNCTION asStringLOB(theValue IN BLOB) RETURN VARCHAR2
IS
	aSize	INTEGER;
	aAmount	INTEGER;
	aRaw	RAW(1000);
	aText	VARCHAR2(32767);
BEGIN
	IF (theValue IS NOT NULL) THEN
		aSize := dbms_lob.getlength(theValue);
		aText := 'length=('||aSize||')';
		IF (aSize > 0) THEN
			aAmount := LEAST(aSize, 100);
			aText := aText||' value=('|| utl_raw.cast_to_varchar2(dbms_lob.substr(theValue, aAmount))||')';
		END IF;
	ELSE
		aText := '<NULL>';
	END IF;
	
	RETURN aText;
END asStringLOB;

----------------------------------------------------------
--	reportSuccess (private)
--
PROCEDURE reportSuccess(theTitle IN VARCHAR2, theTest IN VARCHAR2, theExpected IN CLOB, theComputed IN CLOB)
IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	INSERT INTO UT_test_table (ID, When, Module, Title, Success, Result, Expected, Computed)
		VALUES (UT_test_seq.NEXTVAL, SYSTIMESTAMP, NVL(CurrentModule, '-'), theTitle, 'Y', theTest, theExpected, theComputed);
	COMMIT;
END reportSuccess;

----------------------------------------------------------
--	reportFailure (private)
--
PROCEDURE reportFailure(theTitle IN VARCHAR2, theTest IN VARCHAR2, theExpected IN CLOB, theComputed IN CLOB)
IS
BEGIN
	INSERT INTO UT_test_table (ID, When, Module, Title, Success, Result, Expected, Computed)
		VALUES (UT_test_seq.NEXTVAL, SYSTIMESTAMP, NVL(CurrentModule, '-'), theTitle, 'N', theTest, theExpected, theComputed);
	COMMIT;
END reportFailure;

----------------------------------------------------------
--	console (private)	
--
PROCEDURE console(theText IN VARCHAR2 DEFAULT NULL)
IS
BEGIN
	dbms_output.put_line(theText);
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END console;


END UT_util;
/
