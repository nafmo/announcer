{************************************************************************}
{* Modul:       CmdLine.Pas                                             *}
{************************************************************************}
{* Inneh†ll:    Kommandoradsparser                                      *}
{************************************************************************}
{* Funktion:    Tar hand om kommandoraden                               *}
{************************************************************************}
{* Rutiner:                                                             *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.11 - 1997-01-21 - F”rsta versionen                               *}
{************************************************************************}
Unit CmdLine;

{$D-,G+,X+}

Interface

Type
  RunMode = (DoPost, DisplayData, Simulate);

Function CommandLine(Var StdErr: Text; Var IniFile: String; Var Maint: Boolean;
                     Var ForcePid: Boolean; Var Name1: String;
                     Var Name2: String): RunMode;

Implementation

Uses AnStr, Dos, StrUtil;

{************************************************************************}
{* Rutin:       ParseCmdLine                                            *}
{************************************************************************}
{* Inneh†ll:    Kollar vad som finns p† kommandoraden                   *}
{* Definition:                                                          *}
{************************************************************************}

Function CommandLine(Var StdErr: Text; Var IniFile: String; Var Maint: Boolean;
                     Var ForcePid: Boolean; Var Name1: String;
                     Var Name2: String): RunMode;
Var
  i, j, NameCount:      Byte;
  EndSwitchNow:         Boolean;
  WhatToDo:             RunMode;
  Data:                 String;
Begin
  { Standardv„rden }
  NameCount := 0;
  Name1 := 'Announcer';
  Name2 := Name1;
  IniFile := Copy(ParamStr(0), 1, Length(ParamStr(0)) - 4) + '.INI';
  WhatToDo := DoPost;
  Maint := False;

  { Avl„s kommandoraden }
  For i := 1 to ParamCount do begin
    Data := ParamStr(i);
    If Data[1] = '/' then begin
      EndSwitchNow := False;
      j := 2;
      While (Not EndSwitchNow) and (j <= Length(Data)) do
      begin
        Case UpCase(Data[j]) of
          'I': If Length(Data) > j then begin
                 IniFile := FExpand(Copy(ParamStr(i), j + 1,
                                    Length(ParamStr(i)) - j));
                 EndSwitchNow := True;
               end; { If }
          'D': WhatToDo := DisplayData;
          'M': Maint := True;
          'S': WhatToDo := Simulate;
          'Q': begin
            Assign(Output, 'NUL');
            Rewrite(Output);
          end;
          'P': ForcePID := True;
          '/': ;
          else begin
            Writeln(StdErr, StrErrPar);
            Writeln(StdErr, Data);
            Halt(3);
          end;
        end; { Case }
        Inc(j);
      end; { While }
    end else begin
      Case NameCount of
        0: begin
             Name1 := RmUnderline(Data);
             NameCount := 1;
           end;
        1: begin
             Name2 := RmUnderline(Data);
             NameCount := 2;
           end;
        2: begin
             Writeln(StdErr, StrErrPar);
             Writeln(StdErr, Data);
             Halt(3);
           end;
      end; { Case NameCount }
    end; { If '/' }
  end; { For i }

  CommandLine := WhatToDo;
End;

End.
