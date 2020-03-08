CREATE OR REPLACE
PACKAGE json_utils
IS

NODE_TYPE_NULL			CONSTANT	VARCHAR2(1)	:= '0';
NODE_TYPE_STRING		CONSTANT	VARCHAR2(1)	:= 'S';
NODE_TYPE_LOB			CONSTANT	VARCHAR2(1)	:= 'L';
NODE_TYPE_NUMBER		CONSTANT	VARCHAR2(1)	:= 'N';
NODE_TYPE_DATE			CONSTANT	VARCHAR2(1)	:= 'D';
NODE_TYPE_BOOLEAN		CONSTANT	VARCHAR2(1)	:= 'B';
NODE_TYPE_OBJECT		CONSTANT	VARCHAR2(1)	:= 'O';
NODE_TYPE_ARRAY			CONSTANT	VARCHAR2(1)	:= 'A';

----------------------------------------------------------
--	add_string
--
PROCEDURE add_string(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theValue IN VARCHAR2);

----------------------------------------------------------
--	add_clob
--
PROCEDURE add_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theValue IN CLOB);

----------------------------------------------------------
--	erase_clob
--
PROCEDURE erase_clob(theLobBuf IN OUT NOCOPY CLOB);

----------------------------------------------------------
--	flush_clob
--
PROCEDURE flush_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2);

----------------------------------------------------------
--	get the number of nodes
--
FUNCTION getNodeCount(theNodes IN jsonNodes) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	get the node id for the given property name
--
FUNCTION getNodeIDByName(theNodes IN jsonNodes, thePropertyName IN VARCHAR2) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	get the node id for the given property 1-relative index
--
FUNCTION getNodeIDByIndex(theNodes IN jsonNodes, thePropertyIndex IN NUMBER) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	validate the given list of nodes and raise an
--	exception with id -20100, if an inconsistency is found
--
PROCEDURE validate(theNodes IN OUT NOCOPY jsonNodes);

----------------------------------------------------------
--	add a new node to the list of nodes
--
FUNCTION addNode(theNodes IN OUT NOCOPY jsonNodes, theNode IN jsonNode) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	add a new node to the list of nodes and update the
--	next id pointer in the previous node
--
FUNCTION addNode(theNodes IN OUT NOCOPY jsonNodes, theLastID IN OUT NOCOPY NUMBER, theNode IN jsonNode) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	copy nodes to a new target node
--
PROCEDURE copyNodes(theTargetNodes IN OUT NOCOPY jsonNodes, theTargetNodeID IN BINARY_INTEGER, theLastID IN OUT NOCOPY NUMBER, theName IN VARCHAR2, theSourceNodes IN jsonNodes);

----------------------------------------------------------
--	create subtree of nodes
--
FUNCTION createSubTree(theSourceNodes IN jsonNodes, theSourceNodeID IN BINARY_INTEGER) RETURN jsonValue;

----------------------------------------------------------
--	remove the given node and all of it's subnodes
--
FUNCTION removeNode(theNodes IN OUT NOCOPY jsonNodes, theNodeID IN BINARY_INTEGER) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	convert a node value to a JSON string
--
PROCEDURE value_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN jsonNodes, theNodeID IN NUMBER);

----------------------------------------------------------
--	convert an object to a JSON string
--
PROCEDURE object_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN jsonNodes, theNodeID IN NUMBER, theFlushToLOB IN BOOLEAN DEFAULT TRUE);

----------------------------------------------------------
--	convert an array to a JSON string
--
PROCEDURE array_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN jsonNodes, theNodeID IN NUMBER, theFlushToLOB IN BOOLEAN DEFAULT TRUE);

----------------------------------------------------------
--	copy output to the browser using htp.prn
--
PROCEDURE htp_output_clob(theLobBuf IN CLOB, theJSONP IN VARCHAR2 DEFAULT NULL);

----------------------------------------------------------
--	open the output to the browser
--
PROCEDURE htp_output_open(theJSONP IN VARCHAR2 DEFAULT NULL);

----------------------------------------------------------
--	close the output to the browser
--
PROCEDURE htp_output_close(theJSONP IN VARCHAR2 DEFAULT NULL);

----------------------------------------------------------
--	escape
--
FUNCTION escape(theString IN VARCHAR2, theAsciiOutput IN BOOLEAN DEFAULT TRUE, theEscapeSolitus IN BOOLEAN DEFAULT FALSE) RETURN VARCHAR2;

END json_utils;
/
