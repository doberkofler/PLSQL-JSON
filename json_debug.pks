CREATE OR REPLACE
PACKAGE json_debug
IS

TYPE debugRecordType IS RECORD
(
	nodeLevel		NUMBER,
	nodeType		VARCHAR2(30),
	nodeTypeName	VARCHAR2(30),
	nodeName		VARCHAR2(2000),
	arrayIndex		NUMBER,
	nodeValue		VARCHAR2(2000),
	nodeID			NUMBER,
	parentID		NUMBER,
	nextID			NUMBER,
	subNodeID		NUMBER
);
TYPE debugTableType IS TABLE OF debugRecordType;

FUNCTION dump(theNode IN json_node, theNodeID IN NUMBER DEFAULT NULL) RETURN VARCHAR2;
PROCEDURE output(theData IN json_value, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
PROCEDURE output(theObject IN json_object, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
PROCEDURE output(theArray IN json_array, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
PROCEDURE output(theNodes IN json_nodes, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
FUNCTION asTable(theNodes IN json_nodes, theRawFlag IN BOOLEAN DEFAULT FALSE) RETURN debugTableType PIPELINED;

END json_debug;
/
