{************************************************************************}
{* Program:     Announcer Generate                                      *}
{************************************************************************}
{* F”rfattare:  Peter Karlsson                                          *}
{* Datum:       97-08-08                                                *}
{* Version:     2.0                                                     *}
{************************************************************************}
{* Moduler:     crypt.pas                                               *}
{************************************************************************}
{************************************************************************}
{* Modul:       generate.pas                                            *}
{************************************************************************}
{* Inneh†ll:    Announcer kodgenererare                                 *}
{************************************************************************}
{* Funktion:    Visar registeringskod f”r Announcer                     *}
{************************************************************************}
{* Rutiner:     -                                                       *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.0p - 1994-07-03 -                                                *}
{*  v1.01 - 1997-07-24 - Visar SET-kommandot med nollor...              *}
{*  v2.0  - 1997-08-08 - Nytt registeringsformat                        *}
{************************************************************************}

Program Generate;

Uses Crypt;

{************************************************************************}
{* Rutin:       main                                                    *}
{************************************************************************}
{* Inneh†ll:    Fr†gar om namn och visar registreringskod               *}
{* Definition:  -                                                       *}
{************************************************************************}

var
  namn, code: string;
  serial: longint;
  T: Text;
begin
  Write  ('Ange registreringsnamn:');
  Readln(namn);
  Write  ('Ange serienummer:      ');
  Readln(serial);
  Writeln;
  Code := '';
  RegiCode(namn, serial, code);
  Writeln('Registreringskod:');
  Writeln(code);
  Assign(T, 'G:\ANNOUNCE.KEY');
  Rewrite(T);
  Writeln(T, namn);
  Writeln(T, serial);
  Writeln(T, code);
  Close(T);
  Writeln(CheckRegistration('G:\ANNOUNCE.KEY'));
end.
