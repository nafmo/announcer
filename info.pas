{************************************************************************}
{* Modul:       Info.Pas                                                *}
{************************************************************************}
{* Inneh†ll:    Rutin f”r att visa postningsinformation                 *}
{************************************************************************}
{* Funktion:    Visar postningsinformation f”r en INI-fil               *}
{************************************************************************}
{* Rutiner:     DisplayInfo                                             *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.2  - 1997-04-18 - Utflyttat fr†n Announce.Pas                    *}
{************************************************************************}
Unit Info;

Interface

Uses
  Dos, Globals;

Procedure DisplayInfo(IniFile: String; Maint: Boolean; Idag: CompatDateTime);

{************************************************************************}

Implementation

Uses
  AnStr, NLS, ChekDate, MkString, MkFile, MkMisc, StrUtil, StdErrU;
{$IFDEF OS2}
Uses Os2DT;
{$ENDIF}

Const

  fmReadOnly  = $00;
  fmWriteOnly = $01;
  fmReadWrite = $02;

  fmDenyAll   = $10;
  fmDenyWrite = $20;
  fmDenyRead  = $30;
  fmDenyNone  = $40;

{************************************************************************}
{* Rutin:       DisplayInfo                                             *}
{************************************************************************}
{* Inneh†ll:    Visar information om postning                           *}
{* Definition:  Procedure DisplayInfo(IniFile: String);                 *}
{************************************************************************}

Procedure DisplayInfo(IniFile: String; Maint: Boolean; Idag: CompatDateTime);
Var
  Ini:                                          Text;
  DataFile, NewDataFile:                        File of DataFileRec;
  CurrentRec:                                   DataFileRec;
  Counter, DaysSince, Interval, OnDate, Temp:   Word;
  MinSize, FDate:                               LongInt;
  Rad, Data, SemaphorFile, MsgFile:             String;
  Found, UpdatedSend, PlaceHolder:              Boolean;
  TmpFile:                                      File;
  FileDate:                                     DateTime;
  {$IFDEF OS2}
  LastWrittenDT, IdagDT:                        DateTime;
  {$ENDIF}
