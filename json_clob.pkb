CREATE OR REPLACE
PACKAGE BODY json_clob
IS

----------------------------------------------------------
--	add_string
--
PROCEDURE add_string(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theValue IN VARCHAR2)
IS
BEGIN
	IF (LENGTHB(theValue) > 32767 - LENGTHB(theStrBuf)) THEN
		dbms_lob.append(dest_lob=>theLobBuf, src_lob=>TO_CLOB(theStrBuf));
		theStrBuf := theValue;
	ELSE
		theStrBuf := theStrBuf || theValue;
	END IF;
END add_string;

----------------------------------------------------------
--	add_clob
--
PROCEDURE add_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theValue IN CLOB)
IS
BEGIN
	PRAGMA INLINE (flush, 'YES');
	flush(theLobBuf=>theLobBuf, theStrBuf=>theStrBuf);

	dbms_lob.append(dest_lob=>theLobBuf, src_lob=>theValue);
END add_clob;

----------------------------------------------------------
--	erase
--
PROCEDURE erase(theLobBuf IN OUT NOCOPY CLOB)
IS
BEGIN
	IF (dbms_lob.getlength(lob_loc=>theLobBuf) > 0) THEN
		dbms_lob.trim(lob_loc=>theLobBuf, newlen=>0);
	END IF;
END erase;

----------------------------------------------------------
--	flush
--
PROCEDURE flush(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2)
IS
BEGIN
	IF (LENGTHB(theStrBuf) > 0) THEN
		dbms_lob.append(dest_lob=>theLobBuf, src_lob=>TO_CLOB(theStrBuf));
	END IF;

	theStrBuf := NULL;
END flush;

END json_clob;
/
