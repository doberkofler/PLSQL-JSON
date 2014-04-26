CREATE OR REPLACE
PACKAGE BODY json_UT IS

----------------------------------------------------------
--	PRIVATE TYPES
----------------------------------------------------------

----------------------------------------------------------
--	LOCAL MODULES
----------------------------------------------------------

----------------------------------------------------------
--	GLOBAL MODULES
----------------------------------------------------------

----------------------------------------------------------
--	UT_escape (private)
--
PROCEDURE UT_escape
IS
	TYPE TestValueType IS RECORD (v VARCHAR2(32767), r VARCHAR2(32767));
	TYPE TestValueList IS TABLE OF TestValueType INDEX BY BINARY_INTEGER;

	aList		TestValueList;
	aTitle		VARCHAR2(32767);
	eExpected	VARCHAR2(32767);

	PROCEDURE addPair(theValue IN VARCHAR2, theResult IN VARCHAR2)
	IS
		i	BINARY_INTEGER	:=	aList.COUNT + 1;
	BEGIN
		aList(i).v := theValue;
		aList(i).r := theResult;
	END addPair;

BEGIN
	UT_util.module('UT_escape');

	addPair('',																'');
	addPair(NULL,															'');
	addPair('a',															'a');
	addPair(' ',															' ');
	addPair(' abc ',														' abc ');
	addPair(' "*" ',														' \"*\" ');
	addPair('/',															'/');
	addPair(CHR(8)||CHR(9)||CHR(10)||CHR(13)||CHR(14)||CHR(34)||CHR(92),	'\b\t\n\f\r\"\\');
	addPair(CHR(1)||CHR(2)||CHR(30)||CHR(31),								'\u0001\u0002\u001E\u001F');

	-- process test values with theEscapeSolidusFlag=FALSE
	FOR i IN 1 .. aList.COUNT LOOP
		aTitle  := 'escapeString(escape=FALSE, ascii=TRUE): string="'||UT_util.asString(aList(i).v)||'"';
		UT_util.eq(theTitle=>aTitle, theExpected=>aList(i).r, theComputed=>json_utils.escape(theString=>aList(i).v), theNullOK=>TRUE);
	END LOOP;
END UT_escape;

----------------------------------------------------------
--	check the internal representation using nodes (private)
--
PROCEDURE UT_Nodes
IS
	aObject1		json_object	:=	json_object();
	aArray1			json_array	:=	json_array();
	aObject2		json_object	:=	json_object();
	aArray2			json_array	:=	json_array();

	aLob			CLOB		:=	empty_clob();

	PROCEDURE checkNode(theNodes IN json_nodes, theNodeID IN NUMBER, theType IN VARCHAR2, theName IN VARCHAR2 DEFAULT NULL, theString IN VARCHAR2 DEFAULT NULL, theNumber IN NUMBER DEFAULT NULL, theParent IN NUMBER DEFAULT NULL, theNext IN NUMBER DEFAULT NULL, theSub IN NUMBER DEFAULT NULL)
	IS
	BEGIN
		UT_util.eq(theTitle=>'#'||theNodeID||'(type)',		theExpected=>theType,	theComputed=>theNodes(theNodeID).typ, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(name)',		theExpected=>theName,	theComputed=>theNodes(theNodeID).nam, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(string)',	theExpected=>theString,	theComputed=>theNodes(theNodeID).str, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(number)',	theExpected=>theNumber,	theComputed=>theNodes(theNodeID).num, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(date)',		theExpected=>NULL,		theComputed=>theNodes(theNodeID).dat, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(parent)',	theExpected=>theParent,	theComputed=>theNodes(theNodeID).par, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(next)',		theExpected=>theNext,	theComputed=>theNodes(theNodeID).nex, theNullOK=>TRUE);
		UT_util.eq(theTitle=>'#'||theNodeID||'(sub)',		theExpected=>theSub,	theComputed=>theNodes(theNodeID).sub, theNullOK=>TRUE);
	END checkNode;
