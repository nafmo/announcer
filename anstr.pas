{************************************************************************}
{************************************************************************}
{* Modul:       anstr.pas                                               *}
{************************************************************************}
{* Inneh†ll:    Textstr„ngar f”r nationellt spr†kst”d f”r Announcer     *}
{************************************************************************}
{* Funktion:    Best„mmer de riktiga textstr„ngarna beroende p† lands-  *}
{*              informationen resp. milj”variabeln ANNLANG              *}
{************************************************************************}
{* Version:     1.12                                                    *}
{* F”rfattare:  Peter Karlsson                                          *}
{*              Gjort efter ADSTRING.PAS (c) Thomas Mainka f”r ADIR     *}
{************************************************************************}
{* Revision:    0.30 F”rsta versionen                        1996-01-07 *}
{*              0.31 R„ttade texter                          1996-02-03 *}
{*              0.31.2 Lade till texter                      1996-02-09 *}
{*              1.00 Lade till texter                        1996-03-09 *}
{*              1.10 Lade till/tog bort/„ndrade texter       1996-08-14 *}
{*              1.11 Lade till/tog bort/„ndrade texter       1996-11-15 *}
{*              1.12 Lade till/tog bort/„ndrade texter       1997-04-03 *}
{*              1.2  Lade till/tog bort/„ndrade texter       1997-07-18 *}
{************************************************************************}

Unit AnStr;
{$G+,D-}
Interface

