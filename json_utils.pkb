CREATE OR REPLACE
PACKAGE BODY json_utils
IS

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
		raise_application_error(-20100, 'JSON Validator exception @ node: '||theNodeID||' - '||text);
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
		IF (n.par IS NOT NULL AND theNodes(n.par).typ = 'O' AND n.nam IS NULL) THEN
			error(i, 'Sub nodes of an object node must have a property name');
		END IF;

		--	sub nodes of an array node
		IF (n.par IS NOT NULL AND theNodes(n.par).typ = 'A' AND n.nam IS NOT NULL) THEN
			error(i, 'Sub nodes of an array node are not allowed to have a property name');
		END IF;

		--	type dependent validations
		CASE n.typ

		WHEN '0' THEN	--	null
			IF (n.str IS NOT NULL OR n.num IS NOT NULL OR n.dat IS NOT NULL) THEN
				error(i, 'String or number value not NULL in a null node');
			END IF;

		WHEN 'S' THEN	--	string
			IF (n.num IS NOT NULL) THEN
				error(i, 'Number value not NULL in a string node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a string node');
			END IF;

		WHEN 'N' THEN	--	number
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a number node');
			END IF;
			IF (n.num IS NULL) THEN
				error(i, 'Number value is NULL in a number node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a number node');
			END IF;

		WHEN 'D' THEN	--	date
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a date node');
			END IF;
			IF (n.num IS NOT NULL) THEN
				error(i, 'Number value is not NULL in a date node');
			END IF;
			IF (n.dat IS NULL) THEN
				error(i, 'Date value is NULL in a date node');
			END IF;

		WHEN 'B' THEN	--	boolean
			IF (n.str IS NOT NULL) THEN
				error(i, 'String value not NULL in a boolean node');
			END IF;
			IF (n.num IS NULL OR n.num NOT IN (0, 1)) THEN
				error(i, 'Number values not 0 or 1 in a boolean node');
			END IF;
			IF (n.dat IS NOT NULL) THEN
				error(i, 'Date value not NULL in a number node');
			END IF;

		WHEN 'O' THEN	--	object
			/*
			an object node without subnotes defines an empty object

			IF (n.sub IS NULL OR NOT theNodes.EXISTS(n.sub)) THEN
				error(i, 'Object node with invalid "sub"');
			END IF;
			*/
			NULL;

		WHEN 'A' THEN	--	array
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
	aData	json_value		:=	json_value();
	aLevel	BINARY_INTEGER	:=	1;

	PROCEDURE copy(theTarget IN OUT NOCOPY json_nodes, theParentID IN BINARY_INTEGER, theSource IN json_nodes, theFirstSourceID IN BINARY_INTEGER)
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

			-- set the next id
			IF (aLastID IS NOT NULL) THEN
				theTarget(aLastID).nex := aCurrID;
			END IF;
			aLastID := aCurrID;

			--dbms_output.put_line(LPAD('.', aLevel, '.')||'copied node ('||aSourceID||') to new node: '||json_debug.dump(theTarget(aCurrID), aCurrID));

			-- if the node has subnodes recurse into the subnodes
			IF (theSource(aSourceID).sub IS NOT NULL) THEN
				aLevel := aLevel + 1;
				copy(theTarget=>theTarget, theParentID=>aCurrID, theSource=>theSource, theFirstSourceID=>theSource(aSourceID).sub);
				aLevel := aLevel - 1;
			END IF;

			-- go to the next node
			aSourceID := theSource(aSourceID).nex;
		END LOOP;
	END copy;

BEGIN
	--	if we must only copy a basic node
	IF (theSourceNodes(theSourceNodeID).typ NOT IN ('O', 'A')) THEN
		aData.nodes.EXTEND(1);
		aData.typ			:= NULL;
		aData.nodes(1)		:= theSourceNodes(theSourceNodeID);
		aData.nodes(1).par	:= NULL;
		aData.nodes(1).sub	:= NULL;
		aData.nodes(1).nex	:= NULL;
		RETURN aData;
	END IF;

	--	we must extract a subtree of nodes and create a new tree starting with the first node in the sub tree
	--dbms_output.put_line('json_util.createSubTree for object or array. starting with node: '||theSourceNodes(theSourceNodeID).sub);
	aData.typ := theSourceNodes(theSourceNodeID).typ;
	copy(theTarget=>aData.nodes, theParentID=>NULL, theSource=>theSourceNodes, theFirstSourceID=>theSourceNodes(theSourceNodeID).sub);

	RETURN aData;
END createSubTree;

----------------------------------------------------------
--	value_to_clob
--
PROCEDURE value_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER)
IS
	aNode	json_node	:=	theNodes(theNodeID);
	s		VARCHAR2(32767);
