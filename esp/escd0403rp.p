USING com.totvs.framework.abl.json.*.

define temp-table tt-param no-undo
    field destino          as integer
    field arquivo          as char format "x(35)"
    field usuario          as char format "x(12)"
    field data-exec        as date
    field hora-exec        as integer
    field classifica       as integer
    field desc-classifica  as char format "x(40)"
    field modelo-rtf       as char format "x(35)"
    field l-habilitaRtf    as LOG.

DEF TEMP-TABLE tt-raw-digita
        FIELD raw-digita    AS RAW .

/* recebimento de parƒmetros */
DEF INPUT PARAMETER raw-param AS RAW NO-UNDO .
DEF INPUT PARAMETER TABLE FOR tt-raw-digita.

CREATE tt-param.
RAW-TRANSFER raw-param TO tt-param.


DEF VAR mesg AS CHAR.

OUTPUT TO "\\130.0.5.199\ftp\rpw\Estabelecimento-monitorado.TXT" APPEND.

mesg = ''.



DEFINE VARIABLE objHTTP AS COM-HANDLE  NO-UNDO.
DEFINE VARIABLE cUrl    AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cBOdy   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE cCNPJ   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE oJson   AS CLASS JSONObject NO-UNDO.

DEFINE VARIABLE k AS INTEGER     NO-UNDO.

//cria os registros dos estabelecimento existentes
FOR EACH estabelec NO-LOCK.
    FIND FIRST mgeuca.estabelec-fiscal
    WHERE mgeuca.estabelec-fiscal.cod-estabel = estabelec.cod-estabel NO-ERROR.
 
    IF NOT AVAIL mgeuca.estabelec-fiscal THEN DO:
    CREATE mgeuca.estabelec-fiscal.

    ASSIGN
    mgeuca.estabelec-fiscal.cod-estabel = estabelec.cod-estabel
    mgeuca.estabelec-fiscal.nome        = estabelec.nome
    mgeuca.estabelec-fiscal.pendente    = YES
    mgeuca.estabelec-fiscal.situacao    = 'Ativo'
    mgeuca.estabelec-fiscal.cgc         = estabelec.cgc.
    END.
END.

//marca todos como pendente de verifica»’o, s½ faz essa verifica»’o uma vez, no primeiro dia do m¼s, deve ser executado as 01:00:00.
IF DAY(TODAY) = 1 AND STRING(TIME,"hh:mm:ss") <= "01:30:00" THEN DO:
    FOR EACH mgeuca.estabelec-fiscal.
    ASSIGN mgeuca.estabelec-fiscal.pendente    = YES.
    END.
END.

//rotina para executar nos primeiros 7 dias do m¼s
//IF DAY(TODAY) >= 1 AND DAY(TODAY) <= 7 THEN DO:
    DO  k = 1 TO 3:
       FIND FIRST mgeuca.estabelec-fiscal
            WHERE mgeuca.estabelec-fiscal.pendente = YES NO-ERROR.
          
        IF AVAIL estabelec-fiscal THEN DO:
             cCNPJ = mgeuca.estabelec-fiscal.cgc.

             CREATE  "WinHttp.WinHttpRequest.5.1" objHTTP.
    
             cURL = "https://receitaws.com.br/v1/cnpj/scnpj".
             cURL = replace(cURL,"scnpj",cCNPJ).
             objHTTP:Open( "get", cURL).
             objHTTP:send () NO-ERROR.
             oJson = NEW JSONObject(objHTTP:ResponseText) NO-ERROR.
       
             IF oJson:getString("situacao") <> ? THEN DO:
                 IF oJson:getString("situacao") = 'ATIVA' THEN
                 mgeuca.estabelec-fiscal.situacao    = 'ATIVA'.
                 ELSE
                 mgeuca.estabelec-fiscal.situacao    = 'BAIXADA'.
       
                 ASSIGN mgeuca.estabelec-fiscal.pendente = NO.         
                 
             END.
        END.     
    END.
//END.



k = 1.

//Aqui vai desativar do CD0360 caso o mesmo esteja BAIXADO
FOR EACH mgeuca.estabelec-fiscal NO-LOCK.
    IF mgeuca.estabelec-fiscal.situacao = 'BAIXADA' THEN DO:
 
        
        FOR EACH param-gener 
            WHERE param-gener.cod-chave-1 = "param-comunic" 
            AND param-gener.cod-chave-2 = mgeuca.estabelec-fiscal.cod-estabel.
            
        IF AVAIL param-gener AND 
        param-gener.cod-param = "NF-e" AND param-gener.cod-valor ='4' THEN DO:    
        EXPORT DELIMITER ';'
        TODAY
        estabelec-fiscal.cod-estabel
        estabelec-fiscal.situacao
        'desativado-cd0360'.  
        END.

        IF AVAIL param-gener AND param-gener.cod-param = "NF-e" THEN param-gener.cod-valor = "1".
        IF AVAIL param-gener AND param-gener.cod-param = "MDF-e" THEN param-gener.cod-valor = "1".        
   
        END.
    END.
END.







