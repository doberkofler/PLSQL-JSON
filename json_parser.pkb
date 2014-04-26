CREATE OR REPLACE
PACKAGE BODY json_parser IS

----------------------------------------------------------
--	PRIVATE EXCEPTIONS
----------------------------------------------------------

----------------------------------------------------------
--	PRIVATE TYPES
----------------------------------------------------------

----------------------------------------------------------
--	PRIVATE CONSTANTS
----------------------------------------------------------

----------------------------------------------------------
--	PRIVATE VARIABLES
----------------------------------------------------------

decimalpoint VARCHAR2(1 CHAR) := '.';

----------------------------------------------------------
-- LOCAL MODULES
----------------------------------------------------------

FUNCTION next_char(indx NUMBER, s IN OUT NOCOPY json_src) RETURN VARCHAR2;
FUNCTION next_char2(indx NUMBER, s IN OUT NOCOPY json_src, amount NUMBER DEFAULT 1) RETURN VARCHAR2;

FUNCTION prepareClob(buf IN CLOB) RETURN json_src;
FUNCTION prepareVARCHAR2(buf IN VARCHAR2) RETURN json_src;
FUNCTION lexer(jsrc IN OUT NOCOPY json_src) RETURN lTokens;

PROCEDURE parseMem(tokens lTokens, indx IN OUT PLS_INTEGER, mem_name VARCHAR2, mem_indx NUMBER, theParentID IN OUT BINARY_INTEGER, theLastID IN OUT BINARY_INTEGER, theNodes IN OUT NOCOPY json_nodes);

----------------------------------------------------------
-- GLOBAL MODULES
----------------------------------------------------------

----------------------------------------------------------
--	updateDecimalPoint (private)
--
PROCEDURE updateDecimalPoint
IS
BEGIN
	SELECT SUBSTR(VALUE, 1, 1) INTO decimalpoint FROM nls_session_parameters WHERE parameter = 'NLS_NUMERIC_CHARACTERS';
END updateDecimalPoint;

----------------------------------------------------------
--	next_char (private)
--	type json_src is record (len number, offset number, src varchar2(10), s_clob clob);
--
FUNCTION next_char(indx NUMBER, s IN OUT NOCOPY json_src) RETURN VARCHAR2
IS
BEGIN
	IF (indx > s.len) THEN
		RETURN NULL;
	END IF;

	-- right offset?
	IF (indx > 4000 + s.offset OR indx < s.offset) THEN
		-- load right offset
		s.offset := indx - (indx MOD 4000);
		s.src := dbms_lob.substr(s.s_clob, 4000, s.offset + 1);
	END IF;

	-- read from s.src
	RETURN substr(s.src, indx - s.offset, 1);
END next_char;

----------------------------------------------------------
--	next_char2 (private)
--
FUNCTION next_char2(indx NUMBER, s IN OUT NOCOPY json_src, amount NUMBER DEFAULT 1) RETURN VARCHAR2
IS
  buf VARCHAR2(32767) := '';
BEGIN
	FOR I IN 1 .. amount LOOP
		buf := buf || next_char(indx-1+i,s);
		END LOOP;
	RETURN buf;
END next_char2;

----------------------------------------------------------
--	prepareClob (private)
--
function prepareClob(buf CLOB) RETURN json_src
IS
	temp json_src;
BEGIN
	temp.s_clob := buf;
	temp.offset := 0;
	temp.src := dbms_lob.substr(buf, 4000, temp.offset + 1);
	temp.len := dbms_lob.getlength(buf);
	RETURN temp;
END prepareClob;

----------------------------------------------------------
--	prepareVarchar2 (private)
--
FUNCTION prepareVarchar2(buf VARCHAR2) RETURN json_src
IS
	temp json_src;
begin
	temp.s_clob := buf;
	temp.offset := 0;
	temp.src := substr(buf, 1, 4000);
	temp.len := length(buf);
	RETURN temp;
END prepareVarchar2;

----------------------------------------------------------
--	debug (private)
--
PROCEDURE debug(text VARCHAR2)
IS
BEGIN
	--dbms_output.put_line(text);
	NULL;
END debug;


--
--	START SCANNER
--	*************


----------------------------------------------------------
--	s_error (private)
--
PROCEDURE s_error(text VARCHAR2, line NUMBER, col NUMBER)
IS
BEGIN
	raise_application_error(-20100, 'JSON Scanner exception @ line: '||line||' column: '||col||' - '||text);
