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

set define off

-- uninstall all object
@@uninstall.sql


-- install the headers
@@json_const.pks
show errors
@@json_clob.pks
show errors
@@json_keys.tps
show errors
@@json_node.tps
show errors
@@json_nodes.tps
show errors
@@json_value.tps
show errors
@@json_object.tps
show errors
@@json_array.tps
show errors
@@json_utils.pks
show errors
@@json_parser.pks
show errors
@@json_sql.pks
show errors
@@json_debug.pks
show errors

-- install the bodies
@@json_clob.pkb
show errors
@@json_node.tpb
show errors
@@json_value.tpb
show errors
@@json_object.tpb
show errors
@@json_array.tpb
show errors
@@json_utils.pkb
show errors
@@json_parser.pkb
show errors
@@json_sql.pkb
show errors
@@json_debug.pkb
show errors
