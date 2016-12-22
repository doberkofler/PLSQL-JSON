CREATE OR REPLACE
PACKAGE BODY json_UT IS

--	$Id: json_ut.pkb 49652 2016-12-08 18:17:30Z doberkofler $

----------------------------------------------------------
--	PRIVATE TYPES
----------------------------------------------------------

----------------------------------------------------------
--	LOCAL MODULES
----------------------------------------------------------

PROCEDURE checkNode(theTitle IN VARCHAR2 DEFAULT NULL, theNodes IN json_nodes, theNodeID IN NUMBER, theType IN VARCHAR2, theName IN VARCHAR2 DEFAULT NULL, theString IN VARCHAR2 DEFAULT NULL, theNumber IN NUMBER DEFAULT NULL, theDate IN DATE DEFAULT NULL, theParent IN NUMBER DEFAULT NULL, theNext IN NUMBER DEFAULT NULL, theSub IN NUMBER DEFAULT NULL);
PROCEDURE getComplexObject(theJsonObject IN OUT NOCOPY json_object, theJsonString IN OUT NOCOPY CLOB);
PROCEDURE clearLob(theLob IN OUT NOCOPY CLOB);
PROCEDURE setLob(theLob IN OUT NOCOPY CLOB, theValue IN VARCHAR2);
PROCEDURE fillLob(theLob IN OUT NOCOPY CLOB);
FUNCTION toJSON(theDate IN DATE) RETURN VARCHAR2;

----------------------------------------------------------
--	GLOBAL MODULES
----------------------------------------------------------

----------------------------------------------------------
--	test the convertion of simple values (private)
--
PROCEDURE UT_Values
IS
	TYPE TestValueType IS RECORD (
		typ		VARCHAR2(1),		--	0, S, N, D, B
		str		VARCHAR2(2000),
		num		NUMBER,
		dat		DATE,
		bln		BOOLEAN,
		result	VARCHAR2(32767)
	);
	TYPE TestValueList IS TABLE OF TestValueType INDEX BY BINARY_INTEGER;

	aList			TestValueList;
	
	aObject			json_object	:=	json_object();

	aLob			CLOB		:=	empty_clob();

	THIS_DATE		DATE		:=	TO_DATE('19990101', 'YYYYMMDD');

	PROCEDURE add(typ IN VARCHAR2, str IN VARCHAR2 DEFAULT NULL, num IN NUMBER DEFAULT NULL, dat IN DATE DEFAULT NULL, bln IN BOOLEAN DEFAULT NULL, result IN VARCHAR2)
	IS
		c	BINARY_INTEGER	:=	aList.COUNT + 1;
	BEGIN
		aList(c).typ	:= typ;
		aList(c).str	:= str;
		aList(c).num	:= num;
		aList(c).dat	:= dat;
		aList(c).bln	:= bln;
		aList(c).result	:= result;
	END add;
BEGIN
	UT_util.module('UT_Values');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--	test data
	add(typ=>'0', 																	result=>'{"value":null}');
	add(typ=>'S', str=>NULL,														result=>'{"value":""}');
	add(typ=>'S', str=>'',															result=>'{"value":""}');
	add(typ=>'S', str=>'a',															result=>'{"value":"a"}');
	add(typ=>'S', str=>CHR(8)||CHR(9)||CHR(10)||CHR(13)||CHR(14)||CHR(34)||CHR(92),	result=>'{"value":"\b\t\n\f\r\"\\"}');
	add(typ=>'S', str=>CHR(1)||CHR(2)||CHR(30)||CHR(31),							result=>'{"value":"\u0001\u0002\u001E\u001F"}');
	add(typ=>'N', num=>0,															result=>'{"value":0}');
	add(typ=>'N', num=>-1,															result=>'{"value":-1}');
	add(typ=>'N', num=>1,															result=>'{"value":1}');
	add(typ=>'N', num=>0.1,															result=>'{"value":0.1}');
	add(typ=>'N', num=>0.001,														result=>'{"value":0.001}');
	add(typ=>'N', num=>-0.1,														result=>'{"value":-0.1}');
	add(typ=>'N', num=>-0.001,														result=>'{"value":-0.001}');
	add(typ=>'N', num=>99E10,														result=>'{"value":990000000000}');
	add(typ=>'N', num=>-99E10,														result=>'{"value":-990000000000}');
	add(typ=>'N', num=>99E15,														result=>'{"value":99000000000000000}');
	add(typ=>'N', num=>-99E15,														result=>'{"value":-99000000000000000}');
	add(typ=>'D', dat=>THIS_DATE,													result=>'{"value":"'||toJSON(THIS_DATE)||'"}');
	add(typ=>'D', dat=>THIS_DATE + 1,												result=>'{"value":"'||toJSON(THIS_DATE + 1)||'"}');
	add(typ=>'B', bln=>FALSE,														result=>'{"value":false}');
	add(typ=>'B', bln=>TRUE,														result=>'{"value":true}');

	--	check JSON string
	FOR i IN 1 .. aList.COUNT LOOP
		aObject := json_object();
		
		CASE aList(i).typ
		WHEN '0' THEN
			aObject.put('value');
		WHEN 'S' THEN
			aObject.put('value', aList(i).str);
		WHEN 'N' THEN
			aObject.put('value', aList(i).num);
		WHEN 'D' THEN
			aObject.put('value', aList(i).dat);
		WHEN 'B' THEN
			aObject.put('value', aList(i).bln);
		END CASE;

		aObject.to_clob(theLobBuf=>aLob);
		
		UT_util.eqLOB(	theTitle	=>	'#'||i,
						theComputed	=>	aLob,
						theExpected	=>	TO_CLOB(aList(i).result),
						theNullOK	=>	TRUE
						);
	END LOOP;

	--	cleanup
	dbms_lob.freetemporary(aLob);
