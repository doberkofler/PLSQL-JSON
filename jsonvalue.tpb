CREATE OR REPLACE
TYPE BODY jsonValue
IS


----------------------------------------------------------
--	jsonValue
--
CONSTRUCTOR FUNCTION jsonValue(SELF IN OUT NOCOPY jsonValue) RETURN SELF AS RESULT
IS
BEGIN
	SELF.typ	:=	NULL;
	SELF.nodes	:=	jsonNodes();
	RETURN;
END jsonValue;

----------------------------------------------------------
--	get_type
--
MEMBER FUNCTION get_type RETURN VARCHAR2
IS
BEGIN
	IF (SELF.typ IS NULL) THEN
		CASE SELF.nodes(1).typ
		WHEN json_utils.NODE_TYPE_NULL THEN RETURN 'NULL';
		WHEN json_utils.NODE_TYPE_STRING THEN RETURN 'STRING';
		WHEN json_utils.NODE_TYPE_LOB THEN RETURN 'LOB';
		WHEN json_utils.NODE_TYPE_NUMBER THEN RETURN 'NUMBER';
		WHEN json_utils.NODE_TYPE_DATE THEN RETURN 'DATE';
		WHEN json_utils.NODE_TYPE_BOOLEAN THEN RETURN 'BOOLEAN';
		ELSE
			raise_application_error(-20100, 'jsonNode exception: node type ('||SELF.nodes(1).typ||') invalid');
			RETURN NULL;
		END CASE;
	ELSIF (SELF.typ = json_utils.NODE_TYPE_OBJECT) THEN
		RETURN 'OBJECT';
	ELSIF (SELF.typ = json_utils.NODE_TYPE_ARRAY) THEN
		RETURN 'ARRAY';
	ELSE
		raise_application_error(-20100, 'jsonNode exception: node type ('||SELF.typ||') invalid');
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
MEMBER FUNCTION get_string RETURN VARCHAR2
IS
BEGIN
	IF (SELF.is_string()) THEN
		RETURN SELF.nodes(1).str;
	ELSIF (SELF.is_lob()) THEN
		IF (dbms_lob.getlength(lob_loc=>SELF.nodes(1).lob) <= 32767) THEN
			RETURN SELF.nodes(1).lob;
		ELSE
			raise_application_error(-20100, 'jsonNode exception: attempt to get a lob > 32767 as a string');
			RETURN NULL;
		END IF;
	ELSE
		raise_application_error(-20100, 'jsonNode exception: attempt to get a string from a node with type ('||SELF.get_type||')');
		RETURN NULL;
	END IF;
END get_string;

----------------------------------------------------------
--	get_lob
--
MEMBER FUNCTION get_lob RETURN CLOB
IS
BEGIN
	IF (SELF.is_lob()) THEN
		RETURN SELF.nodes(1).lob;
	ELSIF (SELF.is_string()) THEN
		RETURN TO_CLOB(SELF.nodes(1).str);
	ELSE
		raise_application_error(-20100, 'jsonNode exception: attempt to get a lob from a node with type ('||SELF.get_type||')');
		RETURN NULL;
	END IF;
END get_lob;

----------------------------------------------------------
--	get_number
--
MEMBER FUNCTION get_number RETURN NUMBER
IS
BEGIN
	IF (SELF.is_number()) THEN
		RETURN SELF.nodes(1).num;
	ELSE
		raise_application_error(-20100, 'jsonNode exception: attempt to get a number from a node with type ('||SELF.get_type||')');
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
		raise_application_error(-20100, 'jsonNode exception: attempt to get a date from a node with type ('||SELF.get_type||')');
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
		raise_application_error(-20100, 'jsonNode exception: attempt to get a boolean from a node with type ('||SELF.get_type||')');
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
--	is_lob
--
MEMBER FUNCTION is_lob RETURN BOOLEAN
IS
BEGIN
	RETURN (SELF.get_type = 'LOB');
END is_lob;

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
