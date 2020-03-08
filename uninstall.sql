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
	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE jsonArray FORCE';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE jsonObject FORCE';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE jsonValue FORCE';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE jsonNodes FORCE';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE jsonNode FORCE';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE jsonKeys FORCE';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP PACKAGE json_utils';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP PACKAGE json_parser';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP PACKAGE json_sql';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;

	BEGIN
		EXECUTE IMMEDIATE 'DROP PACKAGE json_debug';
	EXCEPTION
		WHEN object_does_not_exist THEN NULL;
	END;
END;
/