END UT_Values;

----------------------------------------------------------
--	test the convertion of CLOB values (private)
--
PROCEDURE UT_LobValues
IS
	aValue		CLOB		:=	EMPTY_CLOB();
	aOutput		CLOB		:=	EMPTY_CLOB();
	aExpected	CLOB		:=	EMPTY_CLOB();
	aObj		json_object	:=	json_object();
BEGIN
	UT_util.module('UT_LobValues');

	--allocate clob
	dbms_lob.createtemporary(lob_loc=>aValue, cache=>TRUE, dur=>dbms_lob.session);
	dbms_lob.createtemporary(lob_loc=>aOutput, cache=>TRUE, dur=>dbms_lob.session);
	dbms_lob.createtemporary(lob_loc=>aExpected, cache=>TRUE, dur=>dbms_lob.session);

	-- EMPTY_CLOB()
	aObj := json_object();
	aObj.put('value', EMPTY_CLOB());
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":""}'));
	UT_util.eqLOB(theTitle=>'1: EMPTY_CLOB()', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	-- empty CLOB
	aObj := json_object();
	setLob(aValue, '');
	aObj.put('value', aValue);
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":""}'));
	UT_util.eqLOB(theTitle=>'2: NULL', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	-- #
	aObj := json_object();
	setLob(aValue, '#');
	aObj.put('value', aValue);
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":"#"}'));
	UT_util.eqLOB(theTitle=>'3: #', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	-- special characters
	aObj := json_object();
	setLob(aValue, CHR(8)||CHR(9)||CHR(10)||CHR(13)||CHR(14)||CHR(34)||CHR(92));
	aObj.put('value', aValue);
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":"\b\t\n\f\r\"\\"}'));
	UT_util.eqLOB(theTitle=>'4: \b\t\n\f\r\"\\', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	-- hex
	aObj := json_object();
	clearLob(theLob=>aValue);
	setLob(aValue, CHR(1)||CHR(2)||CHR(30)||CHR(31));
	aObj.put('value', aValue);
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":"\u0001\u0002\u001E\u001F"}'));
	UT_util.eqLOB(theTitle=>'5: \u0001\u0002\u001E\u001F', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	-- ##########
	aObj := json_object();
	setLob(aValue, '##########');
	aObj.put('value', aValue);
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":"##########"}'));
	UT_util.eqLOB(theTitle=>'6: ##########', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	-- 32767 * 10 x #
	aObj := json_object();
	fillLob(theLob=>aValue); -- 32767 * 2
	aObj.put('value', aValue);
	aObj.to_clob(theLobBuf=>aOutput);
	clearLob(theLob=>aExpected);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('{"value":"'));
	dbms_lob.append(dest_lob=>aExpected, src_lob=>aValue);
	dbms_lob.append(dest_lob=>aExpected, src_lob=>TO_CLOB('"}'));
	UT_util.eqLOB(theTitle=>'7: 32767*10...#', theComputed=>aOutput, theExpected=>aExpected, theNullOK=>TRUE);

	--	cleanup
	dbms_lob.freetemporary(lob_loc=>aValue);
	dbms_lob.freetemporary(lob_loc=>aOutput);
	dbms_lob.freetemporary(lob_loc=>aExpected);
END UT_LobValues;

----------------------------------------------------------
--	check the internal representation using nodes
--
PROCEDURE UT_Nodes
IS
	aObject1		json_object		:=	json_object();
	aArray1			json_array		:=	json_array();
	aObject2		json_object		:=	json_object();
	aArray2			json_array		:=	json_array();
	aLob			CLOB			:=	empty_clob();
	aTitle			VARCHAR2(80);
BEGIN
	UT_util.module('UT_Nodes');

	--	allocate clob
	dbms_lob.createtemporary(aLob, TRUE);

	--
	--	aArray2
	--
	aArray2.append('a1');
	aArray2.append(8.11);
	json_utils.validate(aArray2.nodes);

	aTitle := 'aArray2';
	aArray2.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle||': json-string',
					theComputed	=>	aLob,
					theExpected	=>	'["a1",8.11]',
					theNullOK	=>	TRUE
					);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>2, theComputed=>aArray2.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>2, theComputed=>aArray2.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aArray2.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>NULL, theString=>'a1');
		checkNode(			theTitle=>aTitle,	theNodes=>aArray2.nodes, theNodeID=>2,		theType=>'N', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>NULL, theNumber=>8.11);

	--
	--	aObject2
	--
	aObject2.put('p1', aArray2.to_json_value());
	aObject2.put('p2', aArray2.to_json_value());
	json_utils.validate(aObject2.nodes);

	aTitle := 'aObject2';
	aObject2.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle||': json-string',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":["a1",8.11],"p2":["a1",8.11]}',
					theNullOK	=>	TRUE
					);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>6, theComputed=>aObject2.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>4, theComputed=>aObject2.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject2.nodes, theNodeID=>1,		theType=>'A', theSub=>2,	theParent=>NULL,	theNext=>4,			theName=>'p1');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject2.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL,	theParent=>1,		theNext=>3,			theName=>NULL, theString=>'a1');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject2.nodes, theNodeID=>3,		theType=>'N', theSub=>NULL,	theParent=>1,		theNext=>NULL,		theName=>NULL, theNumber=>8.11);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject2.nodes, theNodeID=>4,		theType=>'A', theSub=>5,	theParent=>NULL,	theNext=>NULL,		theName=>'p2');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject2.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL,	theParent=>4,		theNext=>6,			theName=>NULL, theString=>'a1');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject2.nodes, theNodeID=>6,		theType=>'N', theSub=>NULL,	theParent=>4,		theNext=>NULL,		theName=>NULL, theNumber=>8.11);

	--
	--	aArray1
	--
	aArray1.append(aObject2);
	aArray1.append(aObject2);
	json_utils.validate(aArray1.nodes);

	aTitle := 'aArray1';
	aArray1.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle||': json-string',
					theComputed	=>	aLob,
					theExpected	=>	'[{"p1":["a1",8.11],"p2":["a1",8.11]},{"p1":["a1",8.11],"p2":["a1",8.11]}]',
					theNullOK	=>	FALSE
					);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>14, theComputed=>aArray1.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>8, theComputed=>aArray1.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>1,		theType=>'O', theSub=>2,	theParent=>NULL,	theNext=>8,		theName=>NULL);
		checkNode(			theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>2,		theType=>'A', theSub=>3,	theParent=>1,		theNext=>5,		theName=>'p1');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL,	theParent=>2,		theNext=>4,		theName=>NULL,		theString=>'a1');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>4,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
		checkNode(			theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>5,		theType=>'A', theSub=>6,	theParent=>1,		theNext=>NULL,	theName=>'p2');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL,	theParent=>5,		theNext=>7,		theName=>NULL,		theString=>'a1');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>7,		theType=>'N', theSub=>NULL,	theParent=>5,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
		checkNode(			theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>8,		theType=>'O', theSub=>9,	theParent=>NULL,	theNext=>NULL,	theName=>NULL);
		checkNode(			theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>9,		theType=>'A', theSub=>10,	theParent=>8,		theNext=>12,	theName=>'p1');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>10,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>11,	theName=>NULL,		theString=>'a1');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>11,		theType=>'N', theSub=>NULL, theParent=>9,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
		checkNode(			theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>12,		theType=>'A', theSub=>13,	theParent=>8,		theNext=>NULL,	theName=>'p2');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>13,		theType=>'S', theSub=>NULL,	theParent=>12,		theNext=>14,	theName=>NULL,		theString=>'a1');
			checkNode(		theTitle=>aTitle,	theNodes=>aArray1.nodes, theNodeID=>14,		theType=>'N', theSub=>NULL,	theParent=>12,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);

	--
	--	aObject1
	--
	aObject1.put('data', aArray1.to_json_value());
	json_utils.validate(aObject1.nodes);

	aTitle := 'aObject1';
	aObject1.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle||': json-string',
					theComputed	=>	aLob,
					theExpected	=>	'{"data":[{"p1":["a1",8.11],"p2":["a1",8.11]},{"p1":["a1",8.11],"p2":["a1",8.11]}]}',
					theNullOK	=>	FALSE
					);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>15, theComputed=>aObject1.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>1, theComputed=>aObject1.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>1,		theType=>'A', theSub=>2,	theParent=>NULL,	theNext=>NULL,	theName=>'data');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>2,		theType=>'O', theSub=>3,	theParent=>1,		theNext=>9,		theName=>NULL);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>3,		theType=>'A', theSub=>4,	theParent=>2,		theNext=>6,		theName=>'p1');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>4,		theType=>'S', theSub=>NULL,	theParent=>3,		theNext=>5,		theName=>NULL,		theString=>'a1');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>5,		theType=>'N', theSub=>NULL, theParent=>3,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>6,		theType=>'A', theSub=>7,	theParent=>2,		theNext=>NULL,	theName=>'p2');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL,	theParent=>6,		theNext=>8,		theName=>NULL,		theString=>'a1');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>8,		theType=>'N', theSub=>NULL,	theParent=>6,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
 		checkNode(			theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>9,		theType=>'O', theSub=>10,	theParent=>1,		theNext=>NULL,	theName=>NULL);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>10,	theType=>'A', theSub=>11,	theParent=>9,		theNext=>13,	theName=>'p1');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>11,	theType=>'S', theSub=>NULL,	theParent=>10,		theNext=>12,	theName=>NULL,		theString=>'a1');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>12,	theType=>'N', theSub=>NULL, theParent=>10,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>13,	theType=>'A', theSub=>14,	theParent=>9,		theNext=>NULL,	theName=>'p2');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>14,	theType=>'S', theSub=>NULL,	theParent=>13,		theNext=>15,	theName=>NULL,		theString=>'a1');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject1.nodes, theNodeID=>15,	theType=>'N', theSub=>NULL,	theParent=>13,		theNext=>NULL,	theName=>NULL,		theNumber=>8.11);

	--	cleanup
	dbms_lob.freetemporary(aLob);