BEGIN
	--	Add the property name
	IF (aNode.nam IS NOT NULL) THEN
		add_to_clob(theLobBuf, theStrBuf, '"');
		add_to_clob(theLobBuf, theStrBuf, escape(aNode.nam));
		add_to_clob(theLobBuf, theStrBuf, '"');
		add_to_clob(theLobBuf, theStrBuf, ':');
	END IF;

	--	Add the property value
	CASE aNode.typ
	WHEN '0' THEN
		add_to_clob(theLobBuf, theStrBuf, 'null');
	WHEN 'S' THEN
		add_to_clob(theLobBuf, theStrBuf, '"');
		add_to_clob(theLobBuf, theStrBuf, escape(aNode.str));
		add_to_clob(theLobBuf, theStrBuf, '"');
	WHEN 'N' THEN
		IF (aNode.num IS NOT NULL) THEN
			s := '';
			IF (aNode.num < 1 AND aNode.num > 0) THEN
				s := '0';
			END IF;
			IF (aNode.num < 0 AND aNode.num > -1) THEN
				s := '-0';
				s := s || SUBSTR(TO_CHAR(aNode.num, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,'''), 2);
			ELSE
				s := s || TO_CHAR(aNode.num, 'TM9', 'NLS_NUMERIC_CHARACTERS=''.,''');
			END IF;
		ELSE
			s := 'null';
		END IF;
		add_to_clob(theLobBuf, theStrBuf, s);
	WHEN 'D' THEN
		add_to_clob(theLobBuf, theStrBuf, '"' || TO_CHAR(aNode.dat, 'YYYY-MM-DD') || 'T' || TO_CHAR(aNode.dat, 'HH24:MI:SS') || '.000Z"');
	WHEN 'B' THEN
		IF (aNode.num IS NOT NULL) THEN
			add_to_clob(theLobBuf, theStrBuf, CASE aNode.num WHEN 1 THEN 'true' ELSE 'false' END);
		ELSE
			add_to_clob(theLobBuf, theStrBuf, 'null');
		END IF;
	WHEN 'O' THEN
		json_utils.object_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>theNodes(theNodeID).sub);
	WHEN 'A' THEN
		json_utils.Array_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>theNodes(theNodeID).sub);
	ELSE
		RAISE VALUE_ERROR;
	END CASE;
END value_to_clob;

----------------------------------------------------------
--	object_to_clob
--
PROCEDURE object_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER)
IS
	i	BINARY_INTEGER	:=	theNodeID;
BEGIN
	--	Serialize the object
	json_utils.add_to_clob(theLobBuf, theStrBuf, '{');
	WHILE (i IS NOT NULL) LOOP
		--	Add separator from last property if we are not the first one
		IF (i != theNodeID) THEN
			json_utils.add_to_clob(theLobBuf, theStrBuf, ',');
		END IF;

		--	Add the property pair
		json_utils.value_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>i);

		i := theNodes(i).nex;
	END LOOP;
	json_utils.add_to_clob(theLobBuf, theStrBuf, '}');

	json_utils.flush_clob(theLobBuf, theStrBuf);
END object_to_clob;

----------------------------------------------------------
--	array_to_clob
--
PROCEDURE array_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER)
IS
	i	BINARY_INTEGER	:=	theNodeID;
BEGIN
	--	Serialize the object
	json_utils.add_to_clob(theLobBuf, theStrBuf, '[');
	WHILE (i IS NOT NULL) LOOP
		--	Add separator from last array entry if we are not the first one
		IF (i != theNodeID) THEN
			json_utils.add_to_clob(theLobBuf, theStrBuf, ',');
		END IF;

		--	Add the property pair
		json_utils.value_to_clob(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf, theNodes=>theNodes, theNodeID=>i);

		i := theNodes(i).nex;
	END LOOP;
	json_utils.add_to_clob(theLobBuf, theStrBuf, ']');

	json_utils.flush_clob(theLobBuf, theStrBuf);
END array_to_clob;

----------------------------------------------------------
--	add_to_clob
--
PROCEDURE add_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theString IN VARCHAR2)
IS
BEGIN
	IF (LENGTHB(theString) > 32767 - LENGTHB(theStrBuf)) THEN
		dbms_lob.writeappend(theLobBuf, LENGTH(theStrBuf), theStrBuf);
		theStrBuf := theString;
	ELSE
		theStrBuf := theStrBuf || theString;
	END IF;
END add_to_clob;

----------------------------------------------------------
--	flush_clob
--
PROCEDURE flush_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2)
IS
BEGIN
	IF (theStrBuf IS NOT NULL) THEN
		dbms_lob.writeappend(theLobBuf, LENGTH(theStrBuf), theStrBuf);
		theStrBuf := NULL;
	END IF;
END flush_clob;

PROCEDURE erase_clob(theLobBuf IN OUT NOCOPY CLOB)
IS
	aAmount	NUMBER			:= dbms_lob.getlength(theLobBuf);
BEGIN
	IF (aAmount > 0) THEN
		dbms_lob.trim(theLobBuf, 0);
		dbms_lob.erase(theLobBuf, aAmount);
	END IF;
END erase_clob;

----------------------------------------------------------
--	escape
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
		WHEN CHR(47) THEN
			IF (theEscapeSolitus) THEN
				buf := '\/';
			END IF;
		WHEN CHR(92) THEN buf := '\\';
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
--	htp_output_clob
--
PROCEDURE htp_output_clob(theLobBuf IN CLOB, theJSONP IN VARCHAR2 DEFAULT NULL)
IS
	amt		NUMBER			:=	30;
	off		NUMBER			:=	1;
	str		VARCHAR2(4096);
BEGIN
	--	open the headers
	owa_util.mime_header('application/json', FALSE);

	--	close the headers
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

END json_utils;
/