END s_error;

----------------------------------------------------------
--	s_error (private)
--
PROCEDURE s_error(text VARCHAR2, tok rToken)
IS
BEGIN
	raise_application_error(-20100, 'JSON Scanner exception @ line: '||tok.line||' column: '||tok.col||' - '||text);
END s_error;

----------------------------------------------------------
--	mt (private)
--
FUNCTION mt(t VARCHAR2, l PLS_INTEGER, c PLS_INTEGER, d VARCHAR2) RETURN rToken
IS
	token rToken;
BEGIN
	token.type_name := t;
	token.line := l;
	token.col := c;
	token.data := d;
	RETURN token;
END mt;

----------------------------------------------------------
--	lexNumber (private)
--
FUNCTION lexNumber(jsrc IN OUT NOCOPY json_src, tok IN OUT NOCOPY rToken, indx IN OUT NOCOPY PLS_INTEGER) RETURN PLS_INTEGER
IS
	numbuf varchar2(4000) := '';
	buf varchar2(4);
	checkLoop boolean;
BEGIN
  buf := next_char(indx, jsrc);
  if(buf = '-') then numbuf := '-'; indx := indx + 1; end if;
  buf := next_char(indx, jsrc);
  --0 or [1-9]([0-9])*
  if(buf = '0') then
    numbuf := numbuf || '0'; indx := indx + 1;
    buf := next_char(indx, jsrc);
  elsif(buf >= '1' and buf <= '9') then
    numbuf := numbuf || buf; indx := indx + 1;
    --read digits
    buf := next_char(indx, jsrc);
    while(buf >= '0' and buf <= '9') loop
      numbuf := numbuf || buf; indx := indx + 1;
      buf := next_char(indx, jsrc);
    end loop;
  end if;
  --fraction
  if(buf = '.') then
    numbuf := numbuf || buf; indx := indx + 1;
    buf := next_char(indx, jsrc);
    checkLoop := FALSE;
    while(buf >= '0' and buf <= '9') loop
      checkLoop := TRUE;
      numbuf := numbuf || buf; indx := indx + 1;
      buf := next_char(indx, jsrc);
    end loop;
    if(not checkLoop) then
      s_error('Expected: digits in fraction', tok);
    end if;
  end if;
  --exp part
  if(buf in ('e', 'E')) then
    numbuf := numbuf || buf; indx := indx + 1;
    buf := next_char(indx, jsrc);
    if(buf = '+' or buf = '-') then
      numbuf := numbuf || buf; indx := indx + 1;
      buf := next_char(indx, jsrc);
    end if;
    checkLoop := FALSE;
    while(buf >= '0' and buf <= '9') loop
      checkLoop := TRUE;
      numbuf := numbuf || buf; indx := indx + 1;
      buf := next_char(indx, jsrc);
    end loop;
    if(not checkLoop) then
      s_error('Expected: digits in exp', tok);
    end if;
  end if;

  tok.data := numbuf;
  return indx;
END lexNumber;

----------------------------------------------------------
--	lexName (private)
--
-- [a-zA-Z]([a-zA-Z0-9])*
--
FUNCTION lexName(jsrc IN OUT NOCOPY json_src, tok IN OUT NOCOPY rToken, indx IN OUT NOCOPY PLS_INTEGER) RETURN PLS_INTEGER
IS
	varbuf varchar2(32767) := '';
	buf varchar(4);
	num number;
BEGIN
  buf := next_char(indx, jsrc);
  while(REGEXP_LIKE(buf, '^[[:alnum:]\_]$', 'i')) loop
    varbuf := varbuf || buf;
    indx := indx + 1;
    buf := next_char(indx, jsrc);
    if (buf is null) then
      goto retname;
      --debug('Premature string ending');
    end if;
  end loop;
  <<retname>>

  --could check for reserved keywords here

  --debug(varbuf);
  tok.data := varbuf;
  return indx-1;
END lexName;

----------------------------------------------------------
--	updateClob (private)
--
PROCEDURE updateClob(v_extended IN OUT NOCOPY CLOB, v_str VARCHAR2)
IS
BEGIN
	dbms_lob.writeappend(v_extended, LENGTH(v_str), v_str);
END updateClob;