BEGIN
	UT_util.module('UT_Nodes');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	aArray2
	aArray2.append('a1');
	aArray2.append(8.11);

	--	aObject2
	aObject2.put('p1', aArray2.to_json_value());
	aObject2.put('p2', aArray2.to_json_value());

	--	aArray1
	aArray1.append(aObject2);
	aArray1.append(aObject2);

	--	aObject1
	aObject1.put('data', aArray1.to_json_value());

	--	validate
	json_utils.validate(aObject1.nodes);

	--	check JSON string
	aObject1.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'json-string',
					theComputed	=>	aLob,
					theExpected	=>	'{"data":[{"p1":["a1",8.11],"p2":["a1",8.11]},{"p1":["a1",8.11],"p2":["a1",8.11]}]}',
					theNullOK	=>	FALSE
					);

	--	check the nodes
	checkNode(				theNodes=>aObject1.nodes, theNodeID=>1,		theType=>'A', theSub=>2,	theParent=>NULL,	theNext=>NULL,	theName=>'data');
		checkNode(			theNodes=>aObject1.nodes, theNodeID=>2,		theType=>'O', theSub=>3,	theParent=>1,		theNext=>9,		theName=>NULL);
			checkNode(		theNodes=>aObject1.nodes, theNodeID=>3,		theType=>'A', theSub=>4,	theParent=>2,		theNext=>6,		theName=>'p1');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>4,		theType=>'S', theSub=>NULL,	theParent=>3,		theNext=>5,		theName=>NULL,		theString=>'a1');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>5,		theType=>'N', theSub=>NULL, theParent=>3,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
			checkNode(		theNodes=>aObject1.nodes, theNodeID=>6,		theType=>'A', theSub=>7,	theParent=>2,		theNext=>NULL,	theName=>'p2');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL,	theParent=>6,		theNext=>8,		theName=>NULL,		theString=>'a1');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>8,		theType=>'N', theSub=>NULL,	theParent=>6,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
 		checkNode(			theNodes=>aObject1.nodes, theNodeID=>9,		theType=>'O', theSub=>10,	theParent=>1,		theNext=>NULL,	theName=>NULL);
			checkNode(		theNodes=>aObject1.nodes, theNodeID=>10,	theType=>'A', theSub=>11,	theParent=>9,		theNext=>13,	theName=>'p1');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>11,	theType=>'S', theSub=>NULL,	theParent=>10,		theNext=>12,	theName=>NULL,		theString=>'a1');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>12,	theType=>'N', theSub=>NULL, theParent=>10,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
			checkNode(		theNodes=>aObject1.nodes, theNodeID=>13,	theType=>'A', theSub=>14,	theParent=>9,		theNext=>NULL,	theName=>'p2');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>14,	theType=>'S', theSub=>NULL,	theParent=>13,		theNext=>15,	theName=>NULL,		theString=>'a1');
				checkNode(	theNodes=>aObject1.nodes, theNodeID=>15,	theType=>'N', theSub=>NULL,	theParent=>13,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);

	--	cleanup
	dbms_lob.freetemporary(aLob);
END UT_Nodes;

