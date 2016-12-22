CREATE OR REPLACE
PACKAGE BODY json_utils
IS

PROCEDURE copySubNodes(theTarget IN OUT NOCOPY json_nodes, theFirstID IN OUT NOCOPY BINARY_INTEGER, theParentID IN BINARY_INTEGER, theSource IN json_nodes, theFirstSourceID IN BINARY_INTEGER);
PROCEDURE removeSubNodes(theNodes IN OUT NOCOPY json_nodes, theNodeID IN BINARY_INTEGER);
FUNCTION number_to_json(theNumber IN NUMBER) RETURN VARCHAR2;
FUNCTION boolean_to_json(theBoolean IN NUMBER) RETURN VARCHAR2;
FUNCTION escape(theString IN VARCHAR2, theAsciiOutput IN BOOLEAN DEFAULT TRUE, theEscapeSolitus IN BOOLEAN DEFAULT FALSE) RETURN VARCHAR2;
PROCEDURE escapeLOB(theInputLob IN CLOB, theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theAsciiOutput IN BOOLEAN DEFAULT TRUE, theEscapeSolitus IN BOOLEAN DEFAULT FALSE);

----------------------------------------------------------
--	get the number of nodes
--
FUNCTION getNodeCount(theNodes IN json_nodes) RETURN BINARY_INTEGER
IS
	i	BINARY_INTEGER	:=	theNodes.FIRST;
	c	BINARY_INTEGER	:=	0;
BEGIN
	WHILE (i IS NOT NULL) LOOP
		c := c + 1;
		i := theNodes(i).nex;
	END LOOP;

	RETURN c;
END getNodeCount;

----------------------------------------------------------
--	getNodeIDByName
--
FUNCTION getNodeIDByName(theNodes IN json_nodes, thePropertyName IN VARCHAR2) RETURN BINARY_INTEGER
IS
	i	BINARY_INTEGER	:=	theNodes.FIRST;
BEGIN
	WHILE (i IS NOT NULL) LOOP
		IF (theNodes(i).nam = thePropertyName) THEN
			RETURN i;
		END IF;
		i := theNodes(i).nex;
	END LOOP;

	RETURN NULL;
END getNodeIDByName;

----------------------------------------------------------
--	getNodeIDByIndex
--
FUNCTION getNodeIDByIndex(theNodes IN json_nodes, thePropertyIndex IN NUMBER) RETURN BINARY_INTEGER
IS
	i	BINARY_INTEGER	:=	theNodes.FIRST;
	c	BINARY_INTEGER	:=	0;
BEGIN
	WHILE (i IS NOT NULL) LOOP
		c := c + 1;
		IF (c = thePropertyIndex) THEN
			RETURN i;
		END IF;
		i := theNodes(i).nex;
	END LOOP;

	RETURN NULL;
END getNodeIDByIndex;

----------------------------------------------------------
--	validate
--
PROCEDURE validate(theNodes IN OUT NOCOPY json_nodes)
IS
	n	json_node;
	i	BINARY_INTEGER;

	FUNCTION equal(theFirstID IN NUMBER, theSecondID IN NUMBER) RETURN BOOLEAN
	IS
	BEGIN
		IF (theFirstID IS NULL AND theSecondID IS NULL) THEN
			RETURN TRUE;
		ELSE
			RETURN (theFirstID = theSecondID);
		END IF;
	END equal;

	PROCEDURE error(theNodeID IN NUMBER, text VARCHAR2)
	IS
	BEGIN
		raise_application_error(-20100, 'JSON Validator exception @ node: '||theNodeID||' - '||text, TRUE);
	END error;