----------------------------------------------------------
--	lexString (private)
--
FUNCTION lexString(jsrc IN OUT NOCOPY json_src, tok IN OUT NOCOPY rToken, indx IN OUT NOCOPY PLS_INTEGER, endChar CHAR) RETURN PLS_INTEGER
IS
	v_extended clob := null; v_count number := 0;
	varbuf varchar2(32767) := '';
	buf varchar(4);
	wrong boolean;
begin
  indx := indx +1;
  buf := next_char(indx, jsrc);
  while(buf != endChar) loop
    --clob control
    if(v_count > 8191) then --crazy oracle error (16383 is the highest working length with unistr - 8192 choosen to be safe)
      if(v_extended is null) then
        v_extended := empty_clob();
        dbms_lob.createtemporary(v_extended, true);
      end if;
      updateClob(v_extended, unistr(varbuf));
      varbuf := ''; v_count := 0;
    end if;
    if(buf = Chr(13) or buf = CHR(9) or buf = CHR(10)) then
      s_error('Control characters not allowed (CHR(9),CHR(10)CHR(13))', tok);
    end if;
    if(buf = '\') then
      --varbuf := varbuf || buf;
      indx := indx + 1;
      buf := next_char(indx, jsrc);
      case
        when buf in ('\') then
          varbuf := varbuf || buf || buf; v_count := v_count + 2;
          indx := indx + 1;
          buf := next_char(indx, jsrc);
        when buf in ('"', '/') then
          varbuf := varbuf || buf; v_count := v_count + 1;
          indx := indx + 1;
          buf := next_char(indx, jsrc);
        when buf = '''' then
          if(json_strict = false) then
            varbuf := varbuf || buf; v_count := v_count + 1;
            indx := indx + 1;
            buf := next_char(indx, jsrc);
          else
            s_error('strictmode - expected: " \ / b f n r t u ', tok);
          end if;
        when buf in ('b', 'f', 'n', 'r', 't') then
          --backspace b = U+0008
          --formfeed  f = U+000C
          --newline   n = U+000A
          --carret    r = U+000D
          --tabulator t = U+0009
          case buf
          when 'b' then varbuf := varbuf || chr(8);
          when 'f' then varbuf := varbuf || chr(13);
          when 'n' then varbuf := varbuf || chr(10);
          when 'r' then varbuf := varbuf || chr(14);
          when 't' then varbuf := varbuf || chr(9);
          end case;
          --varbuf := varbuf || buf;
          v_count := v_count + 1;
          indx := indx + 1;
          buf := next_char(indx, jsrc);
        when buf = 'u' then
          --four hexidecimal chars
          declare
            four varchar2(4);
          begin
            four := next_char2(indx+1, jsrc, 4);
            wrong := FALSE;
            if(upper(substr(four, 1,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
            if(upper(substr(four, 2,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
            if(upper(substr(four, 3,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
            if(upper(substr(four, 4,1)) not in ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','a','b','c','d','e','f')) then wrong := TRUE; end if;
            if(wrong) then
              s_error('expected: " \u([0-9][A-F]){4}', tok);
            end if;
--              varbuf := varbuf || buf || four;
            varbuf := varbuf || '\'||four;--chr(to_number(four,'XXXX'));
             v_count := v_count + 5;
            indx := indx + 5;
            buf := next_char(indx, jsrc);
            end;
        else
          s_error('expected: " \ / b f n r t u ', tok);
      end case;
    else
      varbuf := varbuf || buf; v_count := v_count + 1;
      indx := indx + 1;
      buf := next_char(indx, jsrc);
    end if;
  end loop;

  if (buf is null) then
    s_error('string ending not found', tok);
    --debug('Premature string ending');
  end if;

  --debug(varbuf);
  --dbms_output.put_line(varbuf);
  if(v_extended is not null) then
    updateClob(v_extended, unistr(varbuf));
    tok.data_overflow := v_extended;
    tok.data := dbms_lob.substr(v_extended, 1, 32767);
  else
    tok.data := unistr(varbuf);
  end if;
  return indx;
end lexString;

----------------------------------------------------------
--	lexer (private)
--
--	scanner tokens:
--	'{', '}', ',', ':', '[', ']', STRING, NUMBER, TRUE, FALSE, NULL
--
FUNCTION lexer(jsrc IN OUT NOCOPY json_src) RETURN lTokens
IS
	tokens lTokens;
	indx pls_integer := 1;
	tok_indx pls_integer := 1;
	buf varchar2(4);
	lin_no number := 1;
	col_no number := 0;
BEGIN
  while (indx <= jsrc.len) loop
    --read into buf
    buf := next_char(indx, jsrc);
    col_no := col_no + 1;
    --convert to switch case
    case
      when buf = '{' then tokens(tok_indx) := mt('{', lin_no, col_no, null); tok_indx := tok_indx + 1;
      when buf = '}' then tokens(tok_indx) := mt('}', lin_no, col_no, null); tok_indx := tok_indx + 1;
      when buf = ',' then tokens(tok_indx) := mt(',', lin_no, col_no, null); tok_indx := tok_indx + 1;
      when buf = ':' then tokens(tok_indx) := mt(':', lin_no, col_no, null); tok_indx := tok_indx + 1;
      when buf = '[' then tokens(tok_indx) := mt('[', lin_no, col_no, null); tok_indx := tok_indx + 1;
      when buf = ']' then tokens(tok_indx) := mt(']', lin_no, col_no, null); tok_indx := tok_indx + 1;
      when buf = 't' then
        if(next_char2(indx, jsrc, 4) != 'true') then
          if(json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i')) then
            tokens(tok_indx) := mt('STRING', lin_no, col_no, null);
            indx := lexName(jsrc, tokens(tok_indx), indx);
            col_no := col_no + length(tokens(tok_indx).data) + 1;
            tok_indx := tok_indx + 1;
          else
            s_error('Expected: ''true''', lin_no, col_no);
          end if;
        else
          tokens(tok_indx) := mt('TRUE', lin_no, col_no, null); tok_indx := tok_indx + 1;
          indx := indx + 3;
          col_no := col_no + 3;
        end if;
      when buf = 'n' then
        if(next_char2(indx, jsrc, 4) != 'null') then
          if(json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i')) then
            tokens(tok_indx) := mt('STRING', lin_no, col_no, null);
            indx := lexName(jsrc, tokens(tok_indx), indx);
            col_no := col_no + length(tokens(tok_indx).data) + 1;
            tok_indx := tok_indx + 1;
          else
            s_error('Expected: ''null''', lin_no, col_no);
          end if;
        else
          tokens(tok_indx) := mt('NULL', lin_no, col_no, null); tok_indx := tok_indx + 1;
          indx := indx + 3;
          col_no := col_no + 3;
        end if;
      when buf = 'f' then
        if(next_char2(indx, jsrc, 5) != 'false') then
          if(json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i')) then
            tokens(tok_indx) := mt('STRING', lin_no, col_no, null);
            indx := lexName(jsrc, tokens(tok_indx), indx);
            col_no := col_no + length(tokens(tok_indx).data) + 1;
            tok_indx := tok_indx + 1;
          else
            s_error('Expected: ''false''', lin_no, col_no);
          end if;
        else
          tokens(tok_indx) := mt('FALSE', lin_no, col_no, null); tok_indx := tok_indx + 1;
          indx := indx + 4;
          col_no := col_no + 4;
        end if;
      /*   -- 9 = TAB, 10 = \n, 13 = \r (Linux = \n, Windows = \r\n, Mac = \r */
      when (buf = Chr(10)) then --linux newlines
        lin_no := lin_no + 1;
        col_no := 0;

      when (buf = Chr(13)) then --Windows or Mac way
        lin_no := lin_no + 1;
        col_no := 0;
        if(jsrc.len >= indx +1) then -- better safe than sorry
          buf := next_char(indx+1, jsrc);
          if(buf = Chr(10)) then --\r\n
            indx := indx + 1;
          end if;
        end if;

      when (buf = CHR(9)) then null; --tabbing
      when (buf in ('-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9')) then --number
        tokens(tok_indx) := mt('NUMBER', lin_no, col_no, null);
        indx := lexNumber(jsrc, tokens(tok_indx), indx)-1;
        col_no := col_no + length(tokens(tok_indx).data);
        tok_indx := tok_indx + 1;
      when buf = '"' then --number
        tokens(tok_indx) := mt('STRING', lin_no, col_no, null);
        indx := lexString(jsrc, tokens(tok_indx), indx, '"');
        col_no := col_no + length(tokens(tok_indx).data) + 1;
        tok_indx := tok_indx + 1;
      when buf = '''' and json_strict = false then --number
        tokens(tok_indx) := mt('STRING', lin_no, col_no, null);
        indx := lexString(jsrc, tokens(tok_indx), indx, '''');
        col_no := col_no + length(tokens(tok_indx).data) + 1; --hovsa her
        tok_indx := tok_indx + 1;
      when json_strict = false and REGEXP_LIKE(buf, '^[[:alpha:]]$', 'i') then
        tokens(tok_indx) := mt('STRING', lin_no, col_no, null);
        indx := lexName(jsrc, tokens(tok_indx), indx);
        if(tokens(tok_indx).data_overflow is not null) then
          col_no := col_no + dbms_lob.getlength(tokens(tok_indx).data_overflow) + 1;
        else
          col_no := col_no + length(tokens(tok_indx).data) + 1;
        end if;
        tok_indx := tok_indx + 1;
      when json_strict = false and buf||next_char(indx+1, jsrc) = '/*' then --strip comments
        declare
          saveindx number := indx;
          un_esc clob;
        begin
          indx := indx + 1;
          loop
            indx := indx + 1;
            buf := next_char(indx, jsrc)||next_char(indx+1, jsrc);
            exit when buf = '*/';
            exit when buf is null;
          end loop;

          if(indx = saveindx+2) then
            --enter unescaped mode
            --dbms_output.put_line('Entering unescaped mode');
            un_esc := empty_clob();
            dbms_lob.createtemporary(un_esc, true);
            indx := indx + 1;
            loop
              indx := indx + 1;
              buf := next_char(indx, jsrc)||next_char(indx+1, jsrc)||next_char(indx+2, jsrc)||next_char(indx+3, jsrc);
              exit when buf = '/**/';
              if buf is null then
                s_error('Unexpected sequence /**/ to end unescaped data: '||buf, lin_no, col_no);
              end if;
              buf := next_char(indx, jsrc);
              dbms_lob.writeappend(un_esc, length(buf), buf);
            end loop;
            tokens(tok_indx) := mt('ESTRING', lin_no, col_no, null);
            tokens(tok_indx).data_overflow := un_esc;
            col_no := col_no + dbms_lob.getlength(un_esc) + 1; --note: line count won't work properly
            tok_indx := tok_indx + 1;
            indx := indx + 2;
          end if;

          indx := indx + 1;
        end;
      when buf = ' ' then null; --space
      else
        s_error('Unexpected char: '||buf, lin_no, col_no);
    end case;

    indx := indx + 1;
  end loop;

  return tokens;
END lexer;


--
--	END SCANNER
--	***********


--
--	START PARSER
--	************


----------------------------------------------------------
--	p_error (private)
--
PROCEDURE p_error(text VARCHAR2, tok rToken)
IS
BEGIN
	raise_application_error(-20101, 'JSON Parser exception @ line: '||tok.line||' column: '||tok.col||' - '||text);
END p_error;

----------------------------------------------------------
--	parseObj (private)
--
PROCEDURE parseObj(tokens lTokens, indx IN OUT NOCOPY PLS_INTEGER, theParentID IN OUT BINARY_INTEGER, theLastID IN OUT BINARY_INTEGER, theNodes IN OUT NOCOPY json_nodes)
IS
	TYPE memmap IS TABLE OF NUMBER INDEX BY VARCHAR2(4000); -- i've read somewhere that this is not possible - but it is!
	mymap memmap;
	nullelemfound BOOLEAN := FALSE;

	--yyy	obj json;
	obj json_object := json_object();

	tok rToken;
	mem_name VARCHAR(4000);
	--yyy	arr json_value_array := json_value_array();
	arr json_nodes := json_nodes();
BEGIN
	debug('parseObj - begin');

	-- what to expect?
	WHILE (indx <= tokens.count) LOOP
		tok := tokens(indx);
		debug('parseObj - type: '||tok.type_name);
		CASE tok.type_name
		WHEN 'STRING' THEN
			-- member
			mem_name := substr(tok.data, 1, 4000);
			BEGIN
				IF (mem_name IS NULL) THEN
					IF (nullelemfound) THEN
						p_error('Duplicate empty member: ', tok);
					ELSE
						nullelemfound := TRUE;
					END IF;
				ELSIF (mymap(mem_name) IS NOT NULL) THEN
					p_error('Duplicate member name: '||mem_name, tok);
				END IF;
			EXCEPTION
				WHEN no_data_found THEN
					mymap(mem_name) := 1;
			END;

			indx := indx + 1;
			IF (indx > tokens.count) THEN
				p_error('Unexpected end of input', tok);
			END IF;

			tok := tokens(indx);
			indx := indx + 1;
			IF (indx > tokens.count) THEN
				p_error('Unexpected end of input', tok);
			END IF;

			IF (tok.type_name = ':') THEN
				debug('parseObj - : found');
				parseMem(tokens, indx, mem_name, 0, theParentID, theLastID, theNodes);
			ELSE
				p_error('Expected '':''', tok);
			END IF;

			--move indx forward if ',' is found
			IF (indx > tokens.count) THEN
				p_error('Unexpected end of input', tok);
			END IF;

			tok := tokens(indx);
			IF (tok.type_name = ',') THEN
				debug('found ,');
				indx := indx + 1;
				tok := tokens(indx);
				IF (tok.type_name = '}') THEN --premature exit
					p_error('Premature exit in json object', tok);
				END IF;
			ELSIF (tok.type_name != '}') THEN
				p_error('A comma seperator is probably missing', tok);
			END IF;

		WHEN '}' THEN
			debug('parseObj - } found: returning '||arr.COUNT||' theNodes');
			RETURN;

		ELSE
			p_error('Expected string or }', tok);

		END CASE;

	END LOOP;

	p_error('} not found', tokens(indx-1));
END parseObj;

----------------------------------------------------------
--	parseArr (private)
--
PROCEDURE parseArr(tokens lTokens, indx IN OUT NOCOPY PLS_INTEGER, theParentID IN OUT BINARY_INTEGER, theLastID IN OUT BINARY_INTEGER, theNodes IN OUT NOCOPY json_nodes)
IS
	aNodeID		BINARY_INTEGER;
	aLastID		BINARY_INTEGER;
	tok			rToken;
	aNode		json_node		:=	json_node();
BEGIN
	IF (indx > tokens.count) THEN
		p_error('more elements in array was excepted', tok);
	END IF;

	tok := tokens(indx);
	WHILE (tok.type_name != ']') LOOP

		CASE tok.type_name

		WHEN 'TRUE' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx);
    		aNode		:= json_node(NULL, TRUE);
    		aNode.par	:= theParentID;
			aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID	:= aNodeID;

		WHEN 'FALSE' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx);
    		aNode		:= json_node(NULL, FALSE);
    		aNode.par	:= theParentID;
			aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID	:= aNodeID;

		WHEN 'NULL' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx);
    		aNode		:= json_node(NULL);
    		aNode.par	:= theParentID;
			aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID	:= aNodeID;

		WHEN 'STRING' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx||' value: '||CASE WHEN tok.data_overflow IS NOT NULL THEN tok.data_overflow ELSE tok.data END);
    		aNode		:= json_node(NULL, CASE WHEN tok.data_overflow IS NOT NULL THEN tok.data_overflow ELSE tok.data END);
    		aNode.par	:= theParentID;
			aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID	:= aNodeID;

		WHEN 'ESTRING' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx||' value: '||tok.data_overflow);
    		aNode		:= json_node(NULL, tok.data_overflow);
    		aNode.par	:= theParentID;
			aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID	:= aNodeID;

		WHEN 'NUMBER' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx||' value: '||TO_NUMBER(REPLACE(tok.data, '.', decimalpoint)));
    		aNode		:= json_node(NULL, TO_NUMBER(REPLACE(tok.data, '.', decimalpoint)));
    		aNode.par	:= theParentID;
			aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID	:= aNodeID;

		WHEN '{' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx);

	    	aNode			:= json_node();
	    	aNode.typ		:= 'O';
	    	aNode.sub		:= theNodes.COUNT + 2;
			aNodeID			:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID		:= aNodeID;
			theParentID		:= aNodeID;

			indx			:= indx + 1;
			aLastID			:= theLastID;
			theLastID		:= NULL;
			parseObj(tokens, indx, theParentID, theLastID, theNodes);
    		-- if "theLastID" did not change, we must be dealing with an empty object that does actually not have any sub-nodes
    		IF (theLastID IS NULL) THEN
    			theNodes(aLastID).sub := NULL;
    		END IF;
			theLastID		:= aLastID;
			aLastID			:= NULL;
			theParentID		:= NULL;

		WHEN '[' THEN
    		debug('parseArr - type: '||tok.type_name||' indx: '||indx);

	    	aNode			:= json_node();
	    	aNode.typ		:= 'A';
	    	aNode.sub		:= theNodes.COUNT + 2;
			aNodeID			:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
			IF (theLastID IS NOT NULL) THEN
				theNodes(theLastID).nex := aNodeID;
			END IF;
			theLastID		:= aNodeID;
			theParentID		:= aNodeID;

			indx			:= indx + 1;
			aLastID			:= theLastID;
			theLastID		:= NULL;
    		parseArr(tokens, indx, theParentID, theLastID, theNodes);
    		-- if "theLastID" did not change, we must be dealing with an empty array that does actually not have any sub-nodes
    		IF (theLastID IS NULL) THEN
    			theNodes(aLastID).sub := NULL;
    		END IF;
			theLastID		:= aLastID;
			aLastID			:= NULL;
			theParentID		:= NULL;

		ELSE
			p_error('Expected a value', tok);

		END CASE;

		indx := indx + 1;
		IF (indx > tokens.count) THEN
			p_error('] not found', tok);
		END IF;
		tok := tokens(indx);
		IF (tok.type_name = ',') THEN --advance
			indx := indx + 1;
			IF (indx > tokens.count) THEN
				p_error('more elements in array was excepted', tok);
			END IF;
			tok := tokens(indx);
			IF (tok.type_name = ']') THEN --premature exit
				p_error('Premature exit in array', tok);
			END IF;
		ELSIF (tok.type_name != ']') THEN --error
			p_error('Expected , or ]', tok);
		END IF;

	END LOOP;
