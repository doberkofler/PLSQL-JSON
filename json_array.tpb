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
	IF (theData.typ != 'A') THEN
		raise_application_error(-20100, 'json_array exception: unable to convert node ('||theData.typ||') to an array');
	ELSE
		SELF.nodes	:=	theData.nodes;
		SELF.lastID	:=	NULL;
	END IF;
	RETURN;
END json_array;
----------------------------------------------------------
--	json_array
--
CONSTRUCTOR FUNCTION json_array(SELF IN OUT NOCOPY json_array, theJSONString IN CLOB) RETURN SELF AS result
IS
BEGIN
	SELF.nodes	:=	json_parser.parser(theJSONString, '[');
	SELF.lastID	:=	NULL;
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
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN VARCHAR2)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN NUMBER)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append
--
MEMBER PROCEDURE append(SELF IN OUT NOCOPY json_array, theValue IN DATE)
IS
	aNodeID	BINARY_INTEGER;
BEGIN
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node(NULL, theValue));
END append;

----------------------------------------------------------
--	append
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
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node('O', NULL, NULL, NULL, NULL, NULL, NULL, NULL));

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
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>json_node('A', NULL, NULL, NULL, NULL, NULL, NULL, NULL));

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
	RETURN json_value('A', SELF.nodes);
END to_json_value;

----------------------------------------------------------
--	to_clob
--
MEMBER PROCEDURE to_clob(SELF IN json_array, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE)
IS
	aStrBuf	VARCHAR2(32767);
BEGIN
	IF (theEraseLob) THEN
		json_utils.erase_clob(theLobBuf);
	END IF;
	json_utils.array_to_clob(theLobBuf=>theLobBuf, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST);
END to_clob;

----------------------------------------------------------
--	htp
--
MEMBER FUNCTION to_string (SELF IN json_array) RETURN VARCHAR2
IS
	aLob	CLOB	:=	empty_clob();
	theString VARCHAR2(32767) := '';
	theLength  BINARY_INTEGER;
    e_too_small EXCEPTION; -- ORA-06502: PL/SQL: numeric or value error
    PRAGMA EXCEPTION_INIT( e_too_small, -06502);
BEGIN
	dbms_lob.createtemporary(aLob, TRUE);
	self.to_clob(aLob);
	theLength := dbms_lob.getlength(aLob);
	IF theLength <= 32767 THEN
		theString := dbms_lob.substr(aLob, 32767, 1); 
	END IF;
	dbms_lob.freetemporary(aLob);
	IF theLength > 32767 THEN
		RAISE e_too_small;
	END IF;
	RETURN theString;
END to_string;

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
