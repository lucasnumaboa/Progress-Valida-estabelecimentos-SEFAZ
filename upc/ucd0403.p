/******************************************************************
**
**  Programa: UCD0403
**     AutOR: Informatica 
**  Objetivo: Controle estabelecimento Sefaz
**      Data: junhp/2024
**

\******************************************************************/

/* definicao de variaveis globais */
{utp/ut-glob.i}

/* Parameter definitons */

DEFINE INPUT PARAMETER p-ind-event  AS CHAR.
DEFINE INPUT PARAMETER p-ind-object AS CHAR.
DEFINE INPUT PARAMETER p-wgh-object AS HANDLE.
DEFINE INPUT PARAMETER p-wgh-frame  AS WIDGET-HANDLE.
DEFINE INPUT PARAMETER p-cod-table  AS CHAR.
DEFINE INPUT PARAMETER p-row-table  AS ROWID.

/* Variaveis locais */
DEFINE VAR c-objeto AS CHAR NO-UNDO.

/* variaveis globais */
DEFINE NEW GLOBAL SHARED VAR fl-estabelec        AS WIDGET-HANDLE NO-UNDO.
DEFINE NEW GLOBAL SHARED VAR fl-estabelec-sit    AS WIDGET-HANDLE NO-UNDO.


DEFINE NEW GLOBAL SHARED VAR h_container  AS HANDLE NO-UNDO.

DEFINE new global SHARED  var  wh-objeto       as widget-handle no-undo. 

ASSIGN c-objeto = ENTRY(NUM-ENTRIES(p-wgh-object:FILE-NAME, "~/"), p-wgh-object:FILE-NAME,"~/").


//Lucas - 11-/6/2024
IF p-ind-event = "before-enable" AND
   p-ind-object = "container" AND
   p-wgh-object:FILE-NAME = "cdp/cd0403.w"  THEN DO:

    CREATE TEXT fl-estabelec
    ASSIGN 
        FRAME = p-wgh-frame
        FORMAT = "x(15)"
        WIDTH-CHARS = 14
        HEIGHT-CHARS = 0.88
        ROW = 3.2
        COL = 56
        SCREEN-VALUE = "Situaá∆o sefaz:"
        VISIBLE = YES
        SENSITIVE = NO
        FGCOLOR = 9. //03/07/2023 - Lucas 
        
    CREATE FILL-IN fl-estabelec-sit
    ASSIGN 
        FRAME = p-wgh-frame
        WIDTH = 16
        FORMAT = "x(14)"
        HEIGHT-CHARS = 0.88
        ROW = 3.2
        COL = 66.5
        SCREEN-VALUE = ""
        VISIBLE = YES
        SENSITIVE = NO
        FGCOLOR = 9. //03/07/2023 - Lucas   
        
END.

 IF p-ind-event = "before-display" AND
           p-ind-object = "viewer" AND
           p-wgh-object:FILE-NAME = "advwr/v28ad107.w" THEN DO: 
    
    FIND FIRST estabelec 
    WHERE ROWID(estabelec)= p-row-table NO-LOCK NO-ERROR.
    
    IF AVAIL estabelec THEN
    FIND FIRST mgeuca.estabelec-fiscal WHERE
    mgeuca.estabelec-fiscal.cod-estabel = estabelec.cod-estabel NO-LOCK NO-ERROR.  
    
    IF AVAIL mgeuca.estabelec-fiscal THEN DO:
    IF VALID-HANDLE(fl-estabelec-sit) THEN
        ASSIGN fl-estabelec-sit:SCREEN-VALUE = STRING(mgeuca.estabelec-fiscal.situacao).
    END.
    
    IF NOT AVAIL mgeuca.estabelec-fiscal THEN DO:
    IF VALID-HANDLE(fl-estabelec-sit) THEN
        ASSIGN fl-estabelec-sit:SCREEN-VALUE = STRING("n∆o encontrado").
    END.
END.

                   