end parseArr;

----------------------------------------------------------
--	parseMem (private)
--
PROCEDURE parseMem(tokens lTokens, indx IN OUT PLS_INTEGER, mem_name VARCHAR2, mem_indx NUMBER, theParentID IN OUT BINARY_INTEGER, theLastID IN OUT BINARY_INTEGER, theNodes IN OUT NOCOPY json_nodes)
IS
	tok			rToken;
	aNodeID		BINARY_INTEGER;
	aLastID		BINARY_INTEGER;
	aNode		json_node		:=	json_node();
BEGIN
	tok := tokens(indx);

	CASE tok.type_name

	WHEN 'TRUE' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name);
   		aNode		:= json_node(mem_name, TRUE);
   		aNode.par	:= theParentID;
		aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID	:= aNodeID;

	WHEN 'FALSE' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name);
   		aNode		:= json_node(mem_name, FALSE);
   		aNode.par	:= theParentID;
		aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID	:= aNodeID;

	WHEN 'NULL' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name);
   		aNode		:= json_node(mem_name);
   		aNode.par	:= theParentID;
		aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID	:= aNodeID;

	WHEN 'STRING' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name||' value: '||CASE WHEN tok.data_overflow IS NOT NULL THEN tok.data_overflow ELSE tok.data END);
   		aNode		:= json_node(mem_name, CASE WHEN tok.data_overflow IS NOT NULL THEN tok.data_overflow ELSE tok.data END);
   		aNode.par	:= theParentID;
		aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID	:= aNodeID;

	WHEN 'ESTRING' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name||' value: '||tok.data_overflow);
   		aNode		:= json_node(mem_name, tok.data_overflow);
   		aNode.par	:= theParentID;
		aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID	:= aNodeID;

	WHEN 'NUMBER' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name||' value: '||TO_NUMBER(REPLACE(tok.data, '.', decimalpoint)));
   		aNode		:= json_node(mem_name, TO_NUMBER(REPLACE(tok.data, '.', decimalpoint)));
   		aNode.par	:= theParentID;
		aNodeID		:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID	:= aNodeID;

	WHEN '{' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name);

    	aNode			:= json_node();
    	aNode.typ		:= 'O';
    	aNode.nam		:= mem_name;
    	aNode.sub		:= theNodes.COUNT + 2;
		aNodeID			:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID		:= aNodeID;
		theParentID		:= aNodeID;

		indx			:= indx + 1;
		aLastID			:= theLastID;
		theLastID		:= NULL;
		parseObj(tokens, indx, theParentID, theLastID, theNodes);
   		-- if "theLastID" did not change, we must be dealing with an empty object that does actually not have any sub-nodes
   		IF (theLastID IS NULL) THEN
   			theNodes(aLastID).sub := NULL;
   		END IF;
		theLastID		:= aLastID;
		aLastID			:= NULL;
		theParentID		:= NULL;

	WHEN '[' THEN
    	debug('parseMem - type: '||tok.type_name||' name: '||mem_name);

    	aNode			:= json_node();
    	aNode.typ		:= 'A';
    	aNode.nam		:= mem_name;
    	aNode.sub		:= theNodes.COUNT + 2;
		aNodeID			:= json_utils.addNode(theNodes=>theNodes, theNode=>aNode);
		IF (theLastID IS NOT NULL) THEN
			theNodes(theLastID).nex := aNodeID;
		END IF;
		theLastID		:= aNodeID;
		theParentID		:= aNodeID;

		indx			:= indx + 1;
		aLastID			:= theLastID;
		theLastID		:= NULL;
   		parseArr(tokens, indx, theParentID, theLastID, theNodes);
   		-- if "theLastID" did not change, we must be dealing with an empty array that does actually not have any sub-nodes
   		IF (theLastID IS NULL) THEN
   			theNodes(aLastID).sub := NULL;
   		END IF;
		theLastID		:= aLastID;
		aLastID			:= NULL;
		theParentID		:= NULL;

	ELSE
		p_error('Found '||tok.type_name, tok);

	END CASE;

	indx := indx + 1;