BEGIN
	i := theNodes.FIRST;
	WHILE (i IS NOT NULL) LOOP
		n := theNodes(i);

		--	node references must (at least) exist
		IF (n.nex IS NOT NULL AND NOT theNodes.EXISTS(n.nex)) THEN
			error(i, 'Next node ('||n.nex||') does not exist');
		END IF;
		IF (n.par IS NOT NULL AND NOT theNodes.EXISTS(n.par)) THEN
			error(i, 'Parent node ('||n.par||') does not exist');
		END IF;
		IF (n.sub IS NOT NULL AND NOT theNodes.EXISTS(n.sub)) THEN
			error(i, 'Sub node ('||n.sub||') does not exist');
		END IF;

		--	validations if we have a next node
		IF (n.nex IS NOT NULL) THEN
			IF (NOT equal(n.par, theNodes(n.nex).par)) THEN
				error(i, 'A node and its next node must have the same (or no) parent');
			END IF;
		END IF;

		--	nodes with sub nodes
		IF (n.sub IS NOT NULL AND theNodes(n.sub).par != i) THEN
			error(i, 'Sub node ('||n.sub||') does not have a correct reference to the parent ('||theNodes(n.sub).par||')');
		END IF;

		--	nodes with a parent...
		IF (n.par IS NOT NULL) THEN
			--	must have a parent that points to a sub node with the same parent as we have
			IF (theNodes(n.par).sub IS NULL OR theNodes(theNodes(n.par).sub).par != n.par) THEN
				error(i, 'Sub node ('||theNodes(n.par).sub||') of our parent node ('||n.par||') does not have a correct reference ('||theNodes(theNodes(n.par).sub).par||') to our parent ('||n.par||')');
			END IF;
		END IF;

		--	sub nodes of an object node
		IF (n.par IS NOT NULL AND theNodes(n.par).typ = json_const.NODE_TYPE_OBJECT AND n.nam IS NULL) THEN
			error(i, 'Sub nodes of an object node must have a property name');
		END IF;

		--	sub nodes of an array node
		IF (n.par IS NOT NULL AND theNodes(n.par).typ = json_const.NODE_TYPE_ARRAY AND n.nam IS NOT NULL) THEN
			error(i, 'Sub nodes of an array node are not allowed to have a property name');
		END IF;

		--	type dependent validations
		CASE n.typ

		WHEN json_const.NODE_TYPE_NULL THEN	--	null
			IF (n.str IS NOT NULL OR n.num IS NOT NULL OR n.dat IS NOT NULL) THEN
				error(i, 'String or number value not NULL in a null node');
			END IF;

		WHEN json_const.NODE_TYPE_STRING THEN	--	string
			IF (n.lob IS NOT NULL) THEN
				error(i, 'LOB value not NULL in a string node');
			END IF;
			IF (n.num IS NOT NULL) THEN
				error(i, 'Number value not NULL in a string node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a string node');
			END IF;

		WHEN json_const.NODE_TYPE_LOB THEN		--	lob
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a string node');
			END IF;
			IF (n.num IS NOT NULL) THEN
				error(i, 'Number value not NULL in a string node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a string node');
			END IF;

		WHEN json_const.NODE_TYPE_NUMBER THEN	--	number
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a number node');
			END IF;
			IF (n.num IS NULL) THEN
				error(i, 'Number value is NULL in a number node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a number node');
			END IF;

		WHEN json_const.NODE_TYPE_DATE THEN	--	date
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a date node');
			END IF;
			IF (n.num IS NOT NULL) THEN
				error(i, 'Number value is not NULL in a date node');
			END IF;
			IF (n.dat IS NULL) THEN
				error(i, 'Date value is NULL in a date node');
			END IF;

		WHEN json_const.NODE_TYPE_BOOLEAN THEN	--	boolean
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a boolean node');
			END IF;
			IF (n.num IS NULL OR n.num NOT IN (0, 1)) THEN
				error(i, 'Number values not 0 or 1 in a boolean node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a number node');
			END IF;

		WHEN json_const.NODE_TYPE_OBJECT THEN	--	object
			/*
			an object node without subnotes defines an empty object

			IF (n.sub IS NULL OR NOT theNodes.EXISTS(n.sub)) THEN
				error(i, 'Object node with invalid "sub"');
			END IF;
			*/
			NULL;

		WHEN json_const.NODE_TYPE_ARRAY THEN	--	array
			/*
			an array node without subnotes defines an empty array

			IF (n.sub IS NULL OR NOT theNodes.EXISTS(n.sub)) THEN
				error(i, 'Object node with invalid "sub"');
			END IF;
			*/
			NULL;

		ELSE
			error(i, 'Invalid node type ('||n.typ||')');

		END CASE;

		--	go to next node
		i := theNodes.NEXT(i);
	END LOOP;
END validate;

----------------------------------------------------------
--	addNode
--
FUNCTION addNode(theNodes IN OUT NOCOPY json_nodes, theNode IN json_node) RETURN BINARY_INTEGER
IS
	aCurrID	BINARY_INTEGER;
BEGIN
	--	add a new node
	theNodes.EXTEND(1);
	aCurrID := theNodes.LAST;
	theNodes(aCurrID) := theNode;

	RETURN aCurrID;
