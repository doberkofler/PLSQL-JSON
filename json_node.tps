CREATE OR REPLACE
TYPE json_node IS OBJECT
(
	typ	CHAR(1),					--	0=null, S=string, N=number, B=boolean, O=Object, A=array
	nam	VARCHAR2(32767),			--	property name (only in an object and NULL in an array)
	str	VARCHAR2(32767),			--	property value for string
	num	NUMBER,						--	property value for number and boolean where boolean is stored as 0 for FALSE and 1 for TRUE
	dat	DATE,						--	property value for date
	par	NUMBER,						--	id of the parent node or NULL if this is the root node
	nex	NUMBER,						--	id of the next node or NULL if this is the last node in this object
	sub NUMBER,						--	id of the json_node when type is an object or an array

	--	Default constructor
	CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node) RETURN SELF AS RESULT,

	--	Constructors
	CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2) RETURN SELF AS RESULT,
	CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN VARCHAR2) RETURN SELF AS RESULT,
	CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN NUMBER) RETURN SELF AS RESULT,
	CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN DATE) RETURN SELF AS RESULT,
	CONSTRUCTOR FUNCTION json_node(SELF IN OUT NOCOPY json_node, theName IN VARCHAR2, theValue IN BOOLEAN) RETURN SELF AS RESULT
);
/
