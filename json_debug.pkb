CREATE OR REPLACE
PACKAGE BODY json_debug
IS

PROCEDURE dumpRaw(theNodes IN json_nodes, theResult IN OUT NOCOPY json_debug.debugTableType);
PROCEDURE dump(theNodes IN json_nodes, theFirstNodeID IN NUMBER, theLevel IN OUT NUMBER, theResult IN OUT NOCOPY json_debug.debugTableType);
FUNCTION dump(theNodes IN json_nodes, theNodeID IN NUMBER, theLevel IN NUMBER) RETURN json_debug.debugRecordType;
FUNCTION lalign(theString IN VARCHAR2, theSize IN BINARY_INTEGER) RETURN VARCHAR2;
FUNCTION ralign(theString IN VARCHAR2, theSize IN BINARY_INTEGER) RETURN VARCHAR2;

----------------------------------------------------------
--	output
--
FUNCTION dump(theNode IN json_node, theNodeID IN NUMBER DEFAULT NULL) RETURN VARCHAR2
IS
BEGIN
	RETURN	CASE theNodeID IS NOT NULL WHEN TRUE THEN 'nodeID=('||theNodeID||') ' ELSE '' END ||
			'typ=('||theNode.typ||') nam=('||theNode.nam||') par=('||theNode.par||') nex=('||theNode.nex||') sub=('||theNode.sub||') str=('||theNode.str||') num=('||theNode.num||')';
END dump;

----------------------------------------------------------
--	output
--
PROCEDURE output(theData IN json_value, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL)
IS
	aTitle	VARCHAR2(32767)	:=	theTitle;
BEGIN
	IF (aTitle IS NOT NULL) THEN
		aTitle := aTitle || ' - ';
	END IF;
	aTitle := aTitle || 'json_data('||theData.typ||')';

	output(theNodes=>theData.nodes, theRawFlag=>theRawFlag, theTitle=>aTitle);
END output;

----------------------------------------------------------
--	output
--
PROCEDURE output(theObject IN json_object, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL)
IS
	aTitle	VARCHAR2(32767)	:=	theTitle;
BEGIN
	IF (aTitle IS NOT NULL) THEN
		aTitle := aTitle || ' - ';
	END IF;
	aTitle := aTitle || 'json_object';

	output(theNodes=>theObject.nodes, theRawFlag=>theRawFlag, theTitle=>aTitle);
END output;

----------------------------------------------------------
--	output
--
PROCEDURE output(theArray IN json_array, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL)
IS
	aTitle	VARCHAR2(32767)	:=	theTitle;
BEGIN
	IF (aTitle IS NOT NULL) THEN
		aTitle := aTitle || ' - ';
	END IF;
	aTitle := aTitle || 'json_array';

	output(theNodes=>theArray.nodes, theRawFlag=>theRawFlag, theTitle=>aTitle);
END output;

----------------------------------------------------------
--	output
--
PROCEDURE output(theNodes IN json_nodes, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL)
IS
	r	json_debug.debugTableType	:=	json_debug.debugTableType();
	i	BINARY_INTEGER;
	l	BINARY_INTEGER;
	n	BINARY_INTEGER	:=	1;

	PROCEDURE output_line(theLevel IN VARCHAR2, theNo IN VARCHAR2, theNodeID IN VARCHAR2, theType IN VARCHAR2, theName IN VARCHAR2, theArrayIndex IN VARCHAR2, theParentID IN VARCHAR2, theNextID IN VARCHAR2, theSubNodeID IN VARCHAR2, theValue IN VARCHAR2)
	IS
	BEGIN
		dbms_output.put_line(	lalign(theLevel,				10) || ' ' ||
								ralign(theNo,			 		 5) || ' ' ||
								ralign(theNodeID,				10) || ' ' ||
								lalign(theType,					10) || ' ' ||
								lalign(NVL(theName, '-'),		30) || ' ' ||
								ralign(NVL(theArrayIndex, '-'),	 5) || ' ' ||
								ralign(NVL(theParentID, '-'),	10) || ' ' ||
								ralign(NVL(theNextID, '-'),		10) || ' ' ||
								ralign(NVL(theSubNodeID, '-'),	10) || ' ' ||
								lalign(theValue,				60)
								);
	END output_line;
