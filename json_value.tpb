CREATE OR REPLACE
TYPE BODY json_value
IS


----------------------------------------------------------
--	json_value
--
CONSTRUCTOR FUNCTION json_value(SELF IN OUT NOCOPY json_value) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	NULL;
	SELF.nodes	:=	json_nodes();
	RETURN;
END json_value;

----------------------------------------------------------
--	json_value
--
CONSTRUCTOR FUNCTION json_value(SELF IN OUT NOCOPY json_value, theJSONString IN CLOB) RETURN SELF AS RESULT
IS
	value	json_value	:=	json_value();
BEGIN
	value		:=	json_parser.parse_any(theJSONString);
	SELF.typ	:=	value.typ;
	SELF.nodes	:=	value.nodes;
	RETURN;
END json_value;

----------------------------------------------------------
--	get_type
--
MEMBER FUNCTION get_type RETURN VARCHAR2
IS
BEGIN
	IF (SELF.typ IS NULL) THEN
		CASE SELF.nodes(1).typ
		WHEN '0' THEN RETURN 'NULL';
		WHEN 'S' THEN RETURN 'STRING';
		WHEN 'N' THEN RETURN 'NUMBER';
		WHEN 'D' THEN RETURN 'DATE';
		WHEN 'B' THEN RETURN 'BOOLEAN';
		ELSE
			raise_application_error(-20100, 'json_node exception: node type ('||SELF.nodes(1).typ||') invalid');
			RETURN NULL;
		END CASE;
	ELSIF (SELF.typ = 'O') THEN
		RETURN 'OBJECT';
	ELSIF (SELF.typ = 'A') THEN
		RETURN 'ARRAY';
	ELSE
		raise_application_error(-20100, 'json_node exception: node type ('||SELF.typ||') invalid');
		RETURN NULL;
	END IF;
END get_type;

----------------------------------------------------------
--	get_name
--
MEMBER FUNCTION get_name RETURN VARCHAR2
IS
BEGIN
	RETURN SELF.nodes(1).nam;
END get_name;

----------------------------------------------------------
--	get_string
--
MEMBER FUNCTION get_string(theMaxByteSize NUMBER DEFAULT NULL, theMaxCharSize NUMBER DEFAULT NULL) RETURN VARCHAR2
IS
BEGIN
	IF (SELF.is_string()) THEN
		RETURN SELF.nodes(1).str;
	ELSE
		raise_application_error(-20100, 'json_node exception: attempt to get a string from a node with type ('||SELF.typ||')');
		RETURN NULL;
	END IF;
END get_string;

----------------------------------------------------------
--	get_number
--
MEMBER FUNCTION get_number RETURN NUMBER
IS
BEGIN
	IF (SELF.is_number()) THEN
		RETURN SELF.nodes(1).num;
	ELSE
		raise_application_error(-20100, 'json_node exception: attempt to get a number from a node with type ('||SELF.typ||')');
		RETURN NULL;
	END IF;
END get_number;

----------------------------------------------------------
--	get_date
--
MEMBER FUNCTION get_date RETURN DATE
IS
BEGIN
	IF (SELF.is_date()) THEN
		RETURN SELF.nodes(1).dat;
	ELSE
		raise_application_error(-20100, 'json_node exception: attempt to get a date from a node with type ('||SELF.typ||')');
		RETURN NULL;
	END IF;
END get_date;

----------------------------------------------------------
--	get_bool
--
MEMBER FUNCTION get_bool RETURN BOOLEAN
IS
BEGIN
	IF (SELF.is_bool()) THEN
		RETURN (SELF.nodes(1).num = 1);
	ELSE
		raise_application_error(-20100, 'json_node exception: attempt to get a boolean from a node with type ('||SELF.typ||')');
		RETURN NULL;
	END IF;
END get_bool;

----------------------------------------------------------
--	is_object
--
MEMBER FUNCTION is_object RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'OBJECT');
END is_object;

----------------------------------------------------------
--	is_array
--
MEMBER FUNCTION is_array RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'ARRAY');
END is_array;

----------------------------------------------------------
--	is_string
--
MEMBER FUNCTION is_string RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'STRING');
END is_string;

----------------------------------------------------------
--	is_number
--
MEMBER FUNCTION is_number RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'NUMBER');
END is_number;

----------------------------------------------------------
--	is_date
--
MEMBER FUNCTION is_date RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'DATE');
END is_date;

----------------------------------------------------------
--	is_bool
--
MEMBER FUNCTION is_bool RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'BOOLEAN');
END is_bool;

----------------------------------------------------------
--	is_null
--
MEMBER FUNCTION is_null RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'NULL');
END is_null;


END;
/
