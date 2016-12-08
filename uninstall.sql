/*
 *
 * NAME
 *	uninstall.sql
 *
 * AUTHOR
 *	Dieter Oberkofler
 *
 * FUNCTION
 *	Uninstall the plsql_json objects
 *
 */


DECLARE
	object_does_not_exist EXCEPTION;
	PRAGMA EXCEPTION_INIT(object_does_not_exist, -4043);
BEGIN
	BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE json_const';	EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE json_clob';	EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE json_utils';	EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE json_parser';	EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE json_debug';	EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP TYPE json_array';		EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP TYPE json_object';	EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP TYPE json_value';		EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP TYPE json_nodes';		EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP TYPE json_node';		EXCEPTION WHEN object_does_not_exist THEN NULL; END;
	BEGIN EXECUTE IMMEDIATE 'DROP TYPE json_keys';		EXCEPTION WHEN object_does_not_exist THEN NULL; END;
END;
/