----------------------------------------------------------
--	check the getters (private)
--
PROCEDURE UT_getter
IS
	aObject						json_object	:=	json_object();
	aSubObject					json_object	:=	json_object();
	aArray						json_array	:=	json_array();
	aSubArray					json_array	:=	json_array();

	CURRENT_DATE	CONSTANT	DATE		:=	SYSDATE;

	PROCEDURE testString(theDate IN json_value, theTitle IN VARCHAR2, theValue IN VARCHAR2)
	IS
	BEGIN
		UT_util.eq(theTitle=>theTitle||'(get_type)',	theExpected=>'STRING',	theComputed=>theDate.get_type(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_null)',		theExpected=>FALSE,		theComputed=>theDate.is_null(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_string)',	theExpected=>TRUE,		theComputed=>theDate.is_string(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_number)',	theExpected=>FALSE,		theComputed=>theDate.is_number(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_date)',		theExpected=>FALSE,		theComputed=>theDate.is_date(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_bool)',		theExpected=>FALSE,		theComputed=>theDate.is_bool(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_object)',	theExpected=>FALSE,		theComputed=>theDate.is_object(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_array)',	theExpected=>FALSE,		theComputed=>theDate.is_array(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(get_string)',	theExpected=>theValue,	theComputed=>theDate.get_string(),	theNullOK=>TRUE);
		UT_util.eq(theTitle=>theTitle||'(COUNT)',		theExpected=>1,			theComputed=>theDate.nodes.COUNT,	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(json_node)',	theExpected=>'S',		theComputed=>theDate.nodes(1).typ,	theNullOK=>FALSE);
	END testString;

	PROCEDURE testNumber(theDate IN json_value, theTitle IN VARCHAR2, theValue IN NUMBER)
	IS
	BEGIN
		UT_util.eq(theTitle=>theTitle||'(get_type)',	theExpected=>'NUMBER',	theComputed=>theDate.get_type(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_null)',		theExpected=>FALSE,		theComputed=>theDate.is_null(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_string)',	theExpected=>FALSE,		theComputed=>theDate.is_string(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_number)',	theExpected=>TRUE,		theComputed=>theDate.is_number(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_date)',		theExpected=>FALSE,		theComputed=>theDate.is_date(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_bool)',		theExpected=>FALSE,		theComputed=>theDate.is_bool(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_object)',	theExpected=>FALSE,		theComputed=>theDate.is_object(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_array)',	theExpected=>FALSE,		theComputed=>theDate.is_array(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(get_number)',	theExpected=>theValue,	theComputed=>theDate.get_number(),	theNullOK=>TRUE);
		UT_util.eq(theTitle=>theTitle||'(COUNT)',		theExpected=>1,			theComputed=>theDate.nodes.COUNT,	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(json_node)',	theExpected=>'N',		theComputed=>theDate.nodes(1).typ,	theNullOK=>FALSE);
	END testNumber;

	PROCEDURE testDate(theDate IN json_value, theTitle IN VARCHAR2, theValue IN DATE)
	IS
	BEGIN
		UT_util.eq(theTitle=>theTitle||'(get_type)',	theExpected=>'DATE',	theComputed=>theDate.get_type(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_null)',		theExpected=>FALSE,		theComputed=>theDate.is_null(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_string)',	theExpected=>FALSE,		theComputed=>theDate.is_string(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_number)',	theExpected=>FALSE,		theComputed=>theDate.is_number(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_date)',		theExpected=>TRUE,		theComputed=>theDate.is_date(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_bool)',		theExpected=>FALSE,		theComputed=>theDate.is_bool(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_object)',	theExpected=>FALSE,		theComputed=>theDate.is_object(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_array)',	theExpected=>FALSE,		theComputed=>theDate.is_array(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(get_date)',	theExpected=>theValue,	theComputed=>theDate.get_date(),	theNullOK=>TRUE);
		UT_util.eq(theTitle=>theTitle||'(COUNT)',		theExpected=>1,			theComputed=>theDate.nodes.COUNT,	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(json_node)',	theExpected=>'D',		theComputed=>theDate.nodes(1).typ,	theNullOK=>FALSE);
	END testDate;

	PROCEDURE testBool(theDate IN json_value, theTitle IN VARCHAR2, theValue IN BOOLEAN)
	IS
	BEGIN
		UT_util.eq(theTitle=>theTitle||'(get_type)',	theExpected=>'BOOLEAN',	theComputed=>theDate.get_type(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_null)',		theExpected=>FALSE,		theComputed=>theDate.is_null(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_string)',	theExpected=>FALSE,		theComputed=>theDate.is_string(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_number)',	theExpected=>FALSE,		theComputed=>theDate.is_number(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_date)',		theExpected=>FALSE,		theComputed=>theDate.is_date(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_bool)',		theExpected=>TRUE,		theComputed=>theDate.is_bool(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_object)',	theExpected=>FALSE,		theComputed=>theDate.is_object(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_array)',	theExpected=>FALSE,		theComputed=>theDate.is_array(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(get_bool)',	theExpected=>theValue,	theComputed=>theDate.get_bool(),	theNullOK=>TRUE);
		UT_util.eq(theTitle=>theTitle||'(COUNT)',		theExpected=>1,			theComputed=>theDate.nodes.COUNT,	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(json_node)',	theExpected=>'B',		theComputed=>theDate.nodes(1).typ,	theNullOK=>FALSE);
	END testBool;

	PROCEDURE testNull(theDate IN json_value, theTitle IN VARCHAR2)
	IS
	BEGIN
		UT_util.eq(theTitle=>theTitle||'(get_type)',	theExpected=>'NULL',	theComputed=>theDate.get_type(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_null)',		theExpected=>TRUE,		theComputed=>theDate.is_null(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_string)',	theExpected=>FALSE,		theComputed=>theDate.is_string(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_number)',	theExpected=>FALSE,		theComputed=>theDate.is_number(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_date)',		theExpected=>FALSE,		theComputed=>theDate.is_date(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_bool)',		theExpected=>FALSE,		theComputed=>theDate.is_bool(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_object)',	theExpected=>FALSE,		theComputed=>theDate.is_object(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_array)',	theExpected=>FALSE,		theComputed=>theDate.is_array(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(COUNT)',		theExpected=>1,			theComputed=>theDate.nodes.COUNT,	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(json_node)',	theExpected=>'0',		theComputed=>theDate.nodes(1).typ,	theNullOK=>FALSE);
	END testNull;

	PROCEDURE testType(theDate IN json_value, theTitle IN VARCHAR2, theType IN VARCHAR2)
	IS
		isObject	BOOLEAN	:=	(theType = 'OBJECT');
		isArray		BOOLEAN	:=	(theType = 'ARRAY');
	BEGIN
		UT_util.eq(theTitle=>theTitle||'(get_type)',	theExpected=>theType,	theComputed=>theDate.get_type(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_null)',		theExpected=>FALSE,		theComputed=>theDate.is_null(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_string)',	theExpected=>FALSE,		theComputed=>theDate.is_string(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_number)',	theExpected=>FALSE,		theComputed=>theDate.is_number(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_date)',		theExpected=>FALSE,		theComputed=>theDate.is_date(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_bool)',		theExpected=>FALSE,		theComputed=>theDate.is_bool(),		theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_object)',	theExpected=>isObject,	theComputed=>theDate.is_object(),	theNullOK=>FALSE);
		UT_util.eq(theTitle=>theTitle||'(is_array)',	theExpected=>isArray,	theComputed=>theDate.is_array(),	theNullOK=>FALSE);
	END testType;
BEGIN
	UT_util.module('UT_getter(object)');

	--	aObject
	aObject.put('p1');
	aObject.put('p2', 'string');
	aObject.put('p3', '');
	aObject.put('p4', -0.4711);
	aObject.put('p5', 0);
	aObject.put('p6', CURRENT_DATE);
	aObject.put('p7', TRUE);
	aObject.put('p8', FALSE);
	
	--	validate
	json_utils.validate(aObject.nodes);

	--	test
	testNull(	aObject.get('p1'),		'p1');
	testString(	aObject.get('p2'),		'p2',		'string');
	testString(	aObject.get('p3'),		'p3',		'');
	testNumber(	aObject.get('p4'),		'p4',		-0.4711);
	testNumber(	aObject.get('p5'),		'p5',		0);
	testDate(	aObject.get('p6'),		'p6',		CURRENT_DATE);
	testBool(	aObject.get('p7'),		'p7',		TRUE);
	testBool(	aObject.get('p8'),		'p8',		FALSE);

	UT_util.module('UT_getter(array)');

	--	aArray
	aArray.append();
	aArray.append('string');
	aArray.append('');
	aArray.append(-0.4711);
	aArray.append(0);
	aArray.append(CURRENT_DATE);
	aArray.append(TRUE);
	aArray.append(FALSE);

	--	validate
	json_utils.validate(aArray.nodes);

	--	test
	testNull(	aArray.get(1),		'1');
	testString(	aArray.get(2),		'2',		'string');
	testString(	aArray.get(3),		'3',		'');
	testNumber(	aArray.get(4),		'4',		-0.4711);
	testNumber(	aArray.get(5),		'5',		0);
	testDate(	aArray.get(6),		'6',		CURRENT_DATE);
	testBool(	aArray.get(7),		'7',		TRUE);
	testBool(	aArray.get(8),		'8',		FALSE);

	UT_util.module('UT_getter(nested objects)');

	--	sub object
	aObject		:= json_object();
	aSubObject	:= json_object();
	aSubObject.put('sp1', 'string');
	aSubObject.put('sp2', -0.4711);
	aObject.put('p1', 's');
	aObject.put('p2', aSubObject);
	aObject.put('p3', 0);
	aObject.put('p4', aSubObject);

	--	validate
	json_utils.validate(aSubObject.nodes);
	json_utils.validate(aObject.nodes);

	--	test
	testString(	aObject.get('p1'),	'p1',		's');
	testType(	aObject.get('p2'),	'p2',		'OBJECT');
	testNumber(	aObject.get('p3'),	'p3',		0);
	testType(	aObject.get('p4'),	'p4',		'OBJECT');
END UT_getter;

----------------------------------------------------------
--	UT_Object (private)
--
PROCEDURE UT_Object
IS
	aObject			json_object	:=	json_object();
	aObject2		json_object	:=	json_object();
	aArray			json_array	:=	json_array();
	aNumber			NUMBER;
	aDate			DATE;
	aBoolean		BOOLEAN;

	aLob			CLOB		:=	empty_clob();
BEGIN
	UT_util.module('UT_Object');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	empty object
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'empty',
					theComputed	=>	aLob,
					theExpected	=>	'{}',
					theNullOK	=>	FALSE
					);

	--	put constants to an object
	aObject := json_object();
	aObject.put(theName=>'p1');
	aObject.put(theName=>'p2',	theValue=>'string');
	aObject.put(theName=>'p3',	theValue=>'');
	aObject.put(theName=>'p4',	theValue=>0);
	aObject.put(theName=>'p5',	theValue=>-1);
	aObject.put(theName=>'p6',	theValue=>+2);
	aObject.put(theName=>'p7',	theValue=>.14);
	aObject.put(theName=>'p8',	theValue=>TO_DATE('20141111 111213', 'YYYYMMDD HH24MISS'));
	aObject.put(theName=>'p9',	theValue=>FALSE);
	aObject.put(theName=>'p10',	theValue=>TRUE);
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'constants',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":null,"p2":"string","p3":"","p4":0,"p5":-1,"p6":2,"p7":0.14,"p8":"2014-11-11T11:12:13.000Z","p9":false,"p10":true}',
					theNullOK	=>	FALSE
					);

	-- put variables to an object
	aObject := json_object();
	aObject.put(theName=>'p1', theValue=>aNumber);
	aObject.put(theName=>'p2', theValue=>aDate);
	aObject.put(theName=>'p3', theValue=>aBoolean);
	aNumber := 0;
	aDate := TO_DATE('20141111 111213', 'YYYYMMDD HH24MISS');
	aBoolean := FALSE;
	aObject.put(theName=>'p4', theValue=>aNumber);
	aObject.put(theName=>'p5', theValue=>aDate);
	aObject.put(theName=>'p6', theValue=>aBoolean);
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'variables',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":null,"p2":null,"p3":null,"p4":0,"p5":"2014-11-11T11:12:13.000Z","p6":false}',
					theNullOK	=>	FALSE
					);

	-- do not empty the objects adds parameter and creates an invalid JSON object
	-- (please note that is is done on purpose)
	aObject.put(theName=>'p6', theValue=>'v6');
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'add',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":null,"p2":null,"p3":null,"p4":0,"p5":"2014-11-11T11:12:13.000Z","p6":false,"p6":"v6"}',
					theNullOK	=>	FALSE
					);

	-- put objects to an object
	aObject := json_object();
	aObject.put(theName=>'p1', theValue=>'v1');
	aObject2 := json_object();
	aObject2.put('p2', aObject);
	json_utils.validate(aObject.nodes);
	aObject2.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'objects',
					theComputed	=>	aLob,
					theExpected	=>	'{"p2":{"p1":"v1"}}',
					theNullOK	=>	FALSE
					);

	-- put objects to an object (using to_json_value)
	aObject := json_object();
	aObject.put(theName=>'p1', theValue=>'v1');
	aObject2 := json_object();
	aObject2.put('p2', aObject.to_json_value());
	json_utils.validate(aObject.nodes);
	aObject2.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'objects(to_json_value)',
					theComputed	=>	aLob,
					theExpected	=>	'{"p2":{"p1":"v1"}}',
					theNullOK	=>	FALSE
					);

	-- put arrays to an object
	aArray.append();
	aArray.append(1);
	aObject := json_object();
	aObject.put(theName=>'p1', theValue=>'v1');
	aObject.put(theName=>'p2', theValue=>aArray.to_json_value());
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'arrays',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":[null,1]}',
					theNullOK	=>	FALSE
					);

	--	cleanup
	dbms_lob.freetemporary(aLob);