Begin
  Assign(Ini, IniFile);
  {$I-}
  Reset(Ini);
  If IOResult <> 0 then begin
    { Kolla om filen finns med till„gget .INI }
    Assign(Ini, IniFile + '.INI');
    Reset(Ini);
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrOp1, IniFile, StrErrOp2);
      Writeln(StdErr, IniFile, '.INI');
      Halt(1);
    end; { If IOResult }
    IniFile := IniFile + '.INI';
    Writeln(#254#32, IniFile);
  end else { If IOResult }
    Writeln(#254#32, IniFile);

  { ™ppna datafilen }
  Assign(DataFile, Copy(IniFile, 1, length(IniFile) - 4) + '.DAT');
  Reset(DataFile);
  If IOResult <> 0 then begin
    Writeln(StdErr, StrErrDaf, Copy(IniFile, 1, length(IniFile) - 4) + '.DAT');
    Halt(1);
  end; { If IOResult }

  { Namn„ndra datafilen om vi k”r i maintanence-l„ge, och ”ppna en ny }
  If Maint = True then begin
    Close(DataFile);
    Rename(DataFile, Copy(IniFile, 1, length(IniFile) - 4) + '.OLD');
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrDar);
      Halt(1);
    end; { If IOResult }
    Reset(DataFile);
    FileMode := fmReadWrite or fmDenyWrite;
    Assign(NewDataFile, Copy(IniFile, 1, length(IniFile) - 4) + '.DAT');
    Rewrite(NewDataFile);
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrDat, Copy(IniFile, 1, length(IniFile) - 4), '.DAT');
      Halt(1);
    end; { If IOResult }
    FileMode := fmReadOnly or fmDenyNone;
  end; { If Maint }
  {$I+}

  Counter := 0;
  While not eof(DataFile) do begin
    Read(DataFile, CurrentRec);
    Inc(Counter);
    Found := False;
    UpdatedSend := False;

    If not eof(Ini) then begin
      { Leta efter mallen }
      Repeat
        Readln(Ini, Rad);
      Until (UpStr(Rad) = 'MSG') or (UpStr(Rad) = 'PLACEHOLDER') or Eof(Ini);

      If not eof(Ini) then begin
        If UpStr(Rad) <> 'PLACEHOLDER' then begin
          Found := True;
          PlaceHolder := False;
          Interval := 0;
          OnDate := 0;
          SemaphorFile := '';
          MinSize := -1;
          Repeat
            Readln(Ini, Rad);
            Rad := UpStr(Rad);
            If Copy(Rad, 1, 8) = 'INTERVAL' then begin
              Data := Copy(Rad, 10, Length(Rad)-9);
              If Data[1] = '@' then
                Val(Copy(Data, 2, Length(Data)-1), OnDate, Temp)
              else
                Val(Data, Interval, Temp);
            end else if Copy(Rad, 1, 7) = 'MINSIZE' then begin
              Data := Copy(Rad, 9, Length(Rad)-8);
              Val(Data, MinSize, Temp);
            end else if Copy(Rad, 1, 9) = 'SEMAPHORE' then
              SemaphorFile := Copy(Rad, 11, Length(Rad)-10)
            else if Copy(Rad, 1, 4) = 'FILE' then
              MsgFile := Copy(Rad, 6, Length(Rad)-5)
            else if Rad = 'UPDATEDSEND YES' then
              UpdatedSend := True;
          Until Rad = '.END';
        end else begin { Placeholder }
          PlaceHolder := True;
        end;
      end; { If not eof }
    end; { If not eof }

    If CurrentRec.LastWritten.Day <> 0 then begin
      {$IFDEF OS2}
      LastWrittenDT := DosDateTime2Os2DateTime(CurrentRec.LastWritten);
      IdagDT := DosDateTime2Os2DateTime(Idag);
      Write(StrInfMsg, Counter, StrInfLst, NLS.DateStr(LastWrittenDT),
            StrInfClk, NLS.TimeStr(LastWrittenDT), ' (');
      DaysSince := check_date(FormattedDate(IdagDT, 'MM-DD-YY'),
                              FormattedDate(LastWrittenDT, 'MM-DD-YY'));
      {$ELSE}
      Write(StrInfMsg, Counter, StrInfLst, NLS.DateStr(CurrentRec.LastWritten),
            StrInfClk, NLS.TimeStr(CurrentRec.LastWritten), ' (');
      DaysSince := check_date(FormattedDate(Idag, 'MM-DD-YY'),
                              FormattedDate(CurrentRec.LastWritten, 'MM-DD-YY'));
      {$ENDIF}
      Case DaysSince of
      0: Writeln(StrInfTod);
      1: Writeln(StrInfYst);
      else
        Writeln(DaysSince, StrInfAgo);
      end; { Case }
    end else begin
      Writeln(StrInfNop);
    end; { If Day <> 0 }

    If CurrentRec.MsgIdString <> '' then
      Writeln(StrInfLat, CurrentRec.MsgIdString, ' ',
              LongWord(CurrentRec.MsgIdNum));

    FDate := 0;

    If Found then begin
      { Kontrollera intervall }
      If Interval <> 0 then begin
        Write(StrInfInt, Interval, StrInfDag, StrInfDa2);
        If DaysSince < Interval then
          Writeln(StrInfLes)
        else
          Writeln(StrInfMor);
      end; { If Interval }
      { Kontrollera postningsdatum }
      If OnDate <> 0 then begin
        Write(StrInfDat, OnDate, StrInfDa2);
        If OnDate <> Idag.Day then
          Writeln(StrInfLes)
        else
          If DaysSince = 0 then
            Writeln(StrNotIn5, '.')
          else
            Writeln(StrInfMor);
      end; { If OnDate }
      { Kontrollera semaforfil }
      If SemaphorFile <> '' then begin
        Write(StrInfSem);
        If FileExist(SemaphorFile) then
          Writeln(StrInfSye)
        else
          Writeln(StrInfSno);
        {$I+}
      end; { If SemaphorFile }
      { Kontrollera minsta storlek }
      If MinSize <> -1 then begin
        Write(StrInfMin, MinSize, StrInfMi2);
        Assign(TmpFile, MsgFile);
        {$I-}
        Reset(TmpFile, 1);
        If IOResult = 0 then begin
          If Filesize(TmpFile) > MinSize then
            Writeln(StrInfMye)
          else
            Writeln(StrInfMno);
          GetFTime(TmpFile, FDate);
          Close(TmpFile);
        end else
          Writeln(StrInfMno);
        {$I+}
      end; { If MinSize }
      { Kontrollera om filen „r uppdaterad }
      If UpdatedSend then begin
        Write(StrInfUpd);
        If FDate = 0 then begin { Ingen undansparad filtid }
          Assign(TmpFile, MsgFile);
          {$I-}
          Reset(TmpFile, 1);
          If IOResult = 0 then begin
            GetFTime(TmpFile, FDate);
            Close(TmpFile);
          end else
            Write(StrInfUno);
          {$I+}
        end;
        If FDate <> 0 then begin
          UnpackTime(FDate, FileDate);
          If DTToUnixDate(FileDate) <=
          {$IFDEF OS2}
             DTToUnixDate(LastWrittenDT)
          {$ELSE}
             DTToUnixDate(CurrentRec.LastWritten)
          {$ENDIF}
             then
            Write(StrInfUno);
        end;
        Writeln(StrInfUp2);
      end;
      If Maint then Write(NewDataFile, CurrentRec);
    end else begin { If found }
      If PlaceHolder then begin
        Writeln(StrInfPlc);
        If Maint then begin
          FillChar(CurrentRec, SizeOf(CurrentRec), #0);
          Write(NewDataFile, CurrentRec);
          Writeln(StrInfZer);
        end;
      end else begin
        Writeln(StrInfFnn);
        If Maint then Writeln(StrInfRem);
      end;
    end; { If Found }

  end; { While not eof }

  If not eof(Ini) then begin
    Counter := 0;
    While not eof(Ini) do begin
      Readln(Ini, Rad);
      If (UpStr(Rad) = 'MSG') or (UpStr(Rad) = 'PLACEHOLDER') then
        Inc(Counter);
    end; { While not eof }
    If Counter <> 0 then
      Write(Counter, StrInfYtt);
  end; { If not eof }

  If Maint then begin
    Close(DataFile);
    Erase(DataFile);
    Close(NewDataFile);
  end; { If Maint }

  Close(Ini);
end;

end.
