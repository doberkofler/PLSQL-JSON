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


-- uninstall all object
@@uninstall.sql


-- install the types
@@json_keys.tps
show errors
@@json_node.tps
show errors
@@json_node.tpb
show errors
@@json_nodes.tps
show errors
@@json_value.tps
show errors
@@json_value.tpb
show errors

-- install the packages
@@json_object.tps
show errors
@@json_array.tps
show errors
@@json_utils.pks
show errors
@@json_parser.pks
show errors
@@json_debug.pks
show errors
@@json_object.tpb
show errors
@@json_array.tpb
show errors
@@json_utils.pkb
show errors
@@json_parser.pkb
show errors
@@json_debug.pkb
show errors
