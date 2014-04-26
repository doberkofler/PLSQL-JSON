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
	SELF.num	:=	NULL;
	SELF.dat		:=	NULL;
	SELF.par	:=	NULL;
	SELF.nex	:=	NULL;
	SELF.sub 	:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ		:=	'0';
	SELF.nam		:=	theName;
	SELF.str		:=	NULL;
	SELF.num		:=	NULL;
	SELF.dat		:=	NULL;
	SELF.par		:=	NULL;
	SELF.nex		:=	NULL;
	SELF.sub 		:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN VARCHAR2) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ		:=	'S';
	SELF.nam		:=	theName;
	SELF.str		:=	theValue;
	SELF.num		:=	NULL;
	SELF.dat		:=	NULL;
	SELF.par		:=	NULL;
	SELF.nex		:=	NULL;
	SELF.sub 		:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN NUMBER) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ		:=	CASE WHEN theValue IS NOT NULL THEN 'N' ELSE '0' END;
	SELF.nam		:=	theName;
	SELF.str		:=	NULL;
	SELF.num		:=	theValue;
	SELF.dat		:=	NULL;
	SELF.par		:=	NULL;
	SELF.nex		:=	NULL;
	SELF.sub 		:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN DATE) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ		:=	CASE WHEN theValue IS NOT NULL THEN 'D' ELSE '0' END;
	SELF.nam		:=	theName;
	SELF.str		:=	NULL;
	SELF.num		:=	NULL;
	SELF.dat		:=	theValue;
	SELF.par		:=	NULL;
	SELF.nex		:=	NULL;
	SELF.sub 		:=	NULL;
	RETURN;
END json_node;

----------------------------------------------------------
--	json_node
--
CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN BOOLEAN) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ		:=	CASE WHEN theValue IS NOT NULL THEN 'B' ELSE '0' END;
	SELF.nam		:=	theName;
	SELF.str		:=	NULL;
	IF (theValue IS NOT NULL) THEN
		SELF.num	:=	CASE theValue WHEN TRUE THEN 1 ELSE 0 END;
	ELSE
		SELF.num	:=	NULL;
	END IF;
	SELF.dat		:=	NULL;
	SELF.par		:=	NULL;
	SELF.nex		:=	NULL;
	SELF.sub 		:=	NULL;
	RETURN;
END json_node;


END;
/
