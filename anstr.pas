{************************************************************************}
{************************************************************************}
{* Modul:       anstr.pas                                               *}
{************************************************************************}
{* Inneh†ll:    Textstr„ngar f”r nationellt spr†kst”d f”r Announcer     *}
{************************************************************************}
{* Funktion:    Best„mmer de riktiga textstr„ngarna beroende p† lands-  *}
{*              informationen resp. milj”variabeln ANNLANG              *}
{************************************************************************}
{* Version:     1.00.à3                                                 *}
{* F”rfattare:  Peter Karlsson                                          *}
{*              Gjort efter ADSTRING.PAS (c) Thomas Mainka f”r ADIR     *}
{* Datum:       1996-  -                                                *}
{************************************************************************}
{* Revision:    0.30 F”rsta versionen                        1996-01-07 *}
{*              0.31 R„ttade texter                          1996-02-03 *}
{*              0.31.2 Lade till texter                      1996-02-09 *}
{*              1.00.à3 Lade till texter                     1996-03-09 *}
{************************************************************************}

Unit AnStr;
{$G+,D-}
Interface

Var StrErrSav, StrErrBas, StrErrFil, StrErrReg, StrErrPar, StrErrOp1,
    StrErrOp2, StrErrIni, StrErrIn2, StrErrTag, StrErrLog, StrErrLo2,
    StrErrOrg, StrErrDst, StrErrTos, StrErrTo2, StrErrDat, StrErrDaf,
    StrErrDar,
    StrLogBeg, StrLogEnd, StrLogSav, StrLogBas, StrLogFil, StrLogIni,
    StrLogTos, StrLogTo2, StrLogRun,
    StrStdOri, StrDidSav, StrDidSv2, StrDidSv3, StrNotInt, StrNotIn2,
    StrNotIn3, StrNotReg,
    StrInfMsg, StrInfLst, StrInfClk, StrInfAgo, StrInfTod, StrInfYst,
    StrInfInt, StrInfDag, StrInfLes, StrInfMor, StrInfFnn, StrInfNoi,
    StrInfNop, StrInfRem: String;
    Language  : String[3];

Implementation
Uses Nls, Dos;

Var      S         : String;
         EXTPath   : DirStr;
         EXTFileExists: Boolean;
         ExtFil    : Text;

{************************************************************************}
{* Rutin:       Huvudprogram                                            *}
{************************************************************************}
{* Inneh†ll:    Kontrollerar spr†k mm.                                  *}
{* Definition:  -                                                       *}
{************************************************************************}

