{************************************************************************}
{************************************************************************}
{* Modul:       anhelp.pas                                              *}
{************************************************************************}
{* Inneh†ll:    Visning av hj„lptexten f”r Announcer                    *}
{************************************************************************}
{* Version:     1.10                                                    *}
{* F”rfattare   Peter Karlsson                                          *}
{*              Gjort efter ADHELP.PAS(c) Thomas Mainka f”r ADIR        *}
{* Datum:       1996-06-13                                              *}
{************************************************************************}
{* Revision:    0.30 F”rsta versionen                        1996-01-07 *}
{*              0.31.2 Uppdaterad                            1996-02-04 *}
{*              1.00.à2 Uppdaterad                           1996-03-02 *}
{*              1.00.à3 Uppdaterad                           1996-03-09 *}
{*              1.10 Uppdaterad                              1996-06-13 *}
{************************************************************************}
{* Rutiner:     Interface               Implementation                  *}
{*              =========               ==============                  *}
{*              HelpScreen              HelpSwe                         *}
{*                                      HelpEng                         *}
{************************************************************************}
Unit AnHelp;
{$I-,S-,G+,D-}
{$M 8192,8192,655360}

Interface

Procedure HelpScreen(bragline, registration: string);

Implementation
Uses Nls, Anstr;

{************************************************************************}
{* Rutin:       HelpEng                                                 *}
{************************************************************************}
{* Inneh†ll:    Visar den engelska hj„lpsk„rmen.                        *}
{* Definition:  Procedure HelpEng;                                      *}
{************************************************************************}

Procedure HelpEng(bragline, registration: string);
begin
    Writeln('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    Writeln('³±±±±±±±±±±±±±±± Announcer - a message posting utility program ±±±±±±±±±±±±±±±³');
    Writeln('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
    Writeln;
    Writeln(bragline, ' [', Registration, ']');
    Writeln('(c) Copyright 1995, 1996 Peter Karlsson');
    Writeln;
    Writeln('ANNOUNCE [/I[drive:][path]filename] [/D [/M]] [/Q] [/P] [name1 [name2]]');
    Writeln;
    Writeln('  /I[dive:][path]filename   Gives the name of an alternative configuration file');
    Writeln('  /D                        Display posting information');
    Writeln('  /M                        Removes unnecessary items from the .DAT file');
    Writeln('  /P                        Use PIDs instead of tearlines');
    Writeln('  /Q                        Shows nothing on the screen');
    Writeln('  name1  -and-  name2       Exchanged for the %1 and %2 variables in the');
    Writeln('                            configuration file');
    Writeln;
    Writeln('F”r svenskt l„ge, skriv  SET ANNLANG=SWE');
    Halt;
end;

{************************************************************************}
{* Rutin:       HelpSwe                                                 *}
{************************************************************************}
{* Inneh†ll:    Visar den svenska hj„lpsk„rmen.                         *}
{* Definition:  Procedure HelpSwe;                                      *}
{************************************************************************}

Procedure HelpSwe(bragline, registration: string);
begin
    Writeln('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
    Writeln('³±±±±±±±±±±±±± Announcer - ett program f”r att posta meddelanden ±±±±±±±±±±±±±³');
    Writeln('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
    Writeln;
    Writeln(bragline, ' [', Registration, ']');
    Writeln('(c) Copyright 1995, 1996 Peter Karlsson');
    Writeln;
    Writeln('ANNOUNCE [/I[enhet:][s”kv„g]filnamn] [/D [/M]] [/Q] [/P] [namn1 [namn2]]');
    Writeln;
    Writeln('  /I[enhet:][s”kv„g]filnamn   Anger namn p† en alternativ konfigurationsfil');
    Writeln('  /D                          Visa postningsinformation');
    Writeln('  /M                          Ta bort ”verfl”diga poster ur .DAT-filen');
    Writeln('  /P                          Anv„nd PID-kludge i.st.f tearline');
    Writeln('  /Q                          Visar ingenting p† sk„rmen');
    Writeln('  namn1  -och-  namn2         Anv„nds f”r %1- och %2-variablerna i konfigura-');
    Writeln('                              tionsfilen');
    Writeln;
    Writeln('For English mode, enter  SET ANNLANG=ENG');
    Halt;
end;

{************************************************************************}
{* Rutin:       HelpScreen                                              *}
{************************************************************************}
{* Inneh†ll:    V„ljer och visar hj„lpsk„rm.                            *}
{* Definition:  Procedure HelpScreen;                                   *}
{************************************************************************}

Procedure HelpScreen(bragline, registration: string);
begin
   if Language='SWE' then HelpSwe(bragline, registration)
   else HelpEng(bragline, registration);
   WriteLn('Language selection: Set environment variable ANNLANG to SWE or ENG');
end;

{************************************************************************}
{* Rutin:       Huvudprogram                                            *}
{************************************************************************}
{* Inneh†ll:    - (ingen f”rinitialisering n”dv„ndig)                   *}
{************************************************************************}

end.