Var StrErrVir, StrErrSav, StrErrBas, StrErrFil, StrErrPar, StrErrPrc,
    StrErrOp1, StrErrOp2, StrErrIni, StrErrIn2, StrErrTag, StrErrLog,
    StrErrLo2, StrErrOrg, StrErrDst, StrErrTos, StrErrTo2, StrErrDat,
    StrErrDaf, StrErrDar, StrErrLoc, StrErrAll, StrErrRea, StrErrWri,
    StrErrMOp, StrErrPOp, StrErrIds, StrErrId2, StrErrId3, StrErrTor,
    StrLogBeg, StrLogEnd, StrLogEn2, StrLogSav, StrLogBas, StrLogFil,
    StrLogIni, StrLogTos, StrLogTo2, StrLogRun, StrLogRn2, StrLogMis,
    StrLogPkt, StrLogCrf, StrLogCrs, StrLogFor, StrLogFno, StrLogFn2,
    StrLogTor, StrLogTr2, StrLogTr3, StrLogTr4,
    StrStdOri, StrDidSav, StrDidSv2, StrDidSv3, StrDidSim, StrNotInt,
    StrNotIn2, StrNotIn3, StrNotIn4, StrNotIn5, StrNotSem, StrNotReg,
    StrTooSml, StrNotUpd, StrAskPos, StrAskPo2, StrAskPo3,
    StrInfMsg, StrInfLst, StrInfClk, StrInfAgo, StrInfTod, StrInfYst,
    StrInfInt, StrInfDag, StrInfLes, StrInfMor, StrInfDat, StrInfDa2,
    StrInfFnn, StrInfNop, StrInfRem, StrInfZer, StrInfSem, StrInfSno,
    StrInfSye, StrInfMin, StrInfMi2, StrInfMno, StrInfMye, StrInfUpd,
    StrInfUno, StrInfUp2, StrInfLat, StrInfYtt, StrInfPlc: String;
    ChrYes, ChrNo: Char;
    Language : String[3];

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
     StrErrVir := 'Sj„lvtest misslyckades'#7;
     StrErrSav := 'Fel vid sparande av meddelandet "';
     StrErrBas := 'Stackars lilla jag kan inte hitta meddelandebasen ';
     StrErrFil := 'Lyckades inte lokalisera filen ';
     StrErrPar := 'Felaktig kommandoradsparameter:';
     StrErrPrc := 'Felaktig kommandoradsparameterskombination: /FA och /Q';
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
     StrErrLoc := 'Lokala meddelanden ej till†tna i PKT-l„ge';
     StrErrAll := 'Kan ej allokera minne - inga PKT-filer har skapats';
     StrErrRea := 'Fel vid l„sning av MSG-fil';
     StrErrWri := 'Fel vid skrivning av PKT-fil';
     StrErrMOp := 'Fel vid ”ppning av MSG-fil ';
     StrErrPOp := 'Fel vid skapande av PKT-fil ';
     StrErrIds := 'Kan ej ”ppna eller skapa MSGID-serverfil ';
     StrErrId2 := 'MSGID-serverfil har felaktig signatur, skapar ny.';
     StrErrId3 := 'MSGID-serverfil har felaktig kontrollsumma, skapar ny';
     StrErrTor := 'Endast en tosserkonfigurationsfil kan specificeras';
     { Texter i loggfilen }
     StrLogBeg := 'Start, ';
     StrLogEnd := 'Slut, ';
     StrLogEn2 := ' meddelande(n) skrevs)';
     StrLogSav := 'Kunde inte skriva meddelande nr ';
     StrLogBas := 'Kunde inte lokalisera meddelandebas ';
     StrLogFil := 'Kunde inte lokalisera fil ';
     StrLogIni := 'Konfigurationsfil: ';
     StrLogTos := 'Kunde inte skapa ';
     StrLogTo2 := 'Kunde inte skriva till ';
     StrLogRun := 'K”rtidsfel ';
     StrLogRn2 := ' vid ';
     StrLogMis := 'Vital meddelandeinformation saknas, mall ';
     StrLogPkt := 'Skapade PKT-fil ';
     StrLogCrf := 'Kunde inte skapa semaforfil ';
     StrLogCrs := 'Skapade semaforfil ';
     StrLogFor := 'Framtvingad postning av mall ';
     StrLogFno := 'Postning av mall ';
     StrLogFn2 := ' bortvald';
     StrLogTor := 'M”tesdefinition saknas f”r ';
     StrLogTr2 := ' i tosserkonfigurationen';
     StrLogTr3 := 'Kunde ej l„sa tosserkonfigurationsfil ';
     StrLogTr4 := 'Fel vid l„sning av tosserkonfigurationsfil ';
     { Str„ngar }
     StrStdOri := 'Standard-Origin-rad';
     StrDidSav := 'Skrev meddelande ';
     StrDidSv2 := ' i ';
     StrDidSv3 := ' (mall ';
     StrDidSim := '(simulerat)';
     StrNotInt := 'Mall ';
     StrNotIn2 := ' ska ej postas idag';
     StrNotIn3 := ' dagar sen sist, intervall ';
     StrNotIn4 := 'postas enbart den ';
     StrNotIn5 := 'har redan postats idag';
     StrNotSem := 'Semaforfil saknas f”r mall ';
     StrNotReg := 'OREGISTRERAD';
     StrTooSml := 'Filen „r f”r liten, mall ';
     StrNotUpd := 'Filen „r inte uppdaterad, mall ';
     StrAskPos := 'Posta "';
     StrAskPo2 := '" i ';
     StrAskPo3 := '? (J/N) ';
     { Informationsstr„ngar }
     StrInfMsg := 'Meddelande ';
     StrInfLst := ' postades senast den ';
     StrInfClk := ' kl ';
     StrInfAgo := ' dagar sedan).';
     StrInfTod := 'idag).';
     StrInfYst := 'ig†r).';
     StrInfInt := ' ™nskat intervall „r ';
     StrInfDag := ' dag(ar)';
     StrInfLes := 'kommer ej att postas.';
     StrInfMor := '„r redo f”r postning.';
     StrInfDat := ' ™nskat postningsdatum „r ';
     StrInfDa2 := ', meddelandet ';
     StrInfFnn := ' Meddelandedefinition kunde ej hittas i inst„llningsfilen.';
     StrInfNop := 'Meddelandet har inte postats.';
     StrInfRem := ' Datafilsposten har tagits bort.';
     StrInfZer := ' Datafilsposten har nollst„llts.';
     StrInfSem := ' Semaforfil ';
     StrInfSno := 'existerar inte, meddelandet kommer ej postas.';
     StrInfSye := 'existerar, meddelandet „r redo f”r postning.';
     StrInfMin := ' ™nskad minsta storlek „r ';
     StrInfMi2 := ' byte, meddelandefilen „r ';
     StrInfMno := 'f”r liten.';
     StrInfMye := 'tillr„ckligt stor.';
     StrInfUpd := ' Filen har ';
     StrInfUno := 'ej ';
     StrInfUp2 := 'uppdaterats sedan senaste postning.';
     StrInfLat := ' Senaste MSGID: ';
     StrInfYtt := ' ytterligare meddelandemall(ar) finns.';
     StrInfPlc := ' Meddelandemallen „r oanv„nd.';
     { Svar Ja/Nej }
     ChrYes := 'J';
     ChrNo  := 'N';
   end
   else if Language='ENG' then
   begin
     { Felmeddelanden }
     StrErrVir := 'Self test failed'#7;
     StrErrSav := 'Error while saving the message "';
     StrErrBas := 'Poor little me could not find the message base ';
     StrErrFil := 'Unable to localize the file ';
     StrErrPar := 'Illegal command line parameter:';
     StrErrPrc := 'Illegal command line parameter combination: /FA and /Q';
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
     StrErrLoc := 'Local messages not allowed in PKT mode';
     StrErrAll := 'Unable to allocate memory - no PKT files have been created';
     StrErrRea := 'Error while reading MSG file';
     StrErrWri := 'Error while writing PKT file';
     StrErrMOp := 'Error while opening MSG file ';
     StrErrPOp := 'Error while creating PKT file ';
     StrErrIds := 'Unable to open or create MSGID server file ';
     StrErrId2 := 'MSGID server file has invalid signature, creating new.';
     StrErrId3 := 'MSGID server file has invalid checksum, creating new.';
     StrErrTor := 'No more than one tosser configuration file can be specified';
     { Texter i loggfilen }
     StrLogBeg := 'Begin, ';
     StrLogEnd := 'End, ';
     StrLogEn2 := ' message(s) written)';
     StrLogSav := 'Unable to write message #';
     StrLogBas := 'Unable to localize message base ';
     StrLogFil := 'Unable to localize file ';
     StrLogIni := 'Configuration file: ';
     StrLogTos := 'Unable to create ';
     StrLogTo2 := 'Unable to write to ';
     StrLogRun := 'Run time error ';
     StrLogRn2 := ' at ';
     StrLogMis := 'Vital message information missing, template #';
     StrLogPkt := 'Created PKT file ';
     StrLogCrf := 'Unable to create semaphore file ';
     StrLogCrs := 'Created semaphore file ';
     StrLogFor := 'Forced posting of template #';
     StrLogFno := 'Posting of template #';
     StrLogFn2 := ' deselected';
     StrLogTor := 'Area definition for ';
     StrLogTr2 := ' missing in tosser config';
     StrLogTr3 := 'Unable to read tosser configuration file ';
     StrLogTr4 := 'Error while reading tosser configuration file ';
     { Str„ngar }
     StrStdOri := 'Default Origin Line';
     StrDidSav := 'Wrote message #';
     StrDidSv2 := ' in ';
     StrDidSv3 := ' (template #';
     StrDidSim := '(simulated)';
     StrNotInt := 'Template #';
     StrNotIn2 := ' not due today';
     StrNotIn3 := ' days ago, interval is ';
     StrNotIn4 := 'only posted on the ';
     StrNotIn5 := 'has already been posted today';
     StrNotSem := 'Semaphore file missing for template #';
     StrNotReg := 'NOT REGISTERED';
     StrTooSml := 'The file is too small, template #';
     StrNotUpd := 'The file is not updated, template #';
     StrAskPos := 'Post "';
     StrAskPo2 := '" in ';
     StrAskPo3 := '? (Y/N) ';
     { Informationsstr„ngar }
     StrInfMsg := 'Message ';
     StrInfLst := ' last posted on ';
     StrInfClk := ' at ';
     StrInfAgo := ' days ago).';
     StrInfTod := 'today).';
     StrInfYst := 'yesterday).';
     StrInfInt := ' Defined interval is ';
     StrInfDag := ' day(s)';
     StrInfLes := 'will not be posted.';
     StrInfMor := 'is ready to be posted.';
     StrInfDat := ' Defined date of posting is ';
     StrInfDa2 := ', the message ';
     StrInfFnn := ' Message template could not be found in the configuration file.';
     StrInfNop := 'Message has not been posted.';
     StrInfRem := ' The data file entry has been removed.';
     StrInfZer := ' The data file entry has been zeroed out.';
     StrInfSem := ' Semaphore file ';
     StrInfSno := 'does not exist, message will not be posted.';
     StrInfSye := 'exists, message is ready to be posted.';
     StrInfMin := ' Defined minimum size is ';
     StrInfMi2 := ' bytes, the message file is ';
     StrInfMno := 'too small.';
     StrInfMye := 'big enough.';
     StrInfUpd := ' The file has ';
     StrInfUno := 'not ';
     StrInfUp2 := 'been updated since the last posting.';
     StrInfLat := ' Latest MSGID: ';
     StrInfYtt := ' more message template(s) exists.';
     StrInfPlc := ' The message template is not in use.';
     { Svar Ja/Nej }
     ChrYes := 'Y';
     ChrNo  := 'N';
   end
   else
   begin
      WriteLn('Illegal language: ',Language);
      Halt(3);
   end;
end.
