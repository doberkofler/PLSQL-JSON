CREATE OR REPLACE
PACKAGE json_clob
IS

----------------------------------------------------------
--	add_string
--
PROCEDURE add_string(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theValue IN VARCHAR2);

----------------------------------------------------------
--	add_clob
--
PROCEDURE add_clob(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2, theValue IN CLOB);

----------------------------------------------------------
--	erase
--
PROCEDURE erase(theLobBuf IN OUT NOCOPY CLOB);

----------------------------------------------------------
--	flush
--
PROCEDURE flush(theLobBuf IN OUT NOCOPY CLOB, theStrBuf IN OUT NOCOPY VARCHAR2);

END json_clob;
/