END UT_Nodes;

----------------------------------------------------------
--	UT_RemoveNode
--
PROCEDURE UT_RemoveNode
IS
	aJsonObject		json_object				:=	json_object();
	aJsonString		CLOB					:=	empty_clob();

	aObject			json_object				:=	json_object();
	aLob			CLOB					:=	empty_clob();

	aNodeID			BINARY_INTEGER;
	aLastID			BINARY_INTEGER;

	aTitle			VARCHAR2(32767);
BEGIN
	UT_util.module('UT_RemoveNode');

	-- allocate clob
	dbms_lob.createtemporary(aJsonString, TRUE);
	dbms_lob.createtemporary(aLob, TRUE);

	-- construct a complex json object
	getComplexObject(theJsonObject=>aJsonObject, theJsonString=>aJsonString);

	-- create sub object
	aTitle := 'create sub object';
	aObject := aJsonObject;
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>12, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>7, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL, theParent=>NULL,	theNext=>2,			theName=>'fname',	theString=>'john');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'0', theSub=>NULL, theParent=>NULL,	theNext=>3,			theName=>'mname');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL, theParent=>NULL,	theNext=>4,			theName=>'lname',	theString=>'doe');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'A', theSub=>5,	theParent=>NULL,	theNext=>7,			theName=>'email');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL, theParent=>4,		theNext=>6,			theName=>NULL,		theString=>'j.doe@gmail.com');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL, theParent=>4,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'O', theSub=>8,	theParent=>NULL,	theNext=>NULL,		theName=>'address');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'A', theSub=>9,	theParent=>7,		theNext=>10,		theName=>'street');
			checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'S', theSub=>NULL, theParent=>8,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>11,		theName=>'city',	theString=>'los angeles');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>12,		theName=>'state',	theString=>'ca');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	aJsonString,
					theNullOK	=>	TRUE
					);

	aTitle := 'create complex object';
	aObject := json_object();
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p2',	theValue=>aJsonObject);
	aObject.put(theName=>'p3',	theValue=>'v3');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>15, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>15, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'O', theSub=>3,	theParent=>NULL,	theNext=>15,		theName=>'p2');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL, theParent=>2,		theNext=>4,			theName=>'fname',	theString=>'john');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'0', theSub=>NULL, theParent=>2,		theNext=>5,			theName=>'mname');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL, theParent=>2,		theNext=>6,			theName=>'lname',	theString=>'doe');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'A', theSub=>7,	theParent=>2,		theNext=>9,			theName=>'email');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL, theParent=>6,		theNext=>8,			theName=>NULL,		theString=>'j.doe@gmail.com');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'S', theSub=>NULL, theParent=>6,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'O', theSub=>10,	theParent=>2,		theNext=>NULL,		theName=>'address');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'A', theSub=>11,	theParent=>9,		theNext=>12,		theName=>'street');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL, theParent=>10,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>13,		theName=>'city',	theString=>'los angeles');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>13,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>14,		theName=>'state',	theString=>'ca');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>14,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>15,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',		theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":'||aJsonString||',"p3":"v3"}',
					theNullOK	=>	TRUE
					);

	-- get node id of property p3
	aNodeID := json_utils.getNodeIDByName(theNodes=>aObject.nodes, thePropertyName=>'p3');
	UT_util.eq(theTitle=>'get node id of property p3', theExpected=>15, theComputed=>aNodeID, theNullOK=>TRUE);

	-- remove nodes of property p3
	aTitle := 'remove property p3';
	aObject.lastID := json_utils.removeNode(theNodes=>aObject.nodes, theNodeID=>aNodeID);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>14, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>2, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'O', theSub=>3,	theParent=>NULL,	theNext=>NULL,		theName=>'p2');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL, theParent=>2,		theNext=>4,			theName=>'fname',	theString=>'john');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'0', theSub=>NULL, theParent=>2,		theNext=>5,			theName=>'mname');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL, theParent=>2,		theNext=>6,			theName=>'lname',	theString=>'doe');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'A', theSub=>7,	theParent=>2,		theNext=>9,			theName=>'email');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL, theParent=>6,		theNext=>8,			theName=>NULL,		theString=>'j.doe@gmail.com');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'S', theSub=>NULL, theParent=>6,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'O', theSub=>10,	theParent=>2,		theNext=>NULL,		theName=>'address');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'A', theSub=>11,	theParent=>9,		theNext=>12,		theName=>'street');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL, theParent=>10,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>13,		theName=>'city',	theString=>'los angeles');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>13,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>14,		theName=>'state',	theString=>'ca');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>14,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":'||aJsonString||'}',
					theNullOK	=>	TRUE
					);

	-- get node id of property p1
	aNodeID := json_utils.getNodeIDByName(theNodes=>aObject.nodes, thePropertyName=>'p1');
	UT_util.eq(theTitle=>'get node id of property p1', theExpected=>1, theComputed=>aNodeID, theNullOK=>TRUE);

	-- remove nodes of property p1
	aTitle := 'remove property p1';
	aObject.lastID := json_utils.removeNode(theNodes=>aObject.nodes, theNodeID=>aNodeID);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>13, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>1, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'O', theSub=>2,	theParent=>NULL,	theNext=>NULL,		theName=>'p2');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL, theParent=>1,		theNext=>3,			theName=>'fname',	theString=>'john');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'0', theSub=>NULL, theParent=>1,		theNext=>4,			theName=>'mname');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'S', theSub=>NULL, theParent=>1,		theNext=>5,			theName=>'lname',	theString=>'doe');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'A', theSub=>6,	theParent=>1,		theNext=>8,			theName=>'email');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL, theParent=>5,		theNext=>7,			theName=>NULL,		theString=>'j.doe@gmail.com');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL, theParent=>5,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'O', theSub=>9,	theParent=>1,		theNext=>NULL,		theName=>'address');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'A', theSub=>10,	theParent=>8,		theNext=>11,		theName=>'street');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'S', theSub=>NULL, theParent=>9,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL,	theParent=>8,		theNext=>12,		theName=>'city',	theString=>'los angeles');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>8,		theNext=>13,		theName=>'state',	theString=>'ca');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>13,		theType=>'S', theSub=>NULL,	theParent=>8,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p2":'||aJsonString||'}',
					theNullOK	=>	TRUE
					);

	-- remove nodes of property p1
	aTitle := 'remove property p1#2';
	aObject := json_object();
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p2',	theValue=>aJsonObject);
	aObject.put(theName=>'p3',	theValue=>'v3');
	aNodeID := json_utils.getNodeIDByName(theNodes=>aObject.nodes, thePropertyName=>'p1');
	aObject.lastID := json_utils.removeNode(theNodes=>aObject.nodes, theNodeID=>aNodeID);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>14, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>14, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'O', theSub=>2,	theParent=>NULL,	theNext=>14,		theName=>'p2');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL, theParent=>1,		theNext=>3,			theName=>'fname',	theString=>'john');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'0', theSub=>NULL, theParent=>1,		theNext=>4,			theName=>'mname');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'S', theSub=>NULL, theParent=>1,		theNext=>5,			theName=>'lname',	theString=>'doe');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'A', theSub=>6,	theParent=>1,		theNext=>8,			theName=>'email');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL, theParent=>5,		theNext=>7,			theName=>NULL,		theString=>'j.doe@gmail.com');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL, theParent=>5,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'O', theSub=>9,	theParent=>1,		theNext=>NULL,		theName=>'address');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'A', theSub=>10,	theParent=>8,		theNext=>11,		theName=>'street');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'S', theSub=>NULL, theParent=>9,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL,	theParent=>8,		theNext=>12,		theName=>'city',	theString=>'los angeles');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>8,		theNext=>13,		theName=>'state',	theString=>'ca');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>13,		theType=>'S', theSub=>NULL,	theParent=>8,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>14,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',		theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p2":'||aJsonString||',"p3":"v3"}',
					theNullOK	=>	TRUE
					);

	-- remove nodes of property p1
	aTitle := 'remove property p2#2';
	aObject := json_object();
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p2',	theValue=>aJsonObject);
	aObject.put(theName=>'p3',	theValue=>'v3');
	aNodeID := json_utils.getNodeIDByName(theNodes=>aObject.nodes, thePropertyName=>'p2');
	aObject.lastID := json_utils.removeNode(theNodes=>aObject.nodes, theNodeID=>aNodeID);
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>2, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>2, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',		theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p3":"v3"}',
					theNullOK	=>	TRUE
					);

	--	cleanup
	dbms_lob.freetemporary(aJsonString);
	dbms_lob.freetemporary(aLob);
