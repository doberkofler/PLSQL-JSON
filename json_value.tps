CREATE OR REPLACE
TYPE json_value IS OBJECT
(
	typ		CHAR(1),				--	O=Object, A=array or NULL for all other basic types
	nodes	json_nodes,				--	if typ is NULL the actual type is in the fisrt and only node of the list

	--	Default constructor
	CONSTRUCTOR FUNCTION json_value(SELF IN OUT NOCOPY json_value) RETURN SELF AS RESULT,

	--	Member getter methods
	MEMBER FUNCTION get_type RETURN VARCHAR2,
	MEMBER FUNCTION get_name RETURN VARCHAR2,

	MEMBER FUNCTION get_string(theMaxByteSize NUMBER DEFAULT NULL, theMaxCharSize NUMBER DEFAULT NULL) RETURN VARCHAR2,
	MEMBER FUNCTION get_number RETURN NUMBER,
	MEMBER FUNCTION get_bool RETURN BOOLEAN,

	MEMBER FUNCTION is_object RETURN BOOLEAN,
	MEMBER FUNCTION is_array RETURN BOOLEAN,
	MEMBER FUNCTION is_string RETURN BOOLEAN,
	MEMBER FUNCTION is_number RETURN BOOLEAN,
	MEMBER FUNCTION is_bool RETURN BOOLEAN,
	MEMBER FUNCTION is_null RETURN BOOLEAN
);
/