begin
   case Country of
     45, 46, 47, 358: Language:='SWE';    { Sverige, Danmark, Norge, Suomi }
{     41, 43, 49     : Language:='GER';    { Deutschland, ™sterreich, Schweiz }
     else             Language:='ENG';    { Rest of the world }
   end;

   S:=GetEnv('ANNLANG');
   if S<>'' then Language:=Copy(UpStr(S),1,3);

{$IFDEF TEST_MODUS}
   Write('Spr†k: ',Language,', nytt:');
   Readln(Language);
{$ENDIF}

   if Language='SWE' then
   begin
     { Felmeddelanden }
     StrErrSav := 'Fel vid sparande av meddelandet "';
     StrErrBas := 'Stackars lilla jag kan inte hitta meddelandebasen ';
     StrErrFil := 'Lyckades inte lokalisera filen ';
     StrErrReg := 'F”r att anv„nda denna betaversion m†ste du ha en giltig registreringsnyckel.';
     StrErrPar := 'Felaktig kommandoradsparameter:';
     StrErrOp1 := 'Kunde inte ”ppna varken ';
     StrErrOp2 := ' eller ';
     StrErrIni := 'Fel i ';
     StrErrIn2 := 'Felaktig rad i ';
     StrErrTag := 'Slumpvald tagline ”nskad, men ingen fil har valts!';
     StrErrLog := 'Max en loggfil kan specificeras';
     StrErrLo2 := 'Kunde inte ”ppna loggfilen!';
     StrErrOrg := 'Ogiltig avs„ndaradress: ';
     StrErrDst := 'Ogiltig mottagaradress: ';
     StrErrTos := 'Kan ej skapa echotossloggfil ';
     StrErrTo2 := 'Kan ej skriva till echotossloggfil ';
     StrErrDat := 'Kan ej skapa datafil ';
     StrErrDaf := 'Kan ej hitta datafil ';
     StrErrDar := 'Kan ej byta namn p† datafilen';
     { Texter i loggfilen }
     StrLogBeg := 'Start, ';
     StrLogEnd := 'Slut, ';
     StrLogSav := 'Kunde inte skriva meddelande nr ';
     StrLogBas := 'Kunde inte lokalisera meddelandebas ';
     StrLogFil := 'Kunde inte lokalisera fil ';
     StrLogIni := 'Konfigurationsfil: ';
     StrLogTos := 'Kunde inte skapa ';
     StrLogTo2 := 'Kunde inte skriva till ';
     StrLogRun := 'K”rtidsfel ';
     { Str„ngar }
     StrStdOri := 'Standard-Origin-rad';
     StrDidSav := 'Skrev meddelande ';
     StrDidSv2 := ' i ';
     StrDiDSv3 := ' (mall ';
     StrNotInt := 'Mall ';
     StrNotIn2 := ' ska ej postas idag (';
     StrNotIn3 := ' dagar sen sist, intervall ';
     StrNotReg := 'OREGISTRERAD';
     StrInfMsg := 'Meddelande ';
     StrInfLst := ' postades senast den ';
     StrInfClk := ' kl ';
     StrInfAgo := ' dagar sedan).';
     StrInfTod := 'idag).';
     StrInfYst := 'ig†r).';
     StrInfInt := ' ™nskat intervall „r ';
     StrInfDag := ' dag(ar), meddelandet ska ';
     StrInfLes := 'ej postas idag.';
     StrInfMor := 'postas idag.';
     StrInfFnn := ' Meddelandedefinition kunde ej hittas i inst„llningsfilen';
     StrInfNoi := ' Inget intervall har definierats';
     StrInfNop := 'Meddelandet har inte postats';
     StrInfRem := ' Datafilsposten har tagits bort';
   end
   else if Language='ENG' then
   begin
     { Felmeddelanden }
     StrErrSav := 'Error while saving the message "';
     StrErrBas := 'Poor little me could not find the message base ';
     StrErrFil := 'Unable to localize the file ';
     StrErrReg := 'To use this beta version, you will need a valid registration key.';
     StrErrPar := 'Illegal command line parameter:';
     StrErrOp1 := 'Can not open neither ';
     StrErrOp2 := ' nor ';
     StrErrIni := 'Error in ';
     StrErrIn2 := 'Illegal line in ';
     StrErrTag := 'Random tagline was selected, but no file have been selected!';
     StrErrLog := 'No more than one log file can be specified';
     StrErrLo2 := 'Unable to open the log file!';
     StrErrOrg := 'Illegal originating address: ';
     StrErrDst := 'Illegal destination address: ';
     StrErrTos := 'Unable to create echo toss log file ';
     StrErrTo2 := 'Unable to write to echo toss log file ';
     StrErrDat := 'Unable to create data file ';
     StrErrDaf := 'Unable to find data file ';
     StrErrDar := 'Unable to rename data file';
     { Texter i loggfilen }
     StrLogBeg := 'Begin, ';
     StrLogEnd := 'End, ';
     StrLogSav := 'Unable to write message #';
     StrLogBas := 'Unable to localize message base ';
     StrLogFil := 'Unable to localize file ';
     StrLogIni := 'Configuration file: ';
     StrLogTos := 'Unable to create ';
     StrLogTo2 := 'Unable to write to ';
     StrLogRun := 'Run time error ';
     { Str„ngar }
     StrStdOri := 'Default Origin Line';
     StrDidSav := 'Wrote message #';
     StrDidSv2 := ' in ';
     StrDidSv3 := ' (template #';
     StrNotInt := 'Template #';
     StrNotIn2 := ' not due today (';
     StrNotIn3 := ' days ago, interval is ';
     StrNotReg := 'NOT REGISTERED';
     StrInfMsg := 'Message ';
     StrInfLst := ' last posted on ';
     StrInfClk := ' at ';
     StrInfAgo := ' days ago).';
     StrInfTod := 'today).';
     StrInfYst := 'yesterday).';
     StrInfInt := ' Defined interval is ';
     StrInfDag := ' day(s), the message should ';
     StrInfLes := 'not be posted today.';
     StrInfMor := 'be posted today.';
     StrInfFnn := ' Message template could not be found';
     StrInfNoi := ' No interval has been defined';
     StrInfNop := 'Message has not been posted';
     StrInfRem := ' The data file item has been removed';
   end
   else
   begin
      WriteLn('Illegal language: ',Language);
      Halt(3);
   end;
end.
