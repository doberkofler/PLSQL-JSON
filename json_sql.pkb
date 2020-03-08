CREATE OR REPLACE
PACKAGE BODY json_sql
IS

TYPE HandleType IS RECORD
(
	cursorID		INTEGER,
    description		dbms_sql.desc_tab,
	stringColumn	VARCHAR2(4000),
	numberColumn	NUMBER,
	dateColumn		DATE
);

FUNCTION openCursor(rc IN OUT SYS_REFCURSOR) RETURN HandleType;
FUNCTION openCursor(sqlCmd VARCHAR2, sqlBind jsonObject DEFAULT NULL_OBJECT) RETURN HandleType;
PROCEDURE bind(theCursor IN INTEGER, theBinding jsonObject);
PROCEDURE describeAndDefine(theHandle IN OUT NOCOPY HandleType);
FUNCTION process(theHandle IN OUT NOCOPY HandleType, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN jsonObject;
PROCEDURE closeCursor(theHandle IN OUT NOCOPY HandleType);

----------------------------------------------------------
--	get (SYS_REFCURSOR)
--
FUNCTION get(rc IN OUT SYS_REFCURSOR, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN jsonObject
IS
	aHandle	HandleType;
	aObject	jsonObject		:=	jsonObject();
BEGIN
	-- open cursor
	aHandle := openCursor(rc=>rc);

	-- process cursor
	aObject := process(theHandle=>aHandle, format=>format);

	-- close cursor
    closeCursor(aHandle);

   	RETURN aObject;
END get;

----------------------------------------------------------
--	get
--
FUNCTION get(sqlCmd VARCHAR2, sqlBind jsonObject DEFAULT NULL_OBJECT, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN jsonObject
IS
	aHandle	HandleType;
	aObject	jsonObject		:=	jsonObject();
BEGIN
	-- open cursor
	aHandle := openCursor(sqlCmd=>sqlCmd, sqlBind=>sqlBind);

	-- process cursor
	aObject := process(theHandle=>aHandle, format=>format);

	-- close cursor
    closeCursor(aHandle);

   	RETURN aObject;
END get;

----------------------------------------------------------
--	Execute sql statement and output a json structure
--
PROCEDURE htp(sqlCmd VARCHAR2, sqlBind IN VARCHAR2 DEFAULT NULL, format IN VARCHAR2 DEFAULT FORMAT_TAB)
IS
	aBinding jsonObject := jsonObject();
BEGIN
	-- parse
	IF (sqlBind IS NOT NULL) THEN
		aBinding := jsonObject(TO_CLOB(sqlBind));
	END IF;

	-- process and output
	get(sqlCmd=>sqlCmd, sqlBind=>aBinding, format=>UPPER(format)).htp();
END htp;

----------------------------------------------------------
--	openCursor (private)
--
FUNCTION openCursor(rc IN OUT SYS_REFCURSOR) RETURN HandleType
IS
	aHandle	HandleType;
BEGIN
	-- open cursor
	aHandle.cursorID := dbms_sql.to_cursor_number(rc=>rc);

	-- describe and define columns
	describeAndDefine(theHandle=>aHandle);

	RETURN aHandle;
END openCursor;

----------------------------------------------------------
--	openCursor (private)
--
FUNCTION openCursor(sqlCmd VARCHAR2, sqlBind jsonObject DEFAULT NULL_OBJECT) RETURN HandleType
IS
	aHandle	HandleType;
    aStatus	INTEGER;
BEGIN
	-- open cursor
	aHandle.cursorID := dbms_sql.open_cursor;

	-- parse statement
	dbms_sql.parse(aHandle.cursorID, sqlCmd, dbms_sql.native);

	-- bindings
	bind(aHandle.cursorID, sqlBind);

	-- describe and define columns
	describeAndDefine(theHandle=>aHandle);

	-- execute statement
	aStatus := dbms_sql.execute(aHandle.cursorID);

	RETURN aHandle;
END openCursor;

----------------------------------------------------------
--	bind (private)
--
PROCEDURE bind(theCursor IN INTEGER, theBinding jsonObject)
IS
    aKeys	jsonKeys		:= theBinding.get_keys();
    aKey	VARCHAR2(32767);
    aValue	jsonValue		:= jsonValue();
BEGIN
	FOR i IN 1 .. aKeys.COUNT LOOP
		aKey	:= aKeys(i);
		aValue	:= theBinding.get(aKey);

		IF (aValue.get_type() = 'NUMBER') THEN
			dbms_sql.bind_variable(theCursor, ':'||aKey, aValue.get_number());
		ELSIF (theBinding.get(aKey).get_type() = 'STRING') THEN
			dbms_sql.bind_variable(theCursor, ':'||aKey, aValue.get_string());
		ELSE
			RAISE VALUE_ERROR;
		END IF;
	END LOOP;
END bind;

----------------------------------------------------------
--	describeAndDefine (private)
--
PROCEDURE describeAndDefine(theHandle IN OUT NOCOPY HandleType)
IS
    aCount	INTEGER;
    aType	INTEGER;
BEGIN

	-- describe columns
	dbms_sql.describe_columns(theHandle.cursorID, aCount, theHandle.description);

	-- define columns
	FOR i IN 1 .. aCount LOOP
		aType := theHandle.description(i).col_type;
		IF (aType IN (1, 112)) THEN
			dbms_sql.define_column(theHandle.cursorID, i, theHandle.stringColumn, 4000);
		ELSIF (aType = 2) THEN
			dbms_sql.define_column(theHandle.cursorID, i, theHandle.numberColumn);
		ELSIF (aType = 12) THEN
			dbms_sql.define_column(theHandle.cursorID, i, theHandle.dateColumn);
		END IF;
	END LOOP;
END describeAndDefine;

----------------------------------------------------------
--	process (private)
--
FUNCTION process(theHandle IN OUT NOCOPY HandleType, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN jsonObject
IS
	aName	VARCHAR2(32767);
	aNames	jsonArray		:=	jsonArray();
	aRowObj	jsonObject		:=	jsonObject();
	aRowArr	jsonArray		:=	jsonArray();
	aRows	jsonArray		:=	jsonArray();
	aObject	jsonObject		:=	jsonObject();
BEGIN
	IF (format NOT IN (FORMAT_OBJ, FORMAT_TAB)) THEN
		RAISE VALUE_ERROR;
	END IF;

	-- column names
	IF (format = FORMAT_TAB) THEN
		FOR i IN 1 .. theHandle.description.COUNT LOOP
			IF (theHandle.description(i).col_type in (1, 96)) THEN
				aNames.append(theHandle.description(i).col_name);
			-- number
			ELSIF (theHandle.description(i).col_type = 2) THEN
				aNames.append(theHandle.description(i).col_name);
			-- date
			ELSIF (theHandle.description(i).col_type = 12) THEN
				aNames.append(theHandle.description(i).col_name);
			END IF;
		END LOOP;
	END IF;

	-- process rows
	WHILE (dbms_sql.fetch_rows(theHandle.cursorID) > 0) LOOP
		aRowObj := jsonObject();
		aRowArr := jsonArray();

		-- process columns
		FOR i IN 1 .. theHandle.description.COUNT LOOP

			-- column name
			aName := theHandle.description(i).col_name;

			-- string
			IF (theHandle.description(i).col_type in (1, 96)) THEN
				dbms_sql.column_value(theHandle.cursorID, i, theHandle.stringColumn);
				IF (format = FORMAT_OBJ) THEN
					aRowObj.put(aName, theHandle.stringColumn);
				ELSE
					aRowArr.append(theHandle.stringColumn);
				END IF;
			-- number
			ELSIF (theHandle.description(i).col_type = 2) THEN
				dbms_sql.column_value(theHandle.cursorID, i, theHandle.numberColumn);
				IF (format = FORMAT_OBJ) THEN
					aRowObj.put(aName, theHandle.numberColumn);
				ELSE
					aRowArr.append(theHandle.numberColumn);
				END IF;
			-- date
			ELSIF (theHandle.description(i).col_type = 12) THEN
				dbms_sql.column_value(theHandle.cursorID, i, theHandle.dateColumn);
				IF (format = FORMAT_OBJ) THEN
					aRowObj.put(aName, theHandle.dateColumn);
				ELSE
					aRowArr.append(theHandle.dateColumn);
				END IF;
			END IF;

		END LOOP;

		IF (format = FORMAT_OBJ) THEN
			aRows.append(aRowObj);
		ELSE
			aRows.append(aRowArr);
		END IF;
	END LOOP;

	IF (format = FORMAT_OBJ) THEN
	    aObject.put('rows', aRows.to_jsonValue());
	ELSE
	    aObject.put('cols', aNames.to_jsonValue());
	    aObject.put('rows', aRows.to_jsonValue());
	END IF;

   	RETURN aObject;
END process;

----------------------------------------------------------
--	closeCursor (private)
--
PROCEDURE closeCursor(theHandle IN OUT NOCOPY HandleType)
IS
BEGIN
    IF (dbms_sql.is_open(theHandle.cursorID)) THEN
    	dbms_sql.close_cursor(theHandle.cursorID);
    END IF;
    theHandle.cursorID := NULL;
    theHandle.description.DELETE;
END closeCursor;

END json_sql;
/