END UT_Object;

----------------------------------------------------------
--	UT_Array (private)
--
PROCEDURE UT_Array
IS
	aObject			json_object	:=	json_object();
	aArray			json_array	:=	json_array();
	aArray2			json_array	:=	json_array();

	aLob			CLOB		:=	empty_clob();
BEGIN
	UT_util.module('UT_Array');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	empty array
	json_utils.validate(aArray.nodes);
	aArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'empty',
					theComputed	=>	aLob,
					theExpected	=>	'[]',
					theNullOK	=>	FALSE
					);

	--	array of values
	aArray.append();
	aArray.append('string');
	aArray.append(47.11);
	aArray.append(TO_DATE('20141111 111213', 'YYYYMMDD HH24MISS'));
	aArray.append(FALSE);
	aArray.append(aObject);
	json_utils.validate(aArray.nodes);
	aArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'values',
					theComputed	=>	aLob,
					theExpected	=>	'[null,"string",47.11,"2014-11-11T11:12:13.000Z",false,{}]',
					theNullOK	=>	FALSE
					);

	--	array of objects
	aObject.put('id', 10);
	aObject.put('name', 'Jon Doe');
	aArray := json_array();
	aArray.append(aObject);
	json_utils.validate(aArray.nodes);
	aArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'objects',
					theComputed	=>	aLob,
					theExpected	=>	'[{"id":10,"name":"Jon Doe"}]',
					theNullOK	=>	FALSE
					);

	--	array of arrays
	aArray := json_array();
	aArray.append(0);
	aArray.append('0');
	aArray2 := json_array();
	aArray2.append(aArray);
	aArray2.append(aArray);
	json_utils.validate(aArray2.nodes);
	aArray2.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'arrays',
					theComputed	=>	aLob,
					theExpected	=>	'[[0,"0"],[0,"0"]]',
					theNullOK	=>	FALSE
					);

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_Array;

