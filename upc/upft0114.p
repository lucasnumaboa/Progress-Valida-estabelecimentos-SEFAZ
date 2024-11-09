/*-----------------------------------------------------------------------------------
    PROGRAMA : upft0114.p          
    OBJETIVO : 
    AUTOR    : 
    DATA     : 
-----------------------------------------------------------------------------------*/
/*************************************************************************************
                                      INCLUDES   
*************************************************************************************/
{tools/fc-handle-obj.i}

/*************************************************************************************
                                     PARAMETROS
*************************************************************************************/
DEFINE INPUT PARAMETER p-ind-event  AS CHARACTER     NO-UNDO.
DEFINE INPUT PARAMETER p-ind-object AS CHARACTER     NO-UNDO.
DEFINE INPUT PARAMETER p-wgh-object AS HANDLE        NO-UNDO.
DEFINE INPUT PARAMETER p-wgh-frame  AS WIDGET-HANDLE NO-UNDO.
DEFINE INPUT PARAMETER p-cod-table  AS CHARACTER     NO-UNDO.
DEFINE INPUT PARAMETER p-row-table  AS ROWID         NO-UNDO.

/*************************************************************************************
                                    VARIAVEIS GLOBAIS
*************************************************************************************/
DEFINE NEW GLOBAL SHARED VARIABLE wh-ft0114-cod-estabel       AS WIDGET-HANDLE NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE wh-ft0114-serie             AS WIDGET-HANDLE NO-UNDO.
DEFINE NEW GLOBAL SHARED VARIABLE wh-ft0114-cont-monitor      AS WIDGET-HANDLE NO-UNDO.

/*************************************************************************************
                                    VARIAVEIS LOCAIS
*************************************************************************************/
DEFINE VARIABLE c-handle-obj  AS CHARACTER        NO-UNDO.
DEFINE VARIABLE rw-ext-nf-e   AS ROWID            NO-UNDO.
  
/* ---> INSTANCIA OBJETOS <--- */ 
IF p-ind-event  = "BEFORE-INITIALIZE"    AND
   p-ind-object = 'VIEWER'               THEN DO:

  c-handle-obj = fc-handle-obj("cod-estabel",p-wgh-frame).
  wh-ft0114-cod-estabel   = WIDGET-HANDLE(ENTRY(1,c-handle-obj)) NO-ERROR.
  c-handle-obj = fc-handle-obj("serie",p-wgh-frame).
  wh-ft0114-serie         = WIDGET-HANDLE(ENTRY(1,c-handle-obj)) NO-ERROR.

END.

/* ---> GRAVANDO  <--- */ 
IF p-ind-event  = "ASSIGN" AND
   p-ind-object = 'VIEWER' THEN DO:

  FIND FIRST ser-estab 
       WHERE ROWID(ser-estab) = p-row-table 
       NO-LOCK NO-ERROR.
       
  IF AVAIL ser-estab THEN DO:
     FIND FIRST mgeuca.estabelec-fiscal 
          WHERE mgeuca.estabelec-fiscal.cod-estabel = ser-estab.cod-estabel 
          NO-LOCK NO-ERROR.
     IF AVAILABLE mgeuca.estabelec-fiscal AND mgeuca.estabelec-fiscal.situacao = "baixada" THEN DO:
        MESSAGE "Estabelecimento baixado, nao pode ser alterado, procurar area fiscal !!!" VIEW-AS ALERT-BOX.
        RETURN 'nok'.
     END.
  END. 
END.

//SE O ESTABELECIMENTO N«O ESTIVER PARAMETRIZADO PARA EMITIR NF ELE N«O VAI DEIXAR PARAMETRIZAR
/* ---> GRAVANDO  <--- */ 
IF p-ind-event  = "ASSIGN" AND
   p-ind-object = 'VIEWER' THEN DO:

  FIND FIRST ser-estab 
       WHERE ROWID(ser-estab) = p-row-table 
       NO-LOCK NO-ERROR.
       
  IF AVAIL ser-estab THEN DO:
     FIND FIRST estabelec 
          WHERE estabelec.cod-estabel = ser-estab.cod-estabel 
          NO-LOCK NO-ERROR.
     IF AVAILABLE estabelec AND estabelec.idi-tip-emis-nf-eletro = 1 THEN DO:
        MESSAGE "Estabelecimento n∆o habilitado, procurar area fiscal !!!" VIEW-AS ALERT-BOX.
        RETURN 'nok'.
     END.
  END. 
END.


//se n∆o estiver habilitado cd0360 para emitir nf, procurar TI
/* ---> GRAVANDO  <--- */ 
IF p-ind-event  = "ASSIGN" AND
   p-ind-object = 'VIEWER' THEN DO:

  FIND FIRST ser-estab 
       WHERE ROWID(ser-estab) = p-row-table 
       NO-LOCK NO-ERROR.
       
  IF AVAIL ser-estab THEN DO:
     FIND FIRST estabelec 
          WHERE estabelec.cod-estabel = ser-estab.cod-estabel 
          NO-LOCK NO-ERROR.
          
     IF AVAIL estabelec THEN     
     FIND FIRST param-gener 
        WHERE param-gener.cod-chave-1 = "param-comunic" 
        AND param-gener.cod-chave-2 = estabelec.cod-estabel 
        AND param-gener.cod-param = "NF-e"
        NO-LOCK NO-ERROR.     
          
          
     IF AVAILABLE estabelec AND AVAIL param-gener AND param-gener.cod-valor <> "4" THEN DO:
        MESSAGE "Estabelecimento n∆o habilitado, procurar TI !!!" VIEW-AS ALERT-BOX.
        RETURN 'nok'.
     END.
  END. 
END.