END addNode;

----------------------------------------------------------
--	addNode
--
FUNCTION addNode(theNodes IN OUT NOCOPY json_nodes, theLastID IN OUT NOCOPY NUMBER, theNode IN json_node) RETURN BINARY_INTEGER
IS
	aCurrID	BINARY_INTEGER;
BEGIN
	--	add a new node
	theNodes.EXTEND(1);
	aCurrID := theNodes.LAST;
	theNodes(aCurrID) := theNode;

	--	if we are a "main" node (a node that is actually a parameter in THIS object)
	IF (theNode.par IS NULL) THEN
		--	if we are not the first node, we must set the next argument in the currently last node
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aCurrID;
		END IF;

		--	set the last node
		theLastID := aCurrID;
	END IF;

	RETURN aCurrID;
END addNode;

----------------------------------------------------------
--	copyNodes
--
PROCEDURE copyNodes(theTargetNodes IN OUT NOCOPY json_nodes, theTargetNodeID IN BINARY_INTEGER, theLastID IN OUT NOCOPY NUMBER, theName IN VARCHAR2, theSourceNodes IN json_nodes)
IS
	aLastID	BINARY_INTEGER	:=	theTargetNodes.LAST;
	aCurrID	BINARY_INTEGER	:=	NULL;
	aNode	json_node		:=	json_node();
	aFirst	BOOLEAN			:=	TRUE;
	i		BINARY_INTEGER;
BEGIN
	i := theSourceNodes.FIRST;
	WHILE (i IS NOT NULL) LOOP
		--	get the node from source
		aNode := theSourceNodes(i);

		--	set the new id's relative to the current list of nodes
		aNode.sub := aNode.sub + aLastID;
		aNode.nex := aNode.nex + aLastID;

		--	set the parent node id
		IF (aNode.par IS NULL) THEN
			aNode.par := theTargetNodeID;
		ELSE
			aNode.par := aNode.par + aLastID;
		END IF;

		--	add the node
		aCurrID := json_utils.addNode(theNodes=>theTargetNodes, theLastID=>theLastID, theNode=>aNode);

		--	if this is the first sub-node, we must set the index to the sub notes in the parent
		IF (aFirst) THEN
			theTargetNodes(theTargetNodeID).sub := aCurrID;
			aFirst := FALSE;
		END IF;

		--	get the index to the next node
		i := theSourceNodes.NEXT(i);
	END LOOP;
END copyNodes;

----------------------------------------------------------
--	createSubTree
--
FUNCTION createSubTree(theSourceNodes IN json_nodes, theSourceNodeID IN BINARY_INTEGER) RETURN json_value
IS
	aData		json_value		:=	json_value();
	aFirstID	BINARY_INTEGER;
BEGIN
	--	if we must only copy a basic node
	IF (theSourceNodes(theSourceNodeID).typ NOT IN (json_const.NODE_TYPE_OBJECT, json_const.NODE_TYPE_ARRAY)) THEN
		aData.nodes.EXTEND(1);
		aData.typ			:= NULL;
		aData.nodes(1)		:= theSourceNodes(theSourceNodeID);
		aData.nodes(1).par	:= NULL;
		aData.nodes(1).sub	:= NULL;
		aData.nodes(1).nex	:= NULL;
		RETURN aData;
	END IF;

	--dbms_output.put_line('json_util.createSubTree for object or array. starting with node: '||theSourceNodes(theSourceNodeID).sub);

	--	we must extract a subtree of nodes and create a new tree starting with the first node in the sub tree
	aData.typ := theSourceNodes(theSourceNodeID).typ;
	copySubNodes(theTarget=>aData.nodes, theFirstID=>aFirstID, theParentID=>NULL, theSource=>theSourceNodes, theFirstSourceID=>theSourceNodes(theSourceNodeID).sub);

	RETURN aData;
END createSubTree;

----------------------------------------------------------
--	removeNode
--
FUNCTION removeNode(theNodes IN OUT NOCOPY json_nodes, theNodeID IN BINARY_INTEGER) RETURN BINARY_INTEGER
IS
	aNodes			CONSTANT	json_nodes		:= theNodes;
	aNode						json_node;
	aOldNodeCount				BINARY_INTEGER;
	aNewNodeCount				BINARY_INTEGER;
	aFound						BOOLEAN			:= FALSE;
	aCurrID						BINARY_INTEGER;
	aFirstID					BINARY_INTEGER;
	aLastID						BINARY_INTEGER;
	aSourceNodeID				BINARY_INTEGER;