END UT_RemoveNode;

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
	aDate := TO_DATE('20141111 111213', 'YYYYMMDD HH24MISS');
	aObject.put(theName=>'p8',	theValue=>aDate);
	aObject.put(theName=>'p9',	theValue=>FALSE);
	aObject.put(theName=>'p10',	theValue=>TRUE);
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'constants',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":null,"p2":"string","p3":"","p4":0,"p5":-1,"p6":2,"p7":0.14,"p8":"'||toJSON(aDate)||'","p9":false,"p10":true}',
					theNullOK	=>	FALSE
					);

	-- put variables to an object
	aObject := json_object();
	aNumber := NULL;
	aDate := NULL;
	aBoolean := NULL;
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
					theExpected	=>	'{"p1":null,"p2":null,"p3":null,"p4":0,"p5":"'||toJSON(aDate)||'","p6":false}',
					theNullOK	=>	FALSE
					);

	-- do not empty the objects adds parameter and creates an invalid JSON object
	-- (please note that is is done on purpose)
	aObject.put(theName=>'p6', theValue=>'v6');
	json_utils.validate(aObject.nodes);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'add',
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":null,"p2":null,"p3":null,"p4":0,"p5":"'||toJSON(aDate)||'","p6":"v6"}',
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
--	UT_Duplicates (private)
--
PROCEDURE UT_Duplicates
IS
	aJsonObject		json_object				:=	json_object();
	aJsonString		CLOB					:=	empty_clob();
	aObject			json_object				:=	json_object();
	aArray			json_array				:=	json_array();
	aNumber			NUMBER;
	aDate			DATE;
	aBoolean		BOOLEAN;

	aLob			CLOB					:=	empty_clob();

	aTitle			VARCHAR2(32767);

	i				BINARY_INTEGER;
