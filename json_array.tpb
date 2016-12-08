CREATE OR REPLACE
TYPE BODY json_array IS

----------------------------------------------------------
--	json_array
--
CONSTRUCTOR FUNCTION json_array(SELF IN OUT NOCOPY json_array) RETURN SELF AS result
IS
BEGIN
	nodes	:=	json_nodes();
	lastID	:=	NULL;
	RETURN;
END json_array;

----------------------------------------------------------
--	json_array
--
CONSTRUCTOR FUNCTION json_array(SELF IN OUT NOCOPY json_array, theData IN json_value) RETURN SELF AS result
IS
BEGIN
	IF (theData.typ != json_const.NODE_TYPE_ARRAY) THEN
		raise_application_error(-20100, 'json_array exception: unable to convert node ('||theData.typ||') to an array');
	ELSE
		SELF.nodes	:=	theData.nodes;
		SELF.lastID	:=	NULL;
	END IF;
	RETURN;
END json_array;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL));
END append;

----------------------------------------------------------
--	append (VARCHAR2)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN VARCHAR2)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append (CLOB)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN CLOB)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append (NUMBER)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN NUMBER)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append (DATE)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN DATE)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append (BOOLEAN)
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN BOOLEAN)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN json_object)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	--	add a new object node that will be used as the root for all the sub notes
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(json_const.NODE_TYPE_OBJECT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

	--	copy the sub-nodes
	json_utils.copyNodes(theTargetNodes=>SELF.nodes, theTargetNodeID=>aNodeID, theLastID=>SELF.lastID, theName=>NULL, theSourceNodes=>theValue.nodes);
END append;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN json_array)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	--	add a new array node that will be used as the root for all the sub notes
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(json_const.NODE_TYPE_ARRAY, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

	--	copy the sub-nodes
	json_utils.copyNodes(theTargetNodes=>SELF.nodes, theTargetNodeID=>aNodeID, theLastID=>SELF.lastID, theName=>NULL, theSourceNodes=>theValue.nodes);
END append;

----------------------------------------------------------
--	count
--
MEMBER FUNCTION count(SELF IN json_array) RETURN NUMBER
IS
BEGIN
	RETURN json_utils.getNodeCount(SELF.nodes);
END count;

----------------------------------------------------------
--	get
--
MEMBER FUNCTION get(SELF IN json_array, thePropertyIndex IN NUMBER) RETURN json_value
IS
	aNodeID	BINARY_INTEGER	:=	json_utils.getNodeIDByIndex(theNodes=>SELF.nodes, thePropertyIndex=>thePropertyIndex);
BEGIN
	IF (aNodeID IS NOT NULL) THEN
		RETURN json_utils.createSubTree(theSourceNodes=>SELF.nodes, theSourceNodeID=>aNodeID);
	ELSE
		raise_application_error(-20100, 'json_object exception: property ('||thePropertyIndex||') does not exit');
		RETURN NULL;
	END IF;
END get;

----------------------------------------------------------
--	exist
--
MEMBER FUNCTION exist(SELF IN json_array, thePropertyIndex IN NUMBER) RETURN BOOLEAN
IS
BEGIN
	RETURN (json_utils.getNodeIDByIndex(theNodes=>SELF.nodes, thePropertyIndex=>thePropertyIndex) IS NOT NULL);
END exist;

----------------------------------------------------------
--	to_clob_value
--
MEMBER FUNCTION to_json_value(self IN json_array) RETURN json_value
IS
BEGIN
	RETURN json_value(json_const.NODE_TYPE_ARRAY, SELF.nodes);
END to_json_value;

----------------------------------------------------------
--	to_clob
--
MEMBER PROCEDURE to_clob(SELF IN json_array, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE)
IS
	aStrBuf	VARCHAR2(32767);
BEGIN
	IF (theEraseLob) THEN
		json_clob.erase(theLobBuf);
	END IF;
	json_utils.array_to_clob(theLobBuf=>theLobBuf, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST);
END to_clob;

----------------------------------------------------------
--	to_text
--
MEMBER FUNCTION to_text(SELF IN json_array) RETURN VARCHAR2
IS
	aStrBuf	VARCHAR2(32767);
	aLobLoc	CLOB;
BEGIN
	dbms_lob.createtemporary(lob_loc=>aLobLoc, cache=>TRUE, dur=>dbms_lob.session);
	json_utils.array_to_clob(theLobBuf=>aLobLoc, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST);
	aStrBuf := dbms_lob.substr(aLobLoc, 32767, 1);
	dbms_lob.freetemporary(lob_loc=>aLobLoc);

	RETURN aStrBuf;
END to_text;

----------------------------------------------------------
--	htp
--
MEMBER PROCEDURE htp(SELF IN json_array, theJSONP IN VARCHAR2 DEFAULT NULL)
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