----------------------------------------------------------
--	UT_DeepRecursion (private)
--
PROCEDURE UT_DeepRecursion
IS
	aObject0		json_object	:=	json_object();
	aObject1		json_object	:=	json_object();
	aObject2		json_object	:=	json_object();
	aObject3		json_object	:=	json_object();
	aObject4		json_object	:=	json_object();
	aObject5		json_object	:=	json_object();
	aObject6		json_object	:=	json_object();
	aObject7		json_object	:=	json_object();
	aObject8		json_object	:=	json_object();
	aObject9		json_object	:=	json_object();

	aLob			CLOB		:=	empty_clob();
BEGIN
	UT_util.module('UT_DeepRecursion');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	deep recursion of objects
	aObject9.put('p9', 'v9');
	aObject8.put('p8', aObject9);
	aObject7.put('p7', aObject8);
	aObject6.put('p6', aObject7);
	aObject5.put('p5', aObject6);
	aObject4.put('p4', aObject5);
	aObject3.put('p3', aObject4);
	aObject2.put('p2', aObject3);
	aObject1.put('p1', aObject2);
	aObject0.put('p0', aObject1);
	json_utils.validate(aObject0.nodes);
	aObject0.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'object',
					theComputed	=>	aLob,
					theExpected	=>	'{"p0":{"p1":{"p2":{"p3":{"p4":{"p5":{"p6":{"p7":{"p8":{"p9":"v9"}}}}}}}}}}',
					theNullOK	=>	FALSE
					);

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_DeepRecursion;

----------------------------------------------------------
--	UT_ComplexObject (private)
--
PROCEDURE UT_ComplexObject
IS
	aNameObject		json_object	:=	json_object();
	aEmailArray		json_array	:=	json_array();
	aPersonObject	json_object	:=	json_object();
	aNull			json_object	:=	json_object();
	aPersonArray	json_array	:=	json_array();

	aLob			CLOB		:=	empty_clob();