BEGIN
	UT_util.module('UT_Duplicates');

	-- allocate clob
	dbms_lob.createtemporary(aJsonString, TRUE);
	dbms_lob.createtemporary(aLob, TRUE);

	-- construct a complex json object
	getComplexObject(theJsonObject=>aJsonObject, theJsonString=>aJsonString);

	-- empty object
	aTitle := 'empty object';
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>0, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>NULL, theComputed=>aObject.lastID, theNullOK=>TRUE);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'empty',
					theComputed	=>	aLob,
					theExpected	=>	'{}',
					theNullOK	=>	TRUE
					);

	aArray.append(1);
	aArray.append(2);
	aArray.append(3);

	aTitle := 'duplicates#1';
	aObject := json_object();
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p2',	theValue=>'v2');
	aObject.put(theName=>'p3',	theValue=>'v3');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>3, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>3, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',	theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>3,			theName=>'p2',	theString=>'v2');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',	theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":"v2","p3":"v3"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#2';
	aObject.put(theName=>'p1',	theValue=>'v1!');
	aObject.put(theName=>'p3',	theValue=>'v3!');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>3, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>3, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p2',	theString=>'v2');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>3,			theName=>'p1',	theString=>'v1!');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',	theString=>'v3!');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p2":"v2","p1":"v1!","p3":"v3!"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#3';
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p3',	theValue=>'v3');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>3, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>3, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p2',	theString=>'v2');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>3,			theName=>'p1',	theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',	theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p2":"v2","p1":"v1","p3":"v3"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#4';
	aObject := json_object();
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p2',	theValue=>'v2');
	aObject.put(theName=>'p2',	theValue=>aArray.to_json_value());
	aObject.put(theName=>'p3',	theValue=>'v3');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>6, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>6, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'A', theSub=>3,	theParent=>NULL,	theNext=>6,			theName=>'p2');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>4,			theName=>NULL,		theNumber=>1);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>5,			theName=>NULL,		theNumber=>2);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>NULL,		theName=>NULL,		theNumber=>3);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',		theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":[1,2,3],"p3":"v3"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#5';
	aObject.put(theName=>'p3',	theValue=>aArray.to_json_value());
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>9, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>6, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'A', theSub=>3,	theParent=>NULL,	theNext=>6,			theName=>'p2');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>4,			theName=>NULL,		theNumber=>1);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>5,			theName=>NULL,		theNumber=>2);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>NULL,		theName=>NULL,		theNumber=>3);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'A', theSub=>7,	theParent=>NULL,	theNext=>NULL,		theName=>'p3');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'N', theSub=>NULL, theParent=>6,		theNext=>8,			theName=>NULL,		theNumber=>1);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'N', theSub=>NULL, theParent=>6,		theNext=>9,			theName=>NULL,		theNumber=>2);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'N', theSub=>NULL, theParent=>6,		theNext=>NULL,		theName=>NULL,		theNumber=>3);
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":[1,2,3],"p3":[1,2,3]}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#6';
	aObject.put(theName=>'p3',	theValue=>'v3!');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>6, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>6, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'A', theSub=>3,	theParent=>NULL,	theNext=>6,			theName=>'p2');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>4,			theName=>NULL,		theNumber=>1);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>5,			theName=>NULL,		theNumber=>2);
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'N', theSub=>NULL, theParent=>2,		theNext=>NULL,		theName=>NULL,		theNumber=>3);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',		theString=>'v3!');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":[1,2,3],"p3":"v3!"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#7';
	aObject.put(theName=>'p2',	theValue=>'v2!');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>3, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>3, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>3,			theName=>'p3',		theString=>'v3!');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p2',		theString=>'v2!');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p3":"v3!","p2":"v2!"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#8';
	aObject := aJsonObject;
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>12, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>7, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL, theParent=>NULL,	theNext=>2,			theName=>'fname',	theString=>'john');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'0', theSub=>NULL, theParent=>NULL,	theNext=>3,			theName=>'mname');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL, theParent=>NULL,	theNext=>4,			theName=>'lname',	theString=>'doe');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'A', theSub=>5,	theParent=>NULL,	theNext=>7,			theName=>'email');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL, theParent=>4,		theNext=>6,			theName=>NULL,		theString=>'j.doe@gmail.com');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL, theParent=>4,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'O', theSub=>8,	theParent=>NULL,	theNext=>NULL,		theName=>'address');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'A', theSub=>9,	theParent=>7,		theNext=>10,		theName=>'street');
			checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'S', theSub=>NULL, theParent=>8,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>11,		theName=>'city',	theString=>'los angeles');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>12,		theName=>'state',	theString=>'ca');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	aJsonString,
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#9';
	aObject := json_object();
	aObject.put(theName=>'p1',	theValue=>'v1');
	aObject.put(theName=>'p2',	theValue=>aJsonObject);
	aObject.put(theName=>'p3',	theValue=>'v3');
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>15, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>15, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>2,			theName=>'p1',		theString=>'v1');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'O', theSub=>3,	theParent=>NULL,	theNext=>15,		theName=>'p2');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL, theParent=>2,		theNext=>4,			theName=>'fname',	theString=>'john');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'0', theSub=>NULL, theParent=>2,		theNext=>5,			theName=>'mname');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL, theParent=>2,		theNext=>6,			theName=>'lname',	theString=>'doe');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'A', theSub=>7,	theParent=>2,		theNext=>9,			theName=>'email');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'S', theSub=>NULL, theParent=>6,		theNext=>8,			theName=>NULL,		theString=>'j.doe@gmail.com');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'S', theSub=>NULL, theParent=>6,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
		checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'O', theSub=>10,	theParent=>2,		theNext=>NULL,		theName=>'address');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'A', theSub=>11,	theParent=>9,		theNext=>12,		theName=>'street');
				checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL, theParent=>10,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>13,		theName=>'city',	theString=>'los angeles');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>13,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>14,		theName=>'state',	theString=>'ca');
			checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>14,		theType=>'S', theSub=>NULL,	theParent=>9,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	checkNode(				theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>15,		theType=>'S', theSub=>NULL,	theParent=>NULL,	theNext=>NULL,		theName=>'p3',		theString=>'v3');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":'||aJsonString||',"p3":"v3"}',
					theNullOK	=>	TRUE
					);

	aTitle := 'duplicates#10';
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>15, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>15, theComputed=>aObject.lastID, theNullOK=>TRUE);
	aObject.put(theName=>'p3',	theValue=>'v3!');
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p1":"v1","p2":'||aJsonString||',"p3":"v3!"}',
					theNullOK	=>	TRUE
					);

	-- repeat put
	aObject := json_object();
	aObject.put(theName=>'p', theValue=>0);
	i := 0;
	WHILE (i < 1000) LOOP
		i := i + 1;

		aTitle := 'repeat#'||i;
		aObject.put(theName=>'p', theValue=>i);
		UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>1, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
		UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>1, theComputed=>aObject.lastID, theNullOK=>TRUE);
		checkNode(theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1, theType=>'N', theSub=>NULL, theParent=>NULL, theNext=>NULL, theName=>'p', theNumber=>i);
		aObject.to_clob(theLobBuf=>aLob);
		UT_util.eqLOB(	theTitle	=>	aTitle,
						theComputed	=>	aLob,
						theExpected	=>	'{"p":'||i||'}',
						theNullOK	=>	TRUE
						);
	END LOOP;
	aTitle := 'repeat#done';
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>1, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>1, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1, theType=>'N', theSub=>NULL, theParent=>NULL, theNext=>NULL, theName=>'p', theNumber=>i);
	UT_util.eqLOB(	theTitle	=>	aTitle,
					theComputed	=>	aLob,
					theExpected	=>	'{"p":'||i||'}',
					theNullOK	=>	TRUE
					);

	--	cleanup
	dbms_lob.freetemporary(aJsonString);
	dbms_lob.freetemporary(aLob);