BEGIN
	--
	--	It is only possible to remove a node by basically creating a completely new tree and this is done by first copying
	--	the original tree and then trsversing the copy and create a new tree without the remove node and all it's possible
	--	sub-trees.
	--

	--json_debug.output(theNodes=>theNodes, theRawFlag=>TRUE, theTitle=>'before removeNode');

	-- make sure that we have the node to remove on the root level and save the number of nodes in the root level
	aSourceNodeID := theNodes.FIRST;
	aOldNodeCount := 0;
	WHILE (aSourceNodeID IS NOT NULL) LOOP
		aOldNodeCount := aOldNodeCount + 1;
		IF (aSourceNodeID = theNodeID) THEN
			aFound := TRUE;
		END IF;
		aSourceNodeID := theNodes(aSourceNodeID).nex;
	END LOOP;
	IF (NOT aFound) THEN
		raise_application_error(-20100, 'Cannot find node: '||theNodeID, TRUE);
	END IF;

	-- delete all original nodes
	IF (aNodes.COUNT != theNodes.COUNT) THEN
		raise_application_error(-20100, 'Not all node have been copied', TRUE);
	END IF;
	theNodes.DELETE;
	IF (theNodes.COUNT != 0) THEN
		raise_application_error(-20100, 'Not all nodes have been removed', TRUE);
	END IF;

	-- process the nodes on the root level (the ones that have no parent and use the next link)
	aSourceNodeID := aNodes.FIRST;
	WHILE (aSourceNodeID IS NOT NULL) LOOP
		-- get the source node
		aNode := aNodes(aSourceNodeID);

		-- reset the nex "attribute" because it might get removed
		aNode.nex := NULL;

		-- make sure that all nodes on the root level of an object or array have no parent
		IF (aNode.par IS NOT NULL) THEN
			raise_application_error(-20100, 'Invalid par attribute in node: '||aSourceNodeID, TRUE);
		END IF;

		-- this node needs to be copied
		IF (aSourceNodeID != theNodeID) THEN
			-- add the node
			aCurrID := addNode(theNodes=>theNodes, theLastID=>aLastID, theNode=>aNode);

			-- if there are any sub-notes, we must copy them recursively
			IF (aNode.typ IN (json_const.NODE_TYPE_OBJECT, json_const.NODE_TYPE_ARRAY)) THEN
				IF (aNode.sub IS NULL) THEN
					raise_application_error(-20100, 'Invalid sub attribute in node: '||aSourceNodeID, TRUE);
				END IF;

				-- copy the sub notes
				aFirstID := NULL;
				copySubNodes(theTarget=>theNodes, theFirstID=>aFirstID, theParentID=>aCurrID, theSource=>aNodes, theFirstSourceID=>aNode.sub);

				-- set the new sub id in the node
				theNodes(aCurrID).sub := aFirstID;
			END IF;
		END IF;

		aSourceNodeID := aNodes(aSourceNodeID).nex;
	END LOOP;

	-- make sure that we have removed exactly one node in the root level
	aSourceNodeID := theNodes.FIRST;
	aNewNodeCount := 0;
	WHILE (aSourceNodeID IS NOT NULL) LOOP
		aNewNodeCount := aNewNodeCount + 1;
		aSourceNodeID := theNodes(aSourceNodeID).nex;
	END LOOP;
	IF (aNewNodeCount != aOldNodeCount - 1) THEN
		raise_application_error(-20100, 'Invalid number of nodes after removing one. before: '||aOldNodeCount||' after: '||aNewNodeCount, TRUE);
	END IF;

	--json_debug.output(theNodes=>theNodes, theRawFlag=>TRUE, theTitle=>'after removeNode');

	RETURN aLastID;
END removeNode;

----------------------------------------------------------
--	value_to_clob
--
PROCEDURE value_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER)
IS
	aNode	json_node			:=	theNodes(theNodeID);

	aName	VARCHAR2(32767);
	aCLOB	CLOB;