BEGIN
	UT_util.module('UT_ComplexObject');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	create aNameObject
	aNameObject.put('given', 'Jon');
	aNameObject.put('middle');
	aNameObject.put('last', 'Doe');
	aNameObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'aNameObject',
					theComputed	=>	aLob,
					theExpected	=>	'{"given":"Jon","middle":null,"last":"Doe"}',
					theNullOK	=>	FALSE
					);

	--	create aEmailArray
	aEmailArray := json_array();
	aEmailArray.append('jon.doe@gmail.com');
	aEmailArray.append('j.doe@gmail.com');
	aEmailArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'aEmailArray',
					theComputed	=>	aLob,
					theExpected	=>	'["jon.doe@gmail.com","j.doe@gmail.com"]',
					theNullOK	=>	FALSE
					);

	--	prepare array
	aPersonArray.append(aNull);
	FOR i IN 1 .. 3 LOOP
		aPersonObject	:= json_object();
		aPersonObject.put('id', i);
		aPersonObject.put('name', aNameObject);
		aPersonObject.put('male', TRUE);
		aPersonObject.put('email', aEmailArray.to_json_value());

		aPersonArray.append();
		aPersonArray.append(i);
		aPersonArray.append(3.14);
		aPersonArray.append(FALSE);
		aPersonArray.append(aPersonObject);
	END LOOP;

	-- serialize object
	json_utils.validate(aPersonArray.nodes);
	aPersonArray.to_clob(theLobBuf=>aLob);

	-- test array
	UT_util.eqLOB(	theTitle	=>	'test array',
					theComputed	=>	aLob,
					theExpected	=>	'[{},null,1,3.14,false,{"id":1,"name":{"given":"Jon","middle":null,"last":"Doe"},"male":true,"email":["jon.doe@gmail.com","j.doe@gmail.com"]},null,2,3.14,false,{"id":2,"name":{"given":"Jon","middle":null,"last":"Doe"},"male":true,"email":["jon.doe@gmail.com","j.doe@gmail.com"]},null,3,3.14,false,{"id":3,"name":{"given":"Jon","middle":null,"last":"Doe"},"male":true,"email":["jon.doe@gmail.com","j.doe@gmail.com"]}]',
					theNullOK	=>	FALSE
					);

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_ComplexObject;

----------------------------------------------------------
--	UT_BigObject (private)
--
PROCEDURE UT_BigObject
IS
	aArray			json_array	:=	json_array();

	aString			VARCHAR2(32767);
	aResult			CLOB				:=	empty_clob();
	aLob			CLOB				:=	empty_clob();
BEGIN
	UT_util.module('UT_BigObject');

	--	allocate clob
	dbms_lob.createtemporary(aResult, true);
	dbms_lob.createtemporary(aLob, TRUE);

	--	big object
	aString := '[';
	dbms_lob.writeappend(aResult, LENGTH(aString), aString);
	FOR i IN 1 .. 20000 LOOP
		aString := TO_CHAR(i);
		aArray.append(aString);

		aString := '"' || aString || '"';
		IF (i > 1) THEN
			aString := ',' || aString;
		END IF;
		dbms_lob.writeappend(aResult, LENGTH(aString), aString);
	END LOOP;
	aString := ']';
	dbms_lob.writeappend(aResult, LENGTH(aString), aString);
	json_utils.validate(aArray.nodes);
	aArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'big',
					theComputed	=>	aLob,
					theExpected	=>	aResult,
					theNullOK	=>	FALSE
					);

	--	free temporary CLOB
	dbms_lob.freetemporary(aResult);
	dbms_lob.freetemporary(aLob);
END UT_BigObject;

----------------------------------------------------------
--	UT_ParseBasic (private)
--
PROCEDURE UT_ParseBasic
IS
	TYPE TestValueType IS RECORD (v VARCHAR2(32767), r VARCHAR2(32767));
	TYPE TestValueList IS TABLE OF TestValueType INDEX BY BINARY_INTEGER;

	aList		TestValueList;
	aObject		json_object			:=	json_object();
	aLob		CLOB				:=	empty_clob();
	i			BINARY_INTEGER;

	PROCEDURE addPair(theValue IN VARCHAR2, theResult IN VARCHAR2 DEFAULT NULL)
	IS
		c	BINARY_INTEGER	:=	aList.COUNT + 1;
	BEGIN
		aList(c).v := theValue;
		aList(c).r := NVL(theResult, REPLACE(theValue, ' ', ''));
	END addPair;

