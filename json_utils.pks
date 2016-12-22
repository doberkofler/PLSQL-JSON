CREATE OR REPLACE
PACKAGE json_utils
IS

----------------------------------------------------------
--	get the number of nodes
--
FUNCTION getNodeCount(theNodes IN json_nodes) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	get the node id for the given property name
--
FUNCTION getNodeIDByName(theNodes IN json_nodes, thePropertyName IN VARCHAR2) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	get the node id for the given property 1-relative index
--
FUNCTION getNodeIDByIndex(theNodes IN json_nodes, thePropertyIndex IN NUMBER) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	validate the given list of nodes and raise an
--	exception with id -20100, if an inconsistency is found
--
PROCEDURE validate(theNodes IN OUT NOCOPY json_nodes);

----------------------------------------------------------
--	add a new node to the list of nodes
--
FUNCTION addNode(theNodes IN OUT NOCOPY json_nodes, theNode IN json_node) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	add a new node to the list of nodes and update the
--	next id pointer in the previous node
--
FUNCTION addNode(theNodes IN OUT NOCOPY json_nodes, theLastID IN OUT NOCOPY NUMBER, theNode IN json_node) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	copy nodes to a new target node
--
PROCEDURE copyNodes(theTargetNodes IN OUT NOCOPY json_nodes, theTargetNodeID IN BINARY_INTEGER, theLastID IN OUT NOCOPY NUMBER, theName IN VARCHAR2, theSourceNodes IN json_nodes);

----------------------------------------------------------
--	create subtree of nodes
--
FUNCTION createSubTree(theSourceNodes IN json_nodes, theSourceNodeID IN BINARY_INTEGER) RETURN json_value;

----------------------------------------------------------
--	remove the given node and all of it's subnodes
--
FUNCTION removeNode(theNodes IN OUT NOCOPY json_nodes, theNodeID IN BINARY_INTEGER) RETURN BINARY_INTEGER;

----------------------------------------------------------
--	convert a node value to a JSON string
--
PROCEDURE value_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER);

----------------------------------------------------------
--	convert an object to a JSON string
--
PROCEDURE object_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER, theFlushToLOB IN BOOLEAN DEFAULT TRUE);

----------------------------------------------------------
--	convert an array to a JSON string
--
PROCEDURE array_to_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theNodes IN json_nodes, theNodeID IN NUMBER, theFlushToLOB IN BOOLEAN DEFAULT TRUE);

----------------------------------------------------------
--	copy output to the browser using htp.prn
--
PROCEDURE htp_output_clob(theLobBuf IN CLOB, theJSONP IN VARCHAR2 DEFAULT NULL);

END json_utils;
/