BEGIN
	--	Add the property name
	IF (aNode.nam IS NOT NULL) THEN
		PRAGMA INLINE (escape, 'YES');
		aName := '"' || escape(aNode.nam) || '":';

		PRAGMA INLINE (add_string, 'YES');
		json_clob.add_string(theLobBuf, theStrBuf, aName);
	END IF;

	--	Add the property value
	CASE aNode.typ

	WHEN json_const.NODE_TYPE_NULL THEN
		PRAGMA INLINE (add_string, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>'null');

	WHEN json_const.NODE_TYPE_STRING THEN
		PRAGMA INLINE (escape, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>'"' || escape(aNode.str) || '"');

	WHEN json_const.NODE_TYPE_LOB THEN
		PRAGMA INLINE (add_string, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>'"');
		PRAGMA INLINE (escapeLOB, 'YES');
		escapeLOB(theInputLob=>aNode.lob, theLobBuf=>theLobBuf, theStrBuf=>theStrBuf);
		PRAGMA INLINE (add_string, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>'"');

	WHEN json_const.NODE_TYPE_NUMBER THEN
		PRAGMA INLINE (number_to_json, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>number_to_json(aNode.num));

	WHEN json_const.NODE_TYPE_DATE THEN
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>'"' || TO_CHAR(aNode.dat, 'FXYYYY-MM-DD"T"HH24:MI:SS') || '"');

	WHEN json_const.NODE_TYPE_BOOLEAN THEN
		PRAGMA INLINE (boolean_to_json, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>boolean_to_json(aNode.num));

	WHEN json_const.NODE_TYPE_OBJECT THEN
		json_utils.object_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>theNodes(theNodeID).sub, theFlushToLOB=>FALSE);

	WHEN json_const.NODE_TYPE_ARRAY THEN
		json_utils.array_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>theNodes(theNodeID).sub, theFlushToLOB=>FALSE);

	ELSE
		raise_application_error(-20100, 'Invalid node type: '||aNode.typ, TRUE);
	END CASE;
END value_to_clob;

----------------------------------------------------------
--	object_to_clob
--
PROCEDURE object_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER, theFlushToLOB IN BOOLEAN DEFAULT TRUE)
IS
	i	BINARY_INTEGER	:=	theNodeID;
BEGIN
	--	Serialize the object
	PRAGMA INLINE (add_string, 'YES');
	json_clob.add_string(theLobBuf, theStrBuf, '{');
	WHILE (i IS NOT NULL) LOOP
		--	Add separator from last property if we are not the first one
		IF (i != theNodeID) THEN
			PRAGMA INLINE (add_string, 'YES');
			json_clob.add_string(theLobBuf, theStrBuf, ',');
		END IF;

		--	Add the property pair
		--PRAGMA INLINE (value_to_clob, 'YES');
		json_utils.value_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>i);

		i := theNodes(i).nex;
	END LOOP;
	PRAGMA INLINE (add_string, 'YES');
	json_clob.add_string(theLobBuf, theStrBuf, '}');

	IF (theFlushToLOB) THEN
		json_clob.flush(theLobBuf, theStrBuf);
	END IF;
END object_to_clob;

----------------------------------------------------------
--	array_to_clob
--
PROCEDURE array_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER, theFlushToLOB IN BOOLEAN DEFAULT TRUE)
IS
	i	BINARY_INTEGER	:=	theNodeID;
BEGIN
	--	Serialize the object
	PRAGMA INLINE (add_string, 'YES');
	json_clob.add_string(theLobBuf, theStrBuf, '[');
	WHILE (i IS NOT NULL) LOOP
		--	Add separator from last array entry if we are not the first one
		IF (i != theNodeID) THEN
			PRAGMA INLINE (add_string, 'YES');
			json_clob.add_string(theLobBuf, theStrBuf, ',');
		END IF;

		--	Add the property pair
		PRAGMA INLINE (value_to_clob, 'YES');
		json_utils.value_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>i);

		i := theNodes(i).nex;
	END LOOP;
	PRAGMA INLINE (add_string, 'YES');
	json_clob.add_string(theLobBuf, theStrBuf, ']');

	IF (theFlushToLOB) THEN
		json_clob.flush(theLobBuf, theStrBuf);
	END IF;
END array_to_clob;

----------------------------------------------------------
--	htp_output_clob
--
PROCEDURE htp_output_clob(theLobBuf IN CLOB, theJSONP IN VARCHAR2 DEFAULT NULL)
IS
	MIME_TYPE	CONSTANT	VARCHAR2(30)	:=	'application/json';
	NO_CACHE	CONSTANT	VARCHAR2(32767)	:=	'Cache-Control: no-store, no-cache, must-revalidate, max-age=0
