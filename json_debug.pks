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

FUNCTION dump(theNode IN jsonNode, theNodeID IN NUMBER DEFAULT NULL) RETURN VARCHAR2;
PROCEDURE output(theData IN jsonValue, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
PROCEDURE output(theObject IN jsonObject, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
PROCEDURE output(theArray IN jsonArray, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
PROCEDURE output(theNodes IN jsonNodes, theRawFlag IN BOOLEAN DEFAULT FALSE, theTitle IN VARCHAR2 DEFAULT NULL);
FUNCTION asTable(theNodes IN jsonNodes, theRawFlag IN BOOLEAN DEFAULT FALSE) RETURN debugTableType PIPELINED;

END json_debug;
/
