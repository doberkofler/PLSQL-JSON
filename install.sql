/*
 *
 * NAME
 *	install.sql
 *
 * AUTHOR
 *	Dieter Oberkofler
 *
 * FUNCTION
 *	Install the plsql_json objects
 *
 */

spool install.log

set define off echo on termout off

-- uninstall all object
@@uninstall.sql


-- install the headers
@@json_clob.pks
show errors
@@jsonkeys.tps
show errors
@@jsonnode.tps
show errors
@@jsonnodes.tps
show errors
@@jsonvalue.tps
show errors
@@jsonobject.tps
show errors
@@jsonarray.tps
show errors
@@json_utils.pks
show errors
@@json_parser.pks
show errors
@@json_sql.pks
show errors

-- install the bodies
@@json_clob.pkb
show errors
@@jsonnode.tpb
show errors
@@jsonvalue.tpb
show errors
@@jsonobject.tpb
show errors
@@jsonarray.tpb
show errors
@@json_utils.pkb
show errors
@@json_parser.pkb
show errors
@@json_sql.pkb
show errors

spool off

set define on echo off termout on