BEGIN
	UT_util.module('UT_ParseBasic');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	addPair('{  }');
	addPair('{"p1": null}');
	addPair('{"p1": "v1"}');
	addPair('{"p1": -0.4711}');
	addPair('{"p1": true}');
	addPair('{"p1": false}');
	addPair('{"p1": "v1", "p2": 2, "p3": true}');
	addPair('{"p1": [{"a1p1": "a1v1", "a1p2": {}}, {"a2p1": "a2v2", "a2p2": []}, {"a3p1": "a3v1", "a3p2": [1, 2, 3]}]}');
	addPair('{"p1": {}}');
	addPair('{"p1": []}');
	addPair('{"p1": [{}, {}, {}, [[], {}, [[]]]]}');

	FOR i IN 1 .. aList.COUNT LOOP
		-- parse the json string
		aObject := json_object(aList(i).v);
		
		-- validate the resulting object
		json_utils.validate(aObject.nodes);
		
		-- convert the object back to a version string
		aObject.to_clob(aLob);

		-- test
		UT_util.eqLOB(	theTitle	=>	'#'||i||': '||aList(i).v,
						theComputed	=>	aLob,
						theExpected	=>	aList(i).r,
						theNullOK	=>	TRUE
						);
	END LOOP;

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_ParseBasic;

----------------------------------------------------------
--	UT_ParseSimple (private)
--
PROCEDURE UT_ParseSimple
IS
	JSONSource	CONSTANT	VARCHAR2(32767)		:=	'{
    "id": 2,
    "name": {
        "first": "Jon",
        "middle": "",
        "last": "Doe"
    },
    "age": 40,
    "active": true,
    "email": [
       	"jon.doe@gmail.com",
        "j.doe@gmail.com"
    ]
}';

	aObject					json_object			:=	json_object();

	aResult					CLOB				:=	empty_clob();
	aParsed					CLOB				:=	empty_clob();

	FUNCTION createObject RETURN json_object
	IS
		aPerson	json_object	:=	json_object();
		aName	json_object	:=	json_object();
		aEmails	json_array	:=	json_array();
	BEGIN
		aName.put('first', 'Jon');
		aName.put('middle', '');
		aName.put('last', 'Doe');
		aEmails.append('jon.doe@gmail.com');
		aEmails.append('j.doe@gmail.com');
		aPerson.put('id', 2);
		aPerson.put('name', aName);
		aPerson.put('age', 40);
		aPerson.put('active', TRUE);
		aPerson.put('email', aEmails.to_json_value());
		RETURN aPerson;
	END createObject;
BEGIN
	UT_util.module('UT_ParseSimple');

	--	allocate clob
	dbms_lob.createtemporary(aResult, TRUE);
	dbms_lob.createtemporary(aParsed, TRUE);

	--	create a person progrmmatically
	aObject := createObject();
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aResult);

	--	parse
	aObject := json_object(JSONSource);
	json_utils.validate(aObject.nodes);

	--	serialize again
	aObject.to_clob(theLobBuf=>aParsed);
	UT_util.eqLOB(	theTitle	=>	'equal',
					theComputed	=>	aParsed,
					theExpected	=>	aResult,
					theNullOK	=>	FALSE
					);

	--	free temporary CLOB
	dbms_lob.freetemporary(aResult);
	dbms_lob.freetemporary(aParsed);
END UT_ParseSimple;

----------------------------------------------------------
--	UT_ParseComplex (private)
--
PROCEDURE UT_ParseComplex
IS
	JSONSource	CONSTANT	VARCHAR2(32767)		:=	'{
    "layout": "layout1",
    "data": [
        {
            "id": 1,
            "column": "first",
            "metadata": {}
        },
        {
            "id": 2,
            "column": "second",
            "metadata": {}
        },
        {
            "id": 3,
            "column": "first",
            "metadata": {
                "url": "http://google.com",
                "height": "200px"
            }
        }
    ]
}';

	JSONResult	CONSTANT	VARCHAR2(32767)		:=	'{"layout":"layout1","data":[{"id":1,"column":"first","metadata":{}},{"id":2,"column":"second","metadata":{}},{"id":3,"column":"first","metadata":{"url":"http://google.com","height":"200px"}}]}';

	aObject					json_object			:=	json_object();

	aLob					CLOB				:=	empty_clob();

BEGIN
	UT_util.module('UT_ParseComplex');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	parse
	aObject := json_object(JSONSource);
	json_utils.validate(aObject.nodes);

	--	serialize again
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'equal',
					theComputed	=>	aLob,
					theExpected	=>	JSONResult,
					theNullOK	=>	FALSE
					);

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_ParseComplex;

----------------------------------------------------------
--	UT_ParseAndDestruct (private)
--
PROCEDURE UT_ParseAndDestruct
IS
	JSONSource	CONSTANT	VARCHAR2(32767)		:=	'{
    "layout": "layout1",
    "data": [
        {
            "id": 1,
            "column": "first",
            "metadata": {}
        },
        {
            "id": 2,
            "column": "second",
            "metadata": {}
        },
        {
            "id": 3,
            "column": "first",
            "metadata": {
                "url": "http://google.com",
                "height": "200px"
            }
        }
    ]
}';

	aMainObject				json_object			:=	json_object();
	aDataArray				json_array			:=	json_array();
	aDataObject				json_object			:=	json_object();
	aMetaObject				json_object			:=	json_object();
	aMetaKeys				json_keys;

	aLob					CLOB				:=	empty_clob();

	aID						NUMBER;

	i						NUMBER;
	j						NUMBER;