BEGIN
	IF (theTitle IS NOT NULL) THEN
		dbms_output.put_line('.');
		dbms_output.put_line('---------- '||theTitle||' - BEGIN ----------');
	END IF;

	IF (theRawFlag) THEN
		json_debug.dumpRaw(theNodes=>theNodes, theResult=>r);
	ELSE
		json_debug.dump(theNodes=>theNodes, theFirstNodeID=>theNodes.FIRST, theLevel=>l, theResult=>r);
	END IF;

	output_line('Level',      '#',     'Node#',      'Type',       'Name',                           'Index', 'Parent',     'Next',       'Sub',        'Value');
	output_line('----------', '-----', '----------', '----------', '------------------------------', '-----', '----------', '----------', '----------', '------------------------------------------------------------');

	i := r.FIRST;
	WHILE (i IS NOT NULL) LOOP
		output_line(	theLevel		=>	RPAD('*', NVL(r(i).nodeLevel, 0) + 1, '*'),
						theNo			=>	n,
						theNodeID		=>	r(i).nodeID,
						theType			=>	r(i).nodeType,
						theArrayIndex	=>	r(i).arrayIndex,
						theValue		=>	r(i).nodeValue,
						theParentID		=>	r(i).parentID,
						theNextID		=>	r(i).nextID,
						theSubNodeID	=>	r(i).subNodeID,
						theName			=>	r(i).nodeName
						);
		n := n + 1;
		i := r.NEXT(i);
	END LOOP;

	IF (theTitle IS NOT NULL) THEN
		dbms_output.put_line('---------- '||theTitle||' - END ------------');
		dbms_output.put_line('.');
	END IF;
END output;

----------------------------------------------------------
--	asTable
--
FUNCTION asTable(theNodes IN json_nodes, theRawFlag IN BOOLEAN DEFAULT FALSE) RETURN json_debug.debugTableType PIPELINED
IS
	r	json_debug.debugTableType	:=	json_debug.debugTableType();
	i	BINARY_INTEGER;
	l	BINARY_INTEGER;
BEGIN
	IF (theRawFlag) THEN
		json_debug.dumpRaw(theNodes=>theNodes, theResult=>r);
	ELSE
		json_debug.dump(theNodes=>theNodes, theFirstNodeID=>theNodes.FIRST, theLevel=>l, theResult=>r);
	END IF;

	i := r.FIRST;
	WHILE (i IS NOT NULL) LOOP
		PIPE ROW(r(i));
		i := r.NEXT(i);
	END LOOP;

	RETURN;
END asTable;

----------------------------------------------------------
--	dumpRaw (private)
--
PROCEDURE dumpRaw(theNodes IN json_nodes, theResult IN OUT NOCOPY json_debug.debugTableType)
IS
	i	BINARY_INTEGER;
BEGIN
	i := theNodes.FIRST;
	WHILE (i IS NOT NULL) LOOP
		theResult.EXTEND(1);
		theResult(theResult.LAST) := json_debug.dump(theNodes=>theNodes, theNodeID=>i, theLevel=>NULL);
		i := theNodes.NEXT(i);
	END LOOP;
END dumpRaw;

----------------------------------------------------------
--	dump (private)
--
PROCEDURE dump(theNodes IN json_nodes, theFirstNodeID IN NUMBER, theLevel IN OUT NUMBER, theResult IN OUT NOCOPY json_debug.debugTableType)
IS
	l	BINARY_INTEGER	:=	NVL(theLevel, 0);
	i	BINARY_INTEGER	:=	theFirstNodeID;
BEGIN
	WHILE (i IS NOT NULL) LOOP
		IF (theNodes(i).typ IN ('O', 'A')) THEN
			theResult.EXTEND(1);
			theResult(theResult.LAST) := json_debug.dump(theNodes=>theNodes, theNodeID=>i, theLevel=>l);

			l := l + 1;
			json_debug.dump(theNodes=>theNodes, theFirstNodeID=>theNodes(i).sub, theLevel=>l, theResult=>theResult);
			l := l - 1;
		ELSE
			theResult.EXTEND(1);
			theResult(theResult.LAST) := json_debug.dump(theNodes=>theNodes, theNodeID=>i, theLevel=>l);
		END IF;

		i := theNodes(i).nex;
	END LOOP;
END dump;

