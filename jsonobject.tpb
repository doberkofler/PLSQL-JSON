CREATE OR REPLACE
TYPE BODY jsonObject IS

----------------------------------------------------------
--	jsonObject
--
CONSTRUCTOR FUNCTION jsonObject(SELF IN OUT NOCOPY jsonObject) RETURN SELF AS result
IS
BEGIN
	SELF.nodes	:=	jsonNodes();
	SELF.lastID	:=	NULL;
	RETURN;
END jsonObject;

----------------------------------------------------------
--	jsonObject
--
CONSTRUCTOR FUNCTION jsonObject(SELF IN OUT NOCOPY jsonObject, theData IN jsonValue) RETURN SELF AS result
IS
BEGIN
	IF (theData.typ != json_utils.NODE_TYPE_OBJECT) THEN
		raise_application_error(-20100, 'jsonObject exception: unable to convert node ('||theData.typ||') to an object');
	ELSE
		SELF.nodes	:=	theData.nodes;
		SELF.lastID	:=	NULL;
	END IF;
	RETURN;
END jsonObject;

----------------------------------------------------------
--	jsonObject
--
CONSTRUCTOR FUNCTION jsonObject(SELF IN OUT NOCOPY jsonObject, theJSONString IN CLOB) RETURN SELF AS result
IS
BEGIN
	SELF.nodes	:=	json_parser.parser(theJSONString);
	SELF.lastID	:=	NULL;
	RETURN;
END jsonObject;

----------------------------------------------------------
--	put
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	-- add the node
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theName));
END put;

----------------------------------------------------------
--	put (VARCHAR2)
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN VARCHAR2)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	-- add the node
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theName, theValue));
END put;

----------------------------------------------------------
--	put (CLOB)
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN CLOB)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	-- add the node
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theName, theValue));
END put;

----------------------------------------------------------
--	put (NUMBER)
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN NUMBER)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	-- add the node
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theName, theValue));
END put;

----------------------------------------------------------
--	put (DATE)
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN DATE)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	-- add the node
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theName, theValue));
END put;

----------------------------------------------------------
--	put (BOOLEAN)
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN BOOLEAN)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	-- add the node
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theName, theValue));
END put;

----------------------------------------------------------
--	put
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN jsonObject)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	--	add a new object node that will be used as the root for all the sub notes
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(json_utils.NODE_TYPE_OBJECT, theName, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

	--	copy the sub-nodes
	json_utils.copyNodes(theTargetNodes=>SELF.nodes, theTargetNodeID=>aNodeID, theLastID=>SELF.lastID, theName=>theName, theSourceNodes=>theValue.nodes);
END put;

----------------------------------------------------------
--	put
--
MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN jsonValue)
IS
	aNodeID	BINARY_INTEGER := json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>theName);
BEGIN
	-- remove the existing node if we change an existing property
	IF (aNodeID IS NOT NULL) THEN
		SELF.lastID := json_utils.removeNode(theNodes=>SELF.nodes, theNodeID=>aNodeID);
	END IF;

	--	add a new object node that will be used as the root for all the sub notes
	aNodeID := json_utils.addNode(theNodes=>SELF.nodes, theLastID=>SELF.lastID, theNode=>jsonNode(theValue.typ, theName, NULL, NULL, NULL, NULL, NULL, NULL, NULL));

	--	copy the sub-nodes
	json_utils.copyNodes(theTargetNodes=>SELF.nodes, theTargetNodeID=>aNodeID, theLastID=>SELF.lastID, theName=>theName, theSourceNodes=>theValue.nodes);
END put;

----------------------------------------------------------
--	count
--
MEMBER FUNCTION count(SELF IN jsonObject) RETURN NUMBER
IS
BEGIN
	RETURN json_utils.getNodeCount(theNodes=>SELF.nodes);
END count;

----------------------------------------------------------
--	get
--
MEMBER FUNCTION get(SELF IN jsonObject, thePropertyName IN VARCHAR2) RETURN jsonValue
IS
	aNodeID	BINARY_INTEGER	:=	json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>thePropertyName);
BEGIN
	IF (aNodeID IS NOT NULL) THEN
		RETURN json_utils.createSubTree(theSourceNodes=>SELF.nodes, theSourceNodeID=>aNodeID);
	ELSE
		raise_application_error(-20100, 'jsonObject exception: property ('||thePropertyName||') does not exit');
		RETURN NULL;
	END IF;
END get;

----------------------------------------------------------
--	exist
--
MEMBER FUNCTION exist(SELF IN jsonObject, thePropertyName IN VARCHAR2) RETURN BOOLEAN
IS
BEGIN
	RETURN (json_utils.getNodeIDByName(theNodes=>SELF.nodes, thePropertyName=>thePropertyName) IS NOT NULL);
END exist;

----------------------------------------------------------
--	get_keys
--
MEMBER FUNCTION get_keys RETURN jsonKeys
IS
	keys	jsonKeys	:=	jsonKeys();
	i		BINARY_INTEGER	:=	SELF.nodes.FIRST;
BEGIN
	WHILE (i IS NOT NULL) LOOP
		keys.EXTEND(1);
		keys(keys.LAST) := SELF.nodes(i).nam;
		i := SELF.nodes(i).nex;
	END LOOP;

	RETURN keys;
END get_keys;

----------------------------------------------------------
--	to_jsonValue
--
MEMBER FUNCTION to_jsonValue(SELF IN jsonObject) RETURN jsonValue
IS
BEGIN
	RETURN jsonValue(json_utils.NODE_TYPE_OBJECT, SELF.nodes);
END to_jsonValue;

----------------------------------------------------------
--	to_clob
--
MEMBER PROCEDURE to_clob(SELF IN jsonObject, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE)
IS
	aStrBuf	VARCHAR2(32767);
BEGIN
	IF (theEraseLob) THEN
		json_utils.erase_clob(theLobBuf);
	END IF;
	json_utils.object_to_clob(theLobBuf=>theLobBuf, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST);
END to_clob;

----------------------------------------------------------
--	to_text
--
MEMBER FUNCTION to_text(SELF IN jsonObject) RETURN VARCHAR2
IS
	aStrBuf	VARCHAR2(32767);
	aLobLoc	CLOB;
BEGIN
	dbms_lob.createtemporary(lob_loc=>aLobLoc, cache=>TRUE, dur=>dbms_lob.session);
	json_utils.object_to_clob(theLobBuf=>aLobLoc, theStrBuf=>aStrBuf, theNodes=>SELF.nodes, theNodeID=>SELF.nodes.FIRST);
	aStrBuf := dbms_lob.substr(aLobLoc, 32767, 1);
	dbms_lob.freetemporary(lob_loc=>aLobLoc);

	RETURN aStrBuf;
END to_text;

----------------------------------------------------------
--	htp
--
MEMBER PROCEDURE htp(SELF IN jsonObject, theJSONP IN VARCHAR2 DEFAULT NULL)
IS
	aLob	CLOB	:=	empty_clob();
BEGIN
	dbms_lob.createtemporary(aLob, TRUE);
	SELF.to_clob(aLob);
	json_utils.htp_output_clob(aLob, theJSONP);
	dbms_lob.freetemporary(aLob);
END htp;

END;
/