Cache-Control: post-check=0, pre-check=0
Pragma: no-cache
Expires: -1';

	amt						NUMBER			:=	30;
	off						NUMBER			:=	1;
	str						VARCHAR2(4096);
BEGIN
	--	generate the http header identifying this as json and prevent browsers (IE is very agressive here) from caching
	owa_util.mime_header(MIME_TYPE, FALSE);
	htp.p(NO_CACHE);
	owa_util.http_header_close;

	--	the JSONP callback
	IF (theJSONP IS NOT NULL) THEN
		htp.prn(theJSONP || '(');
	END IF;

	--	output the CLOB
	BEGIN
		LOOP
			dbms_lob.read(theLobBuf, amt, off, str);
			htp.prn(str);
			off := off + amt;
			amt := 4096;
		END LOOP;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;

	--	the JSONP callback
	IF (theJSONP IS NOT NULL) THEN
		htp.prn(')');
	END IF;
END htp_output_clob;

----------------------------------------------------------
--	copySubNodes (private)
--
PROCEDURE copySubNodes(theTarget IN OUT NOCOPY json_nodes, theFirstID IN OUT NOCOPY BINARY_INTEGER, theParentID IN BINARY_INTEGER, theSource IN json_nodes, theFirstSourceID IN BINARY_INTEGER)
IS
	aLastID		BINARY_INTEGER;
	aCurrID		BINARY_INTEGER;
	aSourceID	BINARY_INTEGER	:=	theFirstSourceID;
BEGIN
	WHILE (aSourceID IS NOT NULL) LOOP
		--	add a new node
		theTarget.EXTEND(1);
		aCurrID					:= theTarget.LAST;
		theTarget(aCurrID)		:= theSource(aSourceID);
		theTarget(aCurrID).par	:= theParentID;
		theTarget(aCurrID).nex	:= NULL;
		theTarget(aCurrID).sub	:= CASE theSource(aSourceID).sub IS NOT NULL WHEN TRUE THEN aCurrID + 1 ELSE NULL END;

		-- save the first id
		IF (aSourceID = theFirstSourceID AND theFirstID IS NULL) THEN
			theFirstID := aCurrID;
		END IF;

		-- set the next id
		IF (aLastID IS NOT NULL) THEN
			theTarget(aLastID).nex := aCurrID;
		END IF;
		aLastID := aCurrID;

		-- if the node has subnodes recurse into the subnodes
		IF (theSource(aSourceID).sub IS NOT NULL) THEN
			copySubNodes(theTarget=>theTarget, theFirstID=>theFirstID, theParentID=>aCurrID, theSource=>theSource, theFirstSourceID=>theSource(aSourceID).sub);
		END IF;

		-- go to the next node
		aSourceID := theSource(aSourceID).nex;
	END LOOP;
END copySubNodes;

----------------------------------------------------------
--	removeSubNodes (private)
--
PROCEDURE removeSubNodes(theNodes IN OUT NOCOPY json_nodes, theNodeID IN BINARY_INTEGER)
IS
	aNode	CONSTANT	json_node		:= theNodes(theNodeID);
BEGIN
	IF (aNode.sub IS NOT NULL) THEN
		removeSubNodes(theNodes, aNode.sub);
	END IF;
END removeSubNodes;

----------------------------------------------------------
--	number_to_json (private)
--
FUNCTION number_to_json(theNumber IN NUMBER) RETURN VARCHAR2
IS
	s VARCHAR2(32767);