END parseMem;

----------------------------------------------------------
--	parse_list
--
FUNCTION parse_list(str CLOB) RETURN json_nodes
IS
	tokens	lTokens;
	--yyy	obj		json_list;
	obj		json_nodes := json_nodes();
	indx	PLS_INTEGER := 1;
	jsrc	json_src;
BEGIN
	debug('parse_list');
	updateDecimalPoint();
	jsrc := prepareClob(str);
	tokens := lexer(jsrc);
	IF (tokens(indx).type_name = '[') THEN
		indx := indx + 1;
		--yyy	obj := parseArr(tokens, indx);
	ELSE
		raise_application_error(-20101, 'JSON List Parser exception - no [ start found');
	END IF;
	IF (tokens.count != indx) THEN
		p_error('] should end the JSON List object', tokens(indx));
	END IF;

	RETURN obj;
END parse_list;

----------------------------------------------------------
--	parser
--
FUNCTION parser(str CLOB) RETURN json_nodes
IS
	tokens		lTokens;
	obj			json_nodes := json_nodes();

	indx		PLS_INTEGER		:= 1;
	jsrc		json_src;
	i			BINARY_INTEGER;
	aParentID	BINARY_INTEGER	:=	NULL;
	aLastID		BINARY_INTEGER	:=	NULL;