BEGIN
	UT_util.module('UT_ParseAndDestruct');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	parse
	aMainObject := json_object(JSONSource);
	json_utils.validate(aMainObject.nodes);
	aMainObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'aMainObject',
					theComputed	=>	aLob,
					theExpected	=>	'{"layout":"layout1","data":[{"id":1,"column":"first","metadata":{}},{"id":2,"column":"second","metadata":{}},{"id":3,"column":"first","metadata":{"url":"http://google.com","height":"200px"}}]}',
					theNullOK	=>	TRUE
					);

	--	tests
	UT_util.eq(	theTitle	=>	'layout',
				theComputed	=>	aMainObject.get('layout').get_string(),
				theExpected	=>	'layout1',
				theNullOK	=>	FALSE
				);

	aDataArray := json_array(aMainObject.get('data'));
	json_utils.validate(aDataArray.nodes);
	aDataArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'aDataArray',
					theComputed	=>	aLob,
					theExpected	=>	'[{"id":1,"column":"first","metadata":{}},{"id":2,"column":"second","metadata":{}},{"id":3,"column":"first","metadata":{"url":"http://google.com","height":"200px"}}]',
					theNullOK	=>	TRUE
					);

	FOR i IN 1 .. aDataArray.COUNT LOOP
		aDataObject := json_object(aDataArray.get(i));
		json_utils.validate(aDataObject.nodes);
		aDataObject.to_clob(theLobBuf=>aLob);

		aID := aDataObject.get('id').get_number();
		UT_util.eq(	theTitle	=>	'id',
					theComputed	=>	aID,
					theExpected	=>	i,
					theNullOK	=>	TRUE
					);

		UT_util.eq(	theTitle	=>	'column',
					theComputed	=>	aDataObject.get('column').get_string(),
					theExpected	=>	CASE i WHEN 2 THEN 'second' ELSE 'first' END,
					theNullOK	=>	TRUE
					);

		aMetaObject := json_object(aDataObject.get('metadata'));
		json_utils.validate(aMetaObject.nodes);
		aMetaObject.to_clob(theLobBuf=>aLob);
		aMetaKeys := aMetaObject.get_keys();

		IF (aID IN (1, 2)) THEN
			UT_util.eq(	theTitle	=>	'id#'||aID||'(count)',
						theComputed	=>	aMetaKeys.COUNT,
						theExpected	=>	0,
						theNullOK	=>	TRUE
						);
		ELSIF (aID = 3) THEN
			UT_util.eq(	theTitle	=>	'id#'||aID||'(count)',
						theComputed	=>	aMetaKeys.COUNT,
						theExpected	=>	2,
						theNullOK	=>	TRUE
						);
			FOR j IN 1 .. aMetaKeys.COUNT LOOP
				UT_util.ok('id#'||aID||'(keys)', (aMetaKeys(j) IN ('url', 'height')));
			END LOOP;
			UT_util.eq(	theTitle	=>	'id#'||aID||'(url)',
						theComputed	=>	aMetaObject.get('url').get_string(),
						theExpected	=>	'http://google.com',
						theNullOK	=>	TRUE
						);
			UT_util.eq(	theTitle	=>	'id#'||aID||'(height)',
						theComputed	=>	aMetaObject.get('height').get_string(),
						theExpected	=>	'200px',
						theNullOK	=>	TRUE
						);
		ELSE
			RAISE VALUE_ERROR;
		END IF;
				
	END LOOP;

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_ParseAndDestruct;

----------------------------------------------------------
--	UT_Debug (private)
--
PROCEDURE UT_Debug
IS
	aObject			json_object	:=	json_object();

	aLob			CLOB		:=	empty_clob();
BEGIN
	UT_util.module('UT_Debug');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	create object
	aObject.put('p1', 'v1');
	aObject.put('p2', 47.11);
	aObject.put('p3', SYSDATE);
	aObject.put('p4', TRUE);
	aObject.put('p5');
	json_utils.validate(aObject.nodes);
	json_debug.output(aObject.nodes);

	--	free temporary CLOB
	dbms_lob.freetemporary(aLob);
END UT_Debug;

----------------------------------------------------------
--	Run unit tests
--
PROCEDURE run
IS
BEGIN
	UT_escape;
	UT_Nodes;
	UT_getter;
	UT_Object;
	UT_Array;
	UT_DeepRecursion;
	UT_ComplexObject;
	UT_BigObject;
	UT_ParseBasic;
	UT_ParseSimple;
	UT_ParseComplex;
	UT_ParseAndDestruct;
	UT_Debug;
END run;

----------------------------------------------------------
--	Prepare unit test
--
PROCEDURE prepare
IS
BEGIN
	NULL;
END prepare;

----------------------------------------------------------
--	Cleanup unit test
--
PROCEDURE cleanup
IS
BEGIN
	NULL;
END cleanup;

END json_UT;
/