BEGIN
	IF (theNumber IS NOT NULL) THEN
		IF (theNumber < 1 AND theNumber > 0) THEN
			s := '0'|| TO_CHAR(theNumber, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
		ELSIF (theNumber < 0 AND theNumber > -1) THEN
			s := '-0' || SUBSTR(TO_CHAR(theNumber, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''), 2);
		ELSE
			s := TO_CHAR(theNumber, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
		END IF;
	ELSE
		s := 'null';
	END IF;

	RETURN s;
END number_to_json;

----------------------------------------------------------
--	boolean_to_json (private)
--
FUNCTION boolean_to_json(theBoolean IN NUMBER) RETURN VARCHAR2
IS
	s VARCHAR2(32767);
BEGIN
	IF (theBoolean IS NOT NULL) THEN
		s := CASE theBoolean WHEN 1 THEN 'true' ELSE 'false' END;
	ELSE
		s := 'null';
	END IF;

	RETURN s;
END boolean_to_json;

----------------------------------------------------------
--	escape (private)
--
FUNCTION escape(theString IN VARCHAR2, theAsciiOutput IN BOOLEAN DEFAULT TRUE, theEscapeSolitus IN BOOLEAN DEFAULT FALSE) RETURN VARCHAR2
IS
	sb							VARCHAR2(32767) := '';
	buf							VARCHAR2(64);
	num							NUMBER;
BEGIN
	IF (theString IS NULL) THEN
		RETURN '';
	END IF;

	FOR I IN 1 .. LENGTH(theString) LOOP
		buf := SUBSTR(theString, i, 1);

		CASE buf
		WHEN CHR( 8) THEN buf := '\b';	--	backspace b = U+0008
		WHEN CHR( 9) THEN buf := '\t';	--	tabulator t = U+0009
		WHEN CHR(10) THEN buf := '\n';	--	newline   n = U+000A
		WHEN CHR(13) THEN buf := '\f';	--	formfeed  f = U+000C
		WHEN CHR(14) THEN buf := '\r';	--	carret    r = U+000D
		WHEN CHR(34) THEN buf := '\"';
		WHEN CHR(47) THEN				--	slash
			IF (theEscapeSolitus) THEN
				buf := '\/';
			END IF;
		WHEN CHR(92) THEN buf := '\\';	--	backslash
		ELSE
			IF (ASCII(buf) < 32) THEN
				buf := '\u' || REPLACE(SUBSTR(TO_CHAR(ASCII(buf), 'XXXX'), 2, 4), ' ', '0');
			ELSIF (theAsciiOutput) then
				buf := REPLACE(ASCIISTR(buf), '\', '\u');
			END IF;
		END CASE;

		sb := sb || buf;
	END LOOP;

	RETURN sb;
END escape;

----------------------------------------------------------
--	escapeLOB (private)
--
PROCEDURE escapeLOB(theInputLob IN CLOB, theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theAsciiOutput IN BOOLEAN DEFAULT TRUE, theEscapeSolitus IN BOOLEAN DEFAULT FALSE)
IS
	len CONSTANT	NUMBER			:=	dbms_lob.getlength(lob_loc=>theInputLob);
	str				VARCHAR2(32767);
	buf				VARCHAR2(64);
	num				NUMBER;
BEGIN
	-- empty CLOB
	IF (theInputLob IS NULL OR len = 0) THEN
		RETURN;
	END IF;

	-- is the CLOB is so short (32767 / 6) that we can convert it like a VARCHAR2
	IF (len <= 4000) THEN
		str := escape(theString=>theInputLob, theAsciiOutput=>theAsciiOutput, theEscapeSolitus=>theEscapeSolitus);
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>str);
		RETURN;
	END IF;

	-- is the CLOB short enough that we can at leat select from it like a VARCHAR2
	IF (len <= 32767) THEN
		str := theInputLob;
	END IF;

	-- process the lob
	FOR I IN 1 .. len LOOP
		IF (str IS NOT NULL) THEN
			buf := SUBSTR(str, i, 1);
		ELSE
			buf := dbms_lob.substr(lob_loc=>theInputLob, amount=>1, offset=>i);
		END IF;

		CASE buf
		WHEN CHR( 8) THEN buf := '\b';	--	backspace b = U+0008
		WHEN CHR( 9) THEN buf := '\t';	--	tabulator t = U+0009
		WHEN CHR(10) THEN buf := '\n';	--	newline   n = U+000A
		WHEN CHR(13) THEN buf := '\f';	--	formfeed  f = U+000C
		WHEN CHR(14) THEN buf := '\r';	--	carret    r = U+000D
		WHEN CHR(34) THEN buf := '\"';
		WHEN CHR(47) THEN				--	slash
			IF (theEscapeSolitus) THEN
				buf := '\/';
			END IF;
		WHEN CHR(92) THEN buf := '\\';	--	backslash
		ELSE
			IF (ASCII(buf) < 32) THEN
				buf := '\u' || REPLACE(SUBSTR(TO_CHAR(ASCII(buf), 'XXXX'), 2, 4), ' ', '0');
			ELSIF (theAsciiOutput) then
				buf := REPLACE(ASCIISTR(buf), '\', '\u');
			END IF;
		END CASE;

		PRAGMA INLINE (add_string, 'YES');
		json_clob.add_string(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theValue=>buf);
	END LOOP;
END escapeLOB;

END json_utils;
/
