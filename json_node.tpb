CREATE OR REPLACE
TYPE BODY json_node
IS

----------------------------------------------------------
--	json_node
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	NULL;
	SELF.nam	:=	NULL;
	SELF.str	:=	NULL;
	SELF.lob	:=	NULL;
	SELF.num	:=	NULL;
	SELF.dat	:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node (NULL)
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	json_const.NODE_TYPE_NULL;
	SELF.nam	:=	theName;
	SELF.str	:=	NULL;
	SELF.lob	:=	NULL;
	SELF.num	:=	NULL;
	SELF.dat	:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node (VARCHAR2)
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN VARCHAR2) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	json_const.NODE_TYPE_STRING;
	SELF.nam	:=	theName;
	SELF.str	:=	theValue;
	SELF.lob	:=	NULL;
	SELF.num	:=	NULL;
	SELF.dat	:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node (CLOB)
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN CLOB) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	json_const.NODE_TYPE_LOB;
	SELF.nam	:=	theName;
	SELF.str	:=	NULL;
	SELF.lob	:=	empty_clob();
	SELF.num	:=	NULL;
	SELF.dat	:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	
	dbms_lob.createtemporary(lob_loc=>SELF.lob, cache=>TRUE, dur=>dbms_lob.session);
	IF (dbms_lob.getlength(lob_loc=>theValue) > 0) THEN
		dbms_lob.append(dest_lob=>SELF.lob, src_lob=>theValue);
	END IF;
	
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node (NUMBER)
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN NUMBER) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	CASE WHEN theValue IS NOT NULL THEN json_const.NODE_TYPE_NUMBER ELSE json_const.NODE_TYPE_NULL END;
	SELF.nam	:=	theName;
	SELF.str	:=	NULL;
	SELF.lob	:=	NULL;
	SELF.num	:=	theValue;
	SELF.dat	:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node (DATE)
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN DATE) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	CASE WHEN theValue IS NOT NULL THEN json_const.NODE_TYPE_DATE ELSE json_const.NODE_TYPE_NULL END;
	SELF.nam	:=	theName;
	SELF.str	:=	NULL;
	SELF.lob	:=	NULL;
	SELF.num	:=	NULL;
	SELF.dat	:=	theValue;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node (BOOLEAN)
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN BOOLEAN) RETURN SELF AS RESULT
IS
	aNumber	NUMBER;
BEGIN
	IF (theValue IS NOT NULL) THEN
		aNumber	:=	CASE theValue WHEN TRUE THEN 1 ELSE 0 END;
	END IF;

	SELF.typ	:=	CASE WHEN theValue IS NOT NULL THEN json_const.NODE_TYPE_BOOLEAN ELSE json_const.NODE_TYPE_NULL END;
	SELF.nam	:=	theName;
	SELF.str	:=	NULL;
	SELF.lob	:=	NULL;
	SELF.num	:=	aNumber;
	SELF.dat	:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

END;
/