BEGIN
	updateDecimalPoint();
	jsrc := prepareClob(str);

	tokens := lexer(jsrc);

	--	dump tokens
	/*
	dbms_output.put_line('----------LEXER-S----------');
	i := tokens.FIRST;
	WHILE (i IS NOT NULL) LOOP
		dbms_output.put_line(i||'. type=('||tokens(i).type_name||') type=('||tokens(i).data||') type=('||tokens(i).data_overflow||')');
		i := tokens.NEXT(i);
	END LOOP;
	dbms_output.put_line('----------LEXER-E----------');
	*/

	IF (tokens(indx).type_name = '{') THEN
		indx := indx + 1;
		--yyy	obj := parseObj(tokens, indx);
		parseObj(tokens, indx, aParentID, aLastID, obj);
	ELSE
		raise_application_error(-20101, 'JSON Parser exception - no { start found');
	END IF;
	IF (tokens.count != indx) THEN
		p_error('} should end the JSON object', tokens(indx));
	END IF;

	RETURN obj;
END parser;

----------------------------------------------------------
--	parse_any
--
FUNCTION parse_any(str CLOB) RETURN /*yyy	json_value*/json_nodes
IS
	tokens	lTokens;
	--yyy	obj		json_list;
	obj		json_array := json_array();
	indx	PLS_INTEGER := 1;
	jsrc	json_src;
BEGIN
	debug('parse_any');
	jsrc := prepareClob(str);
	tokens := lexer(jsrc);
	tokens(tokens.count+1).type_name := ']';
	--yyy	obj := parseArr(tokens, indx);
	IF (tokens.count != indx) THEN
		p_error('] should end the JSON List object', tokens(indx));
	END IF;

  --yyy	return obj.head();
	RETURN NULL;
END parse_any;

END json_parser;
/