END UT_Duplicates;

----------------------------------------------------------
--	UT_Array (private)
--
PROCEDURE UT_Array
IS
	aObject			json_object	:=	json_object();
	aArray			json_array	:=	json_array();
	aArray2			json_array	:=	json_array();

	aLob			CLOB		:=	empty_clob();

	aDate			DATE;
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
	aDate := TO_DATE('20141111 111213', 'YYYYMMDD HH24MISS');
	aArray.append(aDate);
	aArray.append(FALSE);
	aArray.append(aObject);
	json_utils.validate(aArray.nodes);
	aArray.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'values',
					theComputed	=>	aLob,
					theExpected	=>	'[null,"string",47.11,"'||toJSON(aDate)||'",false,{}]',
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
	aJsonObject		json_object				:=	json_object();
	aJsonString		CLOB					:=	empty_clob();

	aObject			json_object				:=	json_object();
	aLob			CLOB					:=	empty_clob();

	aTitle			VARCHAR2(32767)			:=	'parsed nodes';
BEGIN
	UT_util.module('UT_ParseComplex');

	-- allocate clob
	dbms_lob.createtemporary(aJsonString, TRUE);
	dbms_lob.createtemporary(aLob, TRUE);

	-- construct a complex json object
	getComplexObject(theJsonObject=>aJsonObject, theJsonString=>aJsonString);

	-- convert json object to string
	aJsonObject.to_clob(theLobBuf=>aLob);
	aJsonObject := json_object();

	-- parse json string
	aObject := json_object(aLob);
	json_utils.validate(aObject.nodes);

	-- validate nodes in parse object
	UT_util.eq(theTitle=>aTitle||': COUNT', theExpected=>12, theComputed=>aObject.nodes.COUNT, theNullOK=>TRUE);

	/*

		WHEN PARSING A COMPLEX OBJECT, THE "PAR" PROPERTIES ARE NOT (YET) FILLED CORRECTLY FOR OBJECT NODES!!!

	UT_util.eq(theTitle=>aTitle||': lastID', theExpected=>7, theComputed=>aObject.lastID, theNullOK=>TRUE);
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>1,		theType=>'S', theSub=>NULL, theParent=>NULL,	theNext=>2,			theName=>'fname',	theString=>'john');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>2,		theType=>'0', theSub=>NULL, theParent=>NULL,	theNext=>3,			theName=>'mname');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>3,		theType=>'S', theSub=>NULL, theParent=>NULL,	theNext=>4,			theName=>'lname',	theString=>'doe');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>4,		theType=>'A', theSub=>5,	theParent=>NULL,	theNext=>7,			theName=>'email');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>5,		theType=>'S', theSub=>NULL, theParent=>4,		theNext=>6,			theName=>NULL,		theString=>'j.doe@gmail.com');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>6,		theType=>'S', theSub=>NULL, theParent=>4,		theNext=>NULL,		theName=>NULL,		theString=>'john.doe@gmail.com');
	checkNode(			theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>7,		theType=>'O', theSub=>8,	theParent=>NULL,	theNext=>NULL,		theName=>'address');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>8,		theType=>'A', theSub=>9,	theParent=>7,		theNext=>10,		theName=>'street');
			checkNode(	theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>9,		theType=>'S', theSub=>NULL, theParent=>8,		theNext=>NULL,		theName=>NULL,		theString=>'n. russmore av.');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>10,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>11,		theName=>'city',	theString=>'los angeles');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>11,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>12,		theName=>'state',	theString=>'ca');
		checkNode(		theTitle=>aTitle,	theNodes=>aObject.nodes, theNodeID=>12,		theType=>'S', theSub=>NULL,	theParent=>7,		theNext=>NULL,		theName=>'zip',		theString=>'90004');
	*/

	-- compare strings
	aObject.to_clob(theLobBuf=>aLob);
	UT_util.eqLOB(	theTitle	=>	'equal',
					theComputed	=>	aLob,
					theExpected	=>	aJsonString,
					theNullOK	=>	FALSE
					);

	-- free temporary CLOB
	dbms_lob.freetemporary(aJsonString);
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

	json_debug.output(aMainObject);
	json_debug.output(aMainObject.get('layout'));

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
--	getJSON
--
PROCEDURE getJSON(theCount IN NUMBER)
IS
	aObject			json_object	:=	json_object();
	aArray			json_array	:=	json_array();