----------------------------------------------------------
--	dump (private)
--
FUNCTION dump(theNodes IN json_nodes, theNodeID IN NUMBER, theLevel IN NUMBER) RETURN json_debug.debugRecordType
IS
	r	json_debug.debugRecordType;

	FUNCTION getArrayIndex(theNodes IN json_nodes, theNodeID IN NUMBER) RETURN NUMBER
	IS
		p	BINARY_INTEGER;
		i	BINARY_INTEGER;
		x	BINARY_INTEGER;
	BEGIN
		r.arrayIndex	:=	NULL;
		p := theNodes(theNodeID).par;
		IF (p IS NOT NULL AND theNodes(p).typ = 'A') THEN
			--dbms_output.put_line('node '||theNodeID||' is part of an an array');
			x := 0;
			i := theNodes(p).sub;
			WHILE (i IS NOT NULL) LOOP
				IF (i = theNodeID) THEN
					RETURN x;
				END IF;
				x := x + 1;
				i := theNodes(i).nex;
			END LOOP;
		END IF;

		RETURN NULL;
	END getArrayIndex;
BEGIN
	--	type independent information
	r.nodeLevel		:=	theLevel;
	r.nodeID		:=	theNodeID;
	r.nodeName		:=	theNodes(theNodeID).nam;
	r.parentID		:=	theNodes(theNodeID).par;
	r.nextID		:=	theNodes(theNodeID).nex;
	r.subNodeID		:=	theNodes(theNodeID).sub;

	--	compute the array index
	r.arrayIndex	:=	getArrayIndex(theNodes=>theNodes, theNodeID=>theNodeID);

	--	type dependent information
	CASE theNodes(theNodeID).typ
	WHEN '0' THEN
		r.nodeType	:=	'NULL';
		r.nodeValue	:=	NULL;
	WHEN 'S' THEN
		r.nodeType	:=	'STRING';
		IF (theNodes(theNodeID).str IS NOT NULL) THEN
			r.nodeValue	:=	SUBSTR(theNodes(theNodeID).str, 1, 2000);
		END IF;
	WHEN 'N' THEN
		r.nodeType := 'NUMBER';
		IF (theNodes(theNodeID).num IS NOT NULL) THEN
			r.nodeValue := TO_CHAR(theNodes(theNodeID).num);
		END IF;
	WHEN 'D' THEN
		r.nodeType := 'DATE';
		IF (theNodes(theNodeID).dat IS NOT NULL) THEN
			r.nodeValue := TO_CHAR(theNodes(theNodeID).dat, 'YYYYMMDD HH24MISS');
		END IF;
	WHEN 'B' THEN
		r.nodeType := 'BOOL';
		IF (theNodes(theNodeID).num IS NOT NULL) THEN
			r.nodeValue := CASE theNodes(theNodeID).num WHEN 1 THEN 'true' ELSE 'false' END;
		END IF;
	WHEN 'O' THEN
		r.nodeType := '[OBJECT]';
	WHEN 'A' THEN
		r.nodeType := '[ARRAY]';
	ELSE
		r.nodeType := TO_CHAR(theNodes(theNodeID).typ);
	END CASE;

	RETURN r;
END dump;

----------------------------------------------------------
--	lalign (private)
--
FUNCTION lalign(theString IN VARCHAR2, theSize IN BINARY_INTEGER) RETURN VARCHAR2
IS
	l	BINARY_INTEGER	:=	LENGTH(theString);
BEGIN
	IF (theString IS NULL OR l IS NULL OR l = 0) THEN
		RETURN RPAD(' ', theSize, ' ');
	ELSIF (l = theSize) THEN
		RETURN theString;
	ELSIF (l > theSize) THEN
		RETURN SUBSTR(theString, 1, theSize);
	ELSE
		RETURN RPAD(theString, theSize, ' ');
	END IF;
END lalign;

----------------------------------------------------------
--	ralign (private)
--
FUNCTION ralign(theString IN VARCHAR2, theSize IN BINARY_INTEGER) RETURN VARCHAR2
IS
	l	BINARY_INTEGER	:=	LENGTH(theString);
BEGIN
	IF (theString IS NULL OR l IS NULL OR l = 0) THEN
		RETURN RPAD(' ', theSize, ' ');
	ELSIF (l = theSize) THEN
		RETURN theString;
	ELSIF (l > theSize) THEN
		RETURN SUBSTR(theString, 1, theSize);
	ELSE
		RETURN LPAD(theString, theSize, ' ');
	END IF;
END ralign;


END json_debug;
/
