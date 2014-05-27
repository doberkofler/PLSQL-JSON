CREATE OR REPLACE
TYPE json_object IS OBJECT

--	$Id: json_object.tps 42847 2014-04-06 17:38:58Z doberkofler $

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
--		aNameObj		json_object	:=	json_object();
--		aEmailArray		json_array	:=	json_array();
--		aPersonObj		json_object	:=	json_object();
--		aPersonArray	json_array	:=	json_array();
--
--		--	just for debugging
--		aLob			CLOB				:=	empty_clob();
--	BEGIN
--		FOR i IN 1 .. 3 LOOP
--			aNameObj := json_object();
--			aNameObj.put('given', 'Jon');
--			aNameObj.put('last', 'Doe');
--
--			aEmailArray := json_array();
--			aEmailArray.append('jon.doe@gmail.com');
--			aEmailArray.append('j.doe@gmail.com');
--
--			aPersonObj := json_object();
--			aPersonObj.put('id', i);
--			aPersonObj.put('name', aNameObj);
--			aPersonObj.put('income', 4800 + i * 100);
--			aPersonObj.put('birthday', SYSDATE);
--			aPersonObj.put('male', TRUE);
--			aPersonObj.put('voice', aEmailArray.to_json_value());
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
--		json_node (TYPE)
--		json_nodes (TYPE)
--		json_data (TYPE)
--		json_object (TYPE)
--		json_array (TYPE)
--		json_utils (PACKAGE)
--
--

(
	nodes		json_nodes,		--	list of nodes
	lastID		NUMBER,			--	id of the last node in this (not sub objects) object

	--	Constructors
	CONSTRUCTOR FUNCTION json_object(SELF IN OUT NOCOPY json_object) RETURN SELF AS result,
	CONSTRUCTOR FUNCTION json_object(SELF IN OUT NOCOPY json_object, theData IN json_value) RETURN SELF AS result,
	CONSTRUCTOR FUNCTION json_object(SELF IN OUT NOCOPY json_object, theJSONString IN CLOB) RETURN SELF AS result,

	--	Member setter methods
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2, theValue IN VARCHAR2),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2, theValue IN NUMBER),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2, theValue IN DATE),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2, theValue IN BOOLEAN),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2, theValue IN json_object),
	MEMBER PROCEDURE put(SELF IN OUT NOCOPY json_object, theName IN VARCHAR2, theValue IN json_value),

	--	Member getter methods
	MEMBER FUNCTION count(SELF IN json_object) RETURN NUMBER,
	MEMBER FUNCTION get(SELF IN json_object, thePropertyName IN VARCHAR2) RETURN json_value,
	MEMBER FUNCTION exist(SELF IN json_object, thePropertyName IN VARCHAR2) RETURN BOOLEAN,
	MEMBER FUNCTION get_keys RETURN json_keys,

	--	Member convertion methods
	MEMBER FUNCTION to_json_value(SELF IN json_object) RETURN json_value,

	--	Output methods
	MEMBER PROCEDURE to_clob(SELF IN json_object, theLobBuf IN OUT NOCOPY CLOB, theEraseLob BOOLEAN DEFAULT TRUE),
	MEMBER FUNCTION to_string (SELF IN json_object) RETURN VARCHAR2,
	MEMBER PROCEDURE htp(SELF IN json_object, theJSONP IN VARCHAR2 DEFAULT NULL)
);
/