BEGIN
	UT_util.module('getJSON');

	--	create subobject
	aObject.put('string', 'this is a string value');
	aObject.put('number', 47.11);
	aObject.put('boolean', TRUE);

	--	create object
	FOR i IN 1 .. theCount LOOP
		aArray.append(aObject);
	END LOOP;

	--	output array
	aArray.htp();
END getJSON;

----------------------------------------------------------
--	checkNode (private) 
--
PROCEDURE checkNode(theTitle IN VARCHAR2 DEFAULT NULL, theNodes IN json_nodes, theNodeID IN NUMBER, theType IN VARCHAR2, theName IN VARCHAR2 DEFAULT NULL, theString IN VARCHAR2 DEFAULT NULL, theNumber IN NUMBER DEFAULT NULL, theDate IN DATE DEFAULT NULL, theParent IN NUMBER DEFAULT NULL, theNext IN NUMBER DEFAULT NULL, theSub IN NUMBER DEFAULT NULL)
IS
	aTitle	VARCHAR2(32767) := '#'||theNodeID;
BEGIN
	IF (theTitle IS NOT NULL) THEN
		aTitle := theTitle||': '||aTitle;
	END IF;

	UT_util.ok(theTitle=>aTitle||'(nodid='||theNodeID||')', theValue=>theNodeID >= 1 AND theNodeID <= theNodes.COUNT);

	UT_util.eq(theTitle=>aTitle||'(type)',		theExpected=>theType,	theComputed=>theNodes(theNodeID).typ, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(name)',		theExpected=>theName,	theComputed=>theNodes(theNodeID).nam, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(string)',	theExpected=>theString,	theComputed=>theNodes(theNodeID).str, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(number)',	theExpected=>theNumber,	theComputed=>theNodes(theNodeID).num, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(date)',		theExpected=>theDate,	theComputed=>theNodes(theNodeID).dat, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(parent)',	theExpected=>theParent,	theComputed=>theNodes(theNodeID).par, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(next)',		theExpected=>theNext,	theComputed=>theNodes(theNodeID).nex, theNullOK=>TRUE);
	UT_util.eq(theTitle=>aTitle||'(sub)',		theExpected=>theSub,	theComputed=>theNodes(theNodeID).sub, theNullOK=>TRUE);
