/*
 *
 * NAME
 *	user.sql
 *
 * AUTHOR
 *	Dieter Oberkofler
 *
 * FUNCTION
 *	Create a sample "plsql_json" schema
 *
 * NOTES
 *
 */


CREATE USER plsql_json IDENTIFIED BY plsql_json;
GRANT create session TO plsql_json;
GRANT unlimited tablespace TO plsql_json;
GRANT create table TO plsql_json;
GRANT create view TO plsql_json;
GRANT create sequence TO plsql_json;
GRANT create procedure TO plsql_json;
GRANT create trigger TO plsql_json;
GRANT create type TO plsql_json;
GRANT execute on dbms_lob TO plsql_json;
GRANT execute on dbms_output TO plsql_json;
