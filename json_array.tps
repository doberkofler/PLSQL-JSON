CREATE OR REPLACE
TYPE json_array IS OBJECT
(
	nodes		json_nodes,		--	list of nodes
	lastID		NUMBER,			--	id of the last node in this (not sub objects) object

	--	Constructors
	CONSTRUCTOR FUNCTION json_array(self IN OUT NOCOPY json_array) RETURN self AS result,
	CONSTRUCTOR FUNCTION json_array(SELF IN OUT NOCOPY json_array, theData IN json_value) RETURN SELF AS result,

	--	Member setter methods
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN VARCHAR2),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN CLOB),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN NUMBER),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN DATE),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN BOOLEAN),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN json_object),
	MEMBER PROCEDURE append(self IN OUT NOCOPY json_array, theValue IN json_array),

	--	Member getter methods
	MEMBER FUNCTION count(SELF IN json_array) RETURN NUMBER,
	MEMBER FUNCTION get(SELF IN json_array, thePropertyIndex IN NUMBER) RETURN json_value,
	MEMBER FUNCTION exist(SELF IN json_array, thePropertyIndex IN NUMBER) RETURN BOOLEAN,

	--	Member convertion methods
	MEMBER FUNCTION to_json_value(self IN json_array) RETURN json_value,

	--	Output methods
	MEMBER PROCEDURE to_clob(SELF IN json_array, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE),
	MEMBER FUNCTION to_text(SELF IN json_array) RETURN VARCHAR2,
	MEMBER PROCEDURE htp(SELF IN json_array, theJSONP IN VARCHAR2 DEFAULT NULL)
);
/