END checkNode;

----------------------------------------------------------
--	getComplexObject (private)
--
PROCEDURE getComplexObject(theJsonObject IN OUT NOCOPY json_object, theJsonString IN OUT NOCOPY CLOB)
IS
	aObj	json_object	:=	json_object();
	aArr	json_array	:=	json_array();
BEGIN
	-- clean
	theJsonObject := json_object();

	-- create object
	theJsonObject.put('fname', 'john');
	theJsonObject.put('mname');
	theJsonObject.put('lname', 'doe');
	aArr := json_array();
	aArr.append('j.doe@gmail.com');
	aArr.append('john.doe@gmail.com');
	theJsonObject.put('email', aArr.to_json_value());
	aArr := json_array();
	aArr.append('n. russmore av.');
	aObj := json_object();
	aObj.put('street', aArr.to_json_value());
	aObj.put('city', 'los angeles');
	aObj.put('state', 'ca');
	aObj.put('zip', '90004');
	theJsonObject.put('address', aObj.to_json_value());

	-- convert to string
	theJsonObject.to_clob(theLobBuf=>theJsonString);
END getComplexObject;

----------------------------------------------------------
--	clearLob (private)
--
PROCEDURE clearLob(theLob IN OUT NOCOPY CLOB)
IS
BEGIN
	IF (dbms_lob.getlength(lob_loc=>theLob) > 0) THEN
		dbms_lob.trim(lob_loc=>theLob, newlen=>0);
	END IF;
END clearLob;

----------------------------------------------------------
--	setLob (private)
--
PROCEDURE setLob(theLob IN OUT NOCOPY CLOB, theValue IN VARCHAR2)
IS
BEGIN
	clearLob(theLob=>theLob);
	IF (theValue IS NOT NULL) THEN
		dbms_lob.append(dest_lob=>theLob, src_lob=>TO_CLOB(theValue));
	END IF;
END setLob;

----------------------------------------------------------
--	fillLob (private)
--
PROCEDURE fillLob(theLob IN OUT NOCOPY CLOB)
IS
	CHUNK CONSTANT CLOB := TO_CLOB(LPAD('#', 32767, '#'));
BEGIN
	clearLob(theLob=>theLob);

	FOR i IN 1 .. 2 LOOP
		dbms_lob.append(dest_lob=>theLob, src_lob=>CHUNK);
	END LOOP;
END fillLob;

----------------------------------------------------------
--	toJSON (private)
--
FUNCTION toJSON(theDate IN DATE) RETURN VARCHAR2
IS
BEGIN
	RETURN TO_CHAR(theDate, 'FXYYYY-MM-DD"T"HH24:MI:SS');
END toJSON;

----------------------------------------------------------
--	Run unit tests
--
PROCEDURE run
IS
BEGIN
	UT_values;
	UT_LobValues;
	UT_Nodes;
	UT_RemoveNode;
	UT_getter;
	UT_Object;
	UT_Duplicates;
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
