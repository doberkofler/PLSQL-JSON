CREATE OR REPLACE
TYPE jsonArray IS OBJECT
(
	nodes		jsonNodes,		--	list of nodes
	lastID		NUMBER,			--	id of the last node in this (not sub objects) object

	--	Constructors
	CONSTRUCTOR FUNCTION jsonArray(self IN OUT NOCOPY jsonArray) RETURN self AS result,
	CONSTRUCTOR FUNCTION jsonArray(SELF IN OUT NOCOPY jsonArray, theData IN jsonValue) RETURN SELF AS result,

	--	Member setter methods
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN VARCHAR2),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN CLOB),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN NUMBER),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN DATE),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN BOOLEAN),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN jsonObject),
	MEMBER PROCEDURE append(self IN OUT NOCOPY jsonArray, theValue IN jsonArray),

	--	Member getter methods
	MEMBER FUNCTION count(SELF IN jsonArray) RETURN NUMBER,
	MEMBER FUNCTION get(SELF IN jsonArray, thePropertyIndex IN NUMBER) RETURN jsonValue,
	MEMBER FUNCTION exist(SELF IN jsonArray, thePropertyIndex IN NUMBER) RETURN BOOLEAN,

	--	Member convertion methods
	MEMBER FUNCTION to_jsonValue(self IN jsonArray) RETURN jsonValue,

	--	Output methods
	MEMBER PROCEDURE to_clob(SELF IN jsonArray, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE),
	MEMBER FUNCTION to_text(SELF IN jsonArray) RETURN VARCHAR2,
	MEMBER PROCEDURE htp(SELF IN jsonArray, theJSONP IN VARCHAR2 DEFAULT NULL)
);
/
