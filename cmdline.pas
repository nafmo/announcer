{************************************************************************}
{* Modul:       CmdLine.Pas                                             *}
{************************************************************************}
{* Inneh†ll:    Kommandoradsparser                                      *}
{************************************************************************}
{* Funktion:    Tar hand om kommandoraden                               *}
{************************************************************************}
{* Rutiner:     CommandLine                                             *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.11 - 1997-01-21 - F”rsta versionen                               *}
{*  v1.12 - 1997-04-03 - Fler kommandoradsv„xlar                        *}
{*  v1.2  - 1997-06-24 - Ignorerar _-parameter (registreringskod)       *}
{*                     - St”d f”r upp till tio namn (%-variabler)       *}
{************************************************************************}
Unit CmdLine;

{$D-,G+,X+}

Interface

Type
  RunMode = (DoPost, PostForce, PostForceAsk, DisplayData);

Function CommandLine(Var StdErr: Text; Var IniFile: String; Var Maint: Boolean;
                     Var ForcePid: Boolean; Var LeaveDates: Boolean;
                     Var DoSimulate: Boolean): RunMode;

Implementation

Uses AnStr, Dos, StrUtil, Globals;

{************************************************************************}
{* Rutin:       CommandLine                                             *}
{************************************************************************}
{* Inneh†ll:    Kollar vad som finns p† kommandoraden                   *}
{* Definition:  Function CommandLine(Var StdErr: Text; Var IniFile:     *}
{*              String; Var Maint: Boolean; Var ForcePid: Boolean;      *}
{*                                                Var LeaveDates:       *}
{*              Boolean; Var DoSimulate: Boolean): RunMode;             *}
{************************************************************************}

Function CommandLine(Var StdErr: Text; Var IniFile: String; Var Maint: Boolean;
                     Var ForcePid: Boolean; Var LeaveDates: Boolean;
                     Var DoSimulate: Boolean): RunMode;
Var
  i, j, k, NameCount:   Byte;
  IsQuiet:              Boolean;
  WhatToDo:             RunMode;
  Data:                 String;
Begin
  { Standardv„rden }
  NameCount := 0;
  For i := 1 to 10 do
    Name[i] := 'Announcer';
  IniFile := Copy(ParamStr(0), 1, Length(ParamStr(0)) - 4) + '.INI';
  WhatToDo := DoPost;
  Maint := False;
  LeaveDates := False;
  IsQuiet := False;
  DoSimulate := False;

  { Avl„s kommandoraden }
  For i := 1 to ParamCount do begin
    Data := ParamStr(i);
    If Data[1] = '/' then begin
      j := 2;
      While j <= Length(Data) do
      begin
        Case UpCase(Data[j]) of
          'D': begin
            WhatToDo := DisplayData;
            If (Length(Data) > j) and (UpCase(Data[j + 1]) = 'M') then begin
              Maint := True;
              Inc(j); { Hoppa ”ver M:et }
            end;
          end;
          'F': If (Length(Data) > j) and (UpCase(Data[j + 1]) = 'A') then begin
            WhatToDo := PostForceAsk;
            Inc(j); { Hoppa ”ver A:et }
          end else
            WhatToDo := PostForce;
          'I': If Length(Data) > j then begin
            k := j + 1;
            While (k <= Length(Data)) and (Data[k] <> '/') do
              Inc(k);
            IniFile := FExpand(Copy(Data, j + 1, k - j - 1));
            j := k;
          end; { If }
          'L': LeaveDates := True;
          'P': ForcePID := True;
          'Q': begin
            StdoutOn(False);                    { D”da all sk„rmutdata }
            IsQuiet := True;
          end;
          'S': DoSimulate := True;
          '/': ;
          else begin
            If IsQuiet then begin
              StdoutOn(True);               { Visa sk„rmutdata }
            end;
            Writeln(StdErr, StrErrPar);
            Writeln(StdErr, Data);
            Writeln(StdErr, '^':j);
            Halt(3);
          end;
        end; { Case }
        Inc(j);
      end; { While }
    end else
      If Data[1] = '_' then begin
        { inget }
    end else begin
      If NameCount < 10 then begin
        Inc(NameCount);
        Name[NameCount] := RmUnderline(Data);
      end else begin
        If IsQuiet then
          StdoutOn(True);               { Visa sk„rmutdata }
        Writeln(StdErr, StrErrPar);
        Writeln(StdErr, Data);
        Halt(3);
      end; { If NameCount }
    end; { If '/' }
  end; { For i }

  If IsQuiet and (WhatToDo = PostForceAsk) then begin
    StdoutOn(True);               { Visa sk„rmutdata }
    Writeln(StdErr, StrErrPrc);
    Halt(3);
  end;

  CommandLine := WhatToDo;
End;

End.
