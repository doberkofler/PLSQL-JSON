CREATE OR REPLACE
TYPE jsonObject IS OBJECT

--	$Id: jsonobject.tps 56520 2019-02-11 22:52:31Z doberkofler $

------------
--  OVERVIEW
--
--  Utilities to efficiently generate JSON
--
--

-----------
--  EXAMPLE
--
--
--	DECLARE
--		aNameObj		jsonObject	:=	jsonObject();
--		aEmailArray		jsonArray	:=	jsonArray();
--		aPersonObj		jsonObject	:=	jsonObject();
--		aPersonArray	jsonArray	:=	jsonArray();
--
--		--	just for debugging
--		aLob			CLOB				:=	empty_clob();
--	BEGIN
--		FOR i IN 1 .. 3 LOOP
--			aNameObj := jsonObject();
--			aNameObj.put('given', 'Jon');
--			aNameObj.put('last', 'Doe');
--
--			aEmailArray := jsonArray();
--			aEmailArray.append('jon.doe@gmail.com');
--			aEmailArray.append('j.doe@gmail.com');
--
--			aPersonObj := jsonObject();
--			aPersonObj.put('id', i);
--			aPersonObj.put('name', aNameObj);
--			aPersonObj.put('income', 4800 + i * 100);
--			aPersonObj.put('birthday', SYSDATE);
--			aPersonObj.put('male', TRUE);
--			aPersonObj.put('voice', aEmailArray.to_jsonValue());
--
--			aPersonArray.append(i);
--			aPersonArray.append(3.14);
--			aPersonArray.append(FALSE);
--			aPersonArray.append(aPersonObj);
--		END LOOP;
--
--		aPersonArray.htp();
--
--		--	just for debugging
--		dbms_lob.createtemporary(aLob, TRUE);
--		aPersonArray.to_clob(aLob);
--		dbms_output.put_line(aLob);
--		dbms_lob.freetemporary(aLob);
--	END;
--	/
--


-------------
--  RESOURCES
--
--	You must use the following modules together:
--		jsonNode (TYPE)
--		jsonNodes (TYPE)
--		json_data (TYPE)
--		jsonObject (TYPE)
--		jsonArray (TYPE)
--		json_utils (PACKAGE)
--
--

(
	nodes		jsonNodes,		--	list of nodes
	lastID		NUMBER,			--	id of the last node in this (not sub objects) object

	--	Constructors
	CONSTRUCTOR FUNCTION jsonObject(SELF IN OUT NOCOPY jsonObject) RETURN SELF AS result,
	CONSTRUCTOR FUNCTION jsonObject(SELF IN OUT NOCOPY jsonObject, theData IN jsonValue) RETURN SELF AS result,
	CONSTRUCTOR FUNCTION jsonObject(SELF IN OUT NOCOPY jsonObject, theJSONString IN CLOB) RETURN SELF AS result,

	--	Member setter methods
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN VARCHAR2),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN CLOB),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN NUMBER),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN DATE),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN BOOLEAN),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN jsonObject),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY jsonObject, theName IN VARCHAR2, theValue IN jsonValue),

	--	Member getter methods
	MEMBER FUNCTION count(SELF IN jsonObject) RETURN NUMBER,
	MEMBER FUNCTION get(SELF IN jsonObject, thePropertyName IN VARCHAR2) RETURN jsonValue,
	MEMBER FUNCTION exist(SELF IN jsonObject, thePropertyName IN VARCHAR2) RETURN BOOLEAN,
	MEMBER FUNCTION get_keys RETURN jsonKeys,

	--	Member convertion methods
	MEMBER FUNCTION to_jsonValue(SELF IN jsonObject) RETURN jsonValue,

	--	Output methods
	MEMBER PROCEDURE to_clob(SELF IN jsonObject, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE),
	MEMBER FUNCTION to_text(SELF IN jsonObject) RETURN VARCHAR2,
	MEMBER PROCEDURE htp(SELF IN jsonObject, theJSONP IN VARCHAR2 DEFAULT NULL)
);
/
