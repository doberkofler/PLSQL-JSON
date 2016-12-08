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

----------------------------------------------------------
--	bind (private)
--
PROCEDURE bind(theCursor IN INTEGER, theBinding json_object)
IS
    aKeys	json_keys		:= theBinding.get_keys();
    aKey	VARCHAR2(32767);
    aValue	json_value		:= json_value();
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
--	openCursor
--
FUNCTION openCursor(theSqlStatement VARCHAR2, theBinding json_object DEFAULT NULL_OBJECT) RETURN HandleType
IS
	aHandle	HandleType;
    aStatus	INTEGER;
    aCount	INTEGER;
    aType	INTEGER;
BEGIN
	-- open cursor
	aHandle.cursorID := dbms_sql.open_cursor;

	-- parse statement
	dbms_sql.parse(aHandle.cursorID, theSqlStatement, dbms_sql.native);

	-- bindings
	bind(aHandle.cursorID, theBinding);

	-- describe columns
	dbms_sql.describe_columns(aHandle.cursorID, aCount, aHandle.description);

	-- define columns
	FOR i IN 1 .. aCount LOOP
		aType := aHandle.description(i).col_type;
		IF (aType IN (1, 112)) THEN
			dbms_sql.define_column(aHandle.cursorID, i, aHandle.stringColumn, 4000);
		ELSIF (aType = 2) THEN
			dbms_sql.define_column(aHandle.cursorID, i, aHandle.numberColumn);
		ELSIF (aType = 12) THEN
			dbms_sql.define_column(aHandle.cursorID, i, aHandle.dateColumn);
		END IF;
	END LOOP;

	-- execute statement
	aStatus := dbms_sql.execute(aHandle.cursorID);

	RETURN aHandle;
END openCursor;

----------------------------------------------------------
--	closeCursor
--
PROCEDURE closeCursor(theHandle IN OUT NOCOPY HandleType)
IS
BEGIN
    dbms_sql.close_cursor(theHandle.cursorID);
    theHandle.cursorID := NULL;
    theHandle.description.DELETE;
END closeCursor;

----------------------------------------------------------
--	get
--
FUNCTION get(theSqlStatement VARCHAR2, theBinding json_object DEFAULT NULL_OBJECT, format IN VARCHAR2 DEFAULT FORMAT_TAB) RETURN json_object
IS
	aHandle	HandleType;

	aName	VARCHAR2(32767);
	aNames	json_array		:=	json_array();
	aRowObj	json_object		:=	json_object();
	aRowArr	json_array		:=	json_array();
	aRows	json_array		:=	json_array();
	aObject	json_object		:=	json_object();
BEGIN
	IF (format NOT IN (FORMAT_OBJ, FORMAT_TAB)) THEN
		RAISE VALUE_ERROR;
	END IF;

	-- open
	aHandle := openCursor(theSqlStatement=>theSqlStatement, theBinding=>theBinding);

	-- column names
	IF (format = FORMAT_TAB) THEN
		FOR i IN 1 .. aHandle.description.COUNT LOOP
			IF (aHandle.description(i).col_type in (1, 96)) THEN
				aNames.append(aHandle.description(i).col_name);
			-- number
			ELSIF (aHandle.description(i).col_type = 2) THEN
				aNames.append(aHandle.description(i).col_name);
			-- date
			ELSIF (aHandle.description(i).col_type = 12) THEN
				aNames.append(aHandle.description(i).col_name);
			END IF;
		END LOOP;
	END IF;

	-- process rows
	WHILE (dbms_sql.fetch_rows(aHandle.cursorID) > 0) LOOP
		aRowObj := json_object();
		aRowArr := json_array();

		-- process columns
		FOR i IN 1 .. aHandle.description.COUNT LOOP

			-- column name
			aName := aHandle.description(i).col_name;

			-- string
			IF (aHandle.description(i).col_type in (1, 96)) THEN
				dbms_sql.column_value(aHandle.cursorID, i, aHandle.stringColumn);
				IF (format = FORMAT_OBJ) THEN
					aRowObj.put(aName, aHandle.stringColumn);
				ELSE
					aRowArr.append(aHandle.stringColumn);
				END IF;
			-- number
			ELSIF (aHandle.description(i).col_type = 2) THEN
				dbms_sql.column_value(aHandle.cursorID, i, aHandle.numberColumn);
				IF (format = FORMAT_OBJ) THEN
					aRowObj.put(aName, aHandle.numberColumn);
				ELSE
					aRowArr.append(aHandle.numberColumn);
				END IF;
			-- date
			ELSIF (aHandle.description(i).col_type = 12) THEN
				dbms_sql.column_value(aHandle.cursorID, i, aHandle.dateColumn);
				IF (format = FORMAT_OBJ) THEN
					aRowObj.put(aName, aHandle.dateColumn);
				ELSE
					aRowArr.append(aHandle.dateColumn);
				END IF;
			END IF;

		END LOOP;

		IF (format = FORMAT_OBJ) THEN
			aRows.append(aRowObj);
		ELSE
			aRows.append(aRowArr);
		END IF;
	END LOOP;

	-- close
    closeCursor(aHandle);

	IF (format = FORMAT_OBJ) THEN
	    aObject.put('rows', aRows.to_json_value());
    	RETURN aObject;
	ELSE
	    aObject.put('cols', aNames.to_json_value());
	    aObject.put('rows', aRows.to_json_value());
    	RETURN aObject;
	END IF;
END get;

----------------------------------------------------------
--	Execute sql statement and output a json structure
--
PROCEDURE htp(sqlCmd VARCHAR2, sqlBind IN VARCHAR2 DEFAULT NULL, format IN VARCHAR2 DEFAULT FORMAT_TAB)
IS
	aBinding json_object := json_object();
BEGIN
	-- parse
	aBinding := json_object(TO_CLOB(sqlBind));

	-- process and output
	get(theSqlStatement=>sqlCmd, theBinding=>aBinding, format=>UPPER(format)).htp();
END htp;

END json_sql;
/
