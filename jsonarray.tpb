CREATE OR REPLACE
TYPE BODY jsonArray IS

----------------------------------------------------------
--	jsonArray
--
CONSTRUCTOR FUNCTION jsonArray(SELF IN OUT NOCOPY jsonArray) RETURN SELF AS result
IS
BEGIN
	nodes	:=	jsonNodes();
	lastID	:=	NULL;
	RETURN;
END jsonArray;

----------------------------------------------------------
--	jsonArray
--
CONSTRUCTOR FUNCTION jsonArray(SELF IN OUT NOCOPY jsonArray, theData IN jsonValue) RETURN SELF AS result
IS
BEGIN
	IF (theData.typ != json_utils.NODE_TYPE_ARRAY) THEN
		raise_application_error(-20100, 'jsonArray exception: unable to convert node ('||theData.typ||') to an array');
	ELSE
		SELF.nodes	:=	theData.nodes;
		SELF.lastID	:=	NULL;
	END IF;
	RETURN;
END jsonArray;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(NULL));
END append;

----------------------------------------------------------
--	append (VARCHAR2)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN VARCHAR2)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(NULL, theValue));
END append;

----------------------------------------------------------
--	append (CLOB)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN CLOB)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(NULL, theValue));
END append;

----------------------------------------------------------
--	append (NUMBER)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN NUMBER)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(NULL, theValue));
END append;

----------------------------------------------------------
--	append (DATE)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN DATE)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(NULL, theValue));
END append;

----------------------------------------------------------
--	append (BOOLEAN)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN BOOLEAN)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(NULL, theValue));
END append;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN jsonObject)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	--	add a new object node that will be used as the root for all the sub notes
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(json_utils.NODE_TYPE_OBJECT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

	--	copy the sub-nodes
	json_utils.copyNodes(theTargetNodes=>SELF.nodes, theTargetNodeID=>aNodeID, theLastID=>SELF.lastID, theName=>NULL, theSourceNodes=>theValue.nodes);
END append;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY jsonArray, theValue IN jsonArray)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	--	add a new array node that will be used as the root for all the sub notes
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(json_utils.NODE_TYPE_ARRAY, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

	--	copy the sub-nodes
	json_utils.copyNodes(theTargetNodes=>SELF.nodes, theTargetNodeID=>aNodeID, theLastID=>SELF.lastID, theName=>NULL, theSourceNodes=>theValue.nodes);
END append;

----------------------------------------------------------
--	count
--
MEMBER FUNCTION count(SELF IN jsonArray) RETURN NUMBER
IS
BEGIN
	RETURN json_utils.getNodeCount(SELF.nodes);
END count;

----------------------------------------------------------
--	get
--
MEMBER FUNCTION get(SELF IN jsonArray, thePropertyIndex IN NUMBER) RETURN jsonValue
IS
	aNodeID	BINARY_INTEGER	:=	json_utils.getNodeIDByIndex(theNodes=>SELF.nodes, thePropertyIndex=>thePropertyIndex);
BEGIN
	IF (aNodeID IS NOT NULL) THEN
		RETURN json_utils.createSubTree(theSourceNodes=>SELF.nodes, theSourceNodeID=>aNodeID);
	ELSE
		raise_application_error(-20100, 'jsonObject exception: property ('||thePropertyIndex||') does not exit');
		RETURN NULL;
	END IF;
END get;

----------------------------------------------------------
--	exist
--
MEMBER FUNCTION exist(SELF IN jsonArray, thePropertyIndex IN NUMBER) RETURN BOOLEAN
IS
BEGIN
	RETURN (json_utils.getNodeIDByIndex(theNodes=>SELF.nodes, thePropertyIndex=>thePropertyIndex) IS NOT NULL);
END exist;

----------------------------------------------------------
--	to_clob_value
--
MEMBER FUNCTION to_jsonValue(self IN jsonArray) RETURN jsonValue
IS
BEGIN
	RETURN jsonValue(json_utils.NODE_TYPE_ARRAY, SELF.nodes);
END to_jsonValue;

----------------------------------------------------------
--	to_clob
--
MEMBER PROCEDURE to_clob(SELF IN jsonArray, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE)
IS
	aIndentation    INTEGER			:= 0;
	aStrBuf			VARCHAR2(32767);
BEGIN
	IF (theEraseLob) THEN
		json_utils.erase_clob(theLobBuf);
	END IF;
	json_utils.array_to_clob(theLobBuf=>theLobBuf, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST, theIndentation=>aIndentation);
END to_clob;

----------------------------------------------------------
--	to_text
--
MEMBER FUNCTION to_text(SELF IN jsonArray) RETURN VARCHAR2
IS
	aIndentation    INTEGER			:= 0;
	aStrBuf			VARCHAR2(32767);
	aLobLoc			CLOB;
BEGIN
	dbms_lob.createtemporary(lob_loc=>aLobLoc, cache=>TRUE, dur=>dbms_lob.session);
	json_utils.array_to_clob(theLobBuf=>aLobLoc, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST, theIndentation=>aIndentation);
	aStrBuf := dbms_lob.substr(aLobLoc, 32767, 1);
	dbms_lob.freetemporary(lob_loc=>aLobLoc);

	RETURN aStrBuf;
END to_text;

----------------------------------------------------------
--	htp
--
MEMBER PROCEDURE htp(SELF IN jsonArray, theJSONP IN VARCHAR2 DEFAULT NULL)
IS
	aLob	CLOB	:=	empty_clob();
BEGIN
	dbms_lob.createtemporary(aLob, TRUE);
	self.to_clob(aLob);
	json_utils.htp_output_clob(aLob, theJSONP);
	dbms_lob.freetemporary(aLob);
END htp;

END;
/
