{************************************************************************}
{* Program:     Announcer                                               *}
{************************************************************************}
{* F”rfattare:  Peter Karlsson                                          *}
{* Datum:       (se nedan)                                              *}
{* Version:     1.11                                                    *}
{************************************************************************}
{* Moduler:                                                             *}
{************************************************************************}
{************************************************************************}
{* Modul:       Announce.Pas                                            *}
{************************************************************************}
{* Inneh†ll:    Announcers huvudprogram                                 *}
{************************************************************************}
{* Funktion:    Postar filer i lokala brevareor                         *}
{************************************************************************}
{* Rutiner:                                                             *}
{************************************************************************}
{* Revision:                                                            *}
{*  v0.10 - 1995-03-08 - F”rsta versionen                               *}
{*  v0.11 - 1995-07-19 - Strippar tecken under #32 (ej CRLF)            *}
{*  v0.20 - 1995-08-01 - Kan ta annan konf.fil och namn p† kommandorad  *}
{*  v0.21 - 1995-08-19 - Kollar om konfigurationsfilen existerar.       *}
{*  v0.22 - 1995-10-28 - Taglines + lite annat skoj                     *}
{*  v0.23 - 1995-10-31 - Registreringskod ska fungera                   *}
{*  v0.25 - 1995-11-09 - Loggfil                                        *}
{*  v0.30 - 1996-01-07 - MSGID igen, netmail, echomail, slumptaglinefil *}
{*  v0.31 - 1996-02-03 - ReadRandomLine f”rb„ttrat, intervall           *}
{*  v1.00 - 1996-04-27 - M”jlighet att visa data, /Q, /M                *}
{*  v1.10 - 1996-08-14 - Valbar REPLY, semaforfiler, SPLIT, omvandlings-*}
{*                       tabeller, kollar s† tillr„ckligt med data      *}
{*                       givits, kan skapa PKT-filer, PID-st”d          *}
{*  v1.11 - 1997-03-05 - St”d f”r paket enligt FSC-0048, fast breddsteg,*}
{*                       ber„knar splitstorlek ”ver hela texten, /S,    *}
{*                       PlaceHolder                                    *}
{************************************************************************}
Program Announcer;

{$I MKB.Def}
{$D-,G+,X+}

Uses Dos, MKFile, MKString, MKMsgAbs, MKOpen, MKGlobT, MKDos, MKMisc, NLS,
     Crypt, AnHelp, AnStr, ChekDate, PktHead, StrUtil, CmdLine;

Const
  Version  = 'v1.11';
  VerMaj   = 1;
  VerMin   = 11;
  {*$*DEFINE BETA}
  {*$*DEFINE GAMMA}
  LogName  = ' ANNO ';
  BragLine: string = 'Announcer ' + Version;

  fmReadOnly  = $00;
  fmWriteOnly = $01;
  fmReadWrite = $02;

  fmDenyAll   = $10;
  fmDenyWrite = $20;
  fmDenyRead  = $30;
  fmDenyNone  = $40;

Var
  Registration, EchoTossLogFile:                                String;
  BragLineIntro, TagLineIntro:                                  String[3];
  LogFile, StdErr:                                              Text;
  LogToFile, ReplyKludge, PktMode, ForcePID, Fsc0048:           Boolean;
  MsgIdString:                                                  String[32];
  MsgIdNum:                                                     LongInt;
  MsgWritten, Ctr:                                              Word;
  Idag:                                                         DateTime;
  ExitSave:                                                     Pointer;

Type
  MsgType = (Local, NetMail, EchoMail);
  CurrPartType = (Header, MainText, Footer, Finished);
  DataFileRec = Record
                  LastWritten: DateTime;
                  MsgIdString: String[32];
                  MsgIdNum: LongInt;
                end;
  FileOfDataFileRec = File Of DataFileRec;
  MsgHeader = record
                FromName,
                ToName:    Array[0..35] of char;
                Subject:   Array[0..71] of char;
                DateTime:  Array[0..19] of char;
                TimesRead,
                DestNode,
                OrigNode,
                Cost,
                OrigNet,
                DestNet,
                DestZone,
                OrigZone,
                DestPoint,
                OrigPoint,
                ReplyTo,
                Attribute,
                NextReply: Word;
              end;
  Buffer = array[0..1023] of char;
  Attributes = Set of (CrashMail, KillSent, FAttach, FileReq, Private, Hold);

{************************************************************************}
{* Rutin:       Leave                                                   *}
{************************************************************************}
{* Inneh†ll:    Avslutar Announcer vid k”rtidsfel                       *}
{* Definition:  Procedure Leave;                                        *}
{************************************************************************}

{$F+}
Procedure Leave;
Var
  RunTime: String[9];
Begin
  ExitProc := ExitSave;
  If ErrorAddr <> nil then begin
    RunTime := HexLong(Seg(ErrorAddr^) * $10000 + Ofs(ErrorAddr^));
    RunTime := Copy(RunTime, 1, 4) + ':' + Copy(RunTime, 5, 4);
    Writeln(StrLogRun, ExitCode, StrLogRn2, RunTime);
  end;
  If LogToFile then begin
    If ErrorAddr <> nil then
      Writeln(LogFile, '! ', LogTime, LogName, StrLogRun, ExitCode, StrLogRn2,
              RunTime);
    Writeln(LogFile, '+ ', LogTime, LogName, StrLogEnd, BragLine, ' (',
            MsgWritten, StrLogEn2);
    Close(LogFile);
    LogToFile := False;
  end;
  ErrorAddr := nil;
End;
{$F-}

{************************************************************************}
{* Rutin:       DoMessage                                               *}
{************************************************************************}
{* Inneh†ll:    Framst„ller ett meddelande enligt angivna parametrar    *}
{* Definition:  Function DoMessage(mFrom, mTo, Subj, FName, MsgBas:     *}
{*              String; TagLine, Origin: String; AreaType: MsgType; Orig,}
{*              Dest: AddrType; EchoTag: String; Var CurrentRec:        *}
{*              DataFileRec; HeaderFile, FooterFile: String; Parts: Byte;}
{*              Size: LongInt; Charset: CharsetType; CreateFile: String;*}
{*              MsgAttr: Attributes; FixedWidth: Boolean): Boolean;     *}
{************************************************************************}

Function DoMessage(mFrom, mTo, Subj, FName, MsgBas: String; TagLine, Origin:
                   String; AreaType: MsgType; Orig, Dest: AddrType; EchoTag:
                   String; Var CurrentRec: DataFileRec; HeaderFile,
                   FooterFile: String; Parts: Byte; Size: LongInt; Charset:
                   CharsetType; CreateFile: String; MsgAttr: Attributes;
                   FixedWidth: Boolean): Boolean;
Var
  TF, Head, Foot, Current, ListNames:                   TFile;
  CurrentIndicator:                                     CurrPartType;
  TmpStr, TmpStr2, ReplyString, ListName, IDString,
  EffectiveMsgIDString, ReplyIDString:                  String;
  SplitKludge:                                          String[63];
  Msg:                                                  AbsMsgPtr;
  i:                                                    Byte;
  EchoToss:                                             Text;
  WriteEchoToss, MoreNames, MailingList, DoneOne,
  DidPost:                                              Boolean;
  MsgNum, TextSize, NextSplit, ReplyNum,
  AccumulatedSize:                                      LongInt;
  TempAddr:                                             AddrType;

 {************************************************************************}
 {* Rutin:       DoHeader                                                *}
 {************************************************************************}
 Procedure DoHeader(Subj: String);
 begin
   Case AreaType of
     Local: begin
       Msg^.SetMailType(mmtNormal);  { M”testyp }
       Msg^.StartNewMsg;
       Msg^.SetEcho(False);          { Ska ej ekas }
       Msg^.SetPriv(Private in MsgAttr);
     end;
     NetMail: begin
       Msg^.SetMailType(mmtNetmail);
       Msg^.StartNewMsg;
       Msg^.SetOrig(Orig);           { Avs„ndaradress }
       Msg^.SetDest(Dest);
       Msg^.SetEcho(True);           { Ska ekas }
       Msg^.SetPriv(True);
       { FMPT och TOPT kr„vs ibland f”r att f† adresserna r„tt,
         de skrivs automatiskt i MSG och Hudson. I JAM ignoreras de „nd† }
       If (UpCase(MsgBas[1]) <> 'F') and (UpCase(MsgBas[1]) <> 'H') then
       begin
         If Orig.point <> 0 then
           Msg^.DoKludgeLn(#1'FMPT ' + Long2Str(Orig.point));
         If Dest.point <> 0 then
           Msg^.DoKludgeLn(#1'TOPT ' + Long2Str(Dest.point));
       end;
     end;
     EchoMail: begin
       Msg^.SetMailType(mmtEchomail);
       Msg^.StartNewMsg;
       Msg^.SetOrig(Orig);
       Msg^.SetEcho(True);
       Msg^.SetPriv(False);
       If PktMode then
         Msg^.DoStringLn('AREA:' + EchoTag);
     end;
   end; { Case }

   Msg^.SetRefer(0);

   { Meddelandeheader }
   Msg^.SetFrom(mFrom);
   Msg^.SetTo(mTo);
   Msg^.SetSubj(Subj);
   Msg^.SetDate(mkstring.DateStr(GetDosDate));
   Msg^.SetTime(mkstring.TimeStr(GetDosDate));
   Msg^.SetLocal(True);

   { Attribut }
   If AreaType <> EchoMail then begin
     Msg^.SetCrash(CrashMail in MsgAttr);
     Msg^.SetKillSent(KillSent in MsgAttr);
     Msg^.SetFAttach(FAttach in MsgAttr);
     Msg^.SetFileReq(FileReq in MsgAttr);
     If (UpCase(MsgBas[1]) <> 'H') or Not FixedWidth then
       Msg^.SetHold(Hold in MsgAttr);
   end;

   { Undvik dubbla FLAGS-rader i Hudson (Hudson har inget HOLD-attribut) }
   If (UpCase(MsgBas[1]) = 'H') and (Hold in MsgAttr) and FixedWidth then
     Msg^.DoKludgeLn(#1'FLAGS NPD HLD')
   else If FixedWidth then
     Msg^.DoKludgeLn(#1'FLAGS NPD');

   { Skapa MSGID, REPLY, SPLIT och NOTE-kludgar }
   If EffectiveMsgIDString <> '' then
     Msg^.DoKludgeLn(#1'MSGID: ' + EffectiveMsgIDString);
   If ReplyIDString <> '' then
     Msg^.DoKludgeLn(#1'REPLY: ' + ReplyIDString);
   If SplitKludge <> '' then
     Msg^.DoKludgeLn(SplitKludge);
   If ListName <> '' then
     Msg^.DoKludgeLn(#1'NOTE: Mailing list "' + ListName + '"');
   If Registration = StrNotReg then
     Msg^.DoKludgeLn(#1'NOTE: Unregistered evaluation version');

   { CHRS-kludge }
   Case Charset of
     Pc8, FromIso, FromSjuBit:
          Msg^.DoKludgeLn(#1'CHRS: IBMPC 2');
     Sv7: Msg^.DoKludgeLn(#1'CHRS: SWEDISH 1');
     Iso: Msg^.DoKludgeLn(#1'CHRS: LATIN-1 2');
   end; { Case } { ASCII ger ingen kludge }

   { PID-kludge }
   If ForcePID then
     Msg^.DoKludgeLn(#1'PID: ' + BragLine);

   { Avsluta kludgar (Squish) }
   Msg^.EndKludges;
 end;

 {************************************************************************}
 {* Rutin:       DoFooter                                                *}
 {************************************************************************}
 Procedure DoFooter;
 Var
   TmpStr:                                       String;
 Begin
   If Not ForcePID then
     Msg^.DoStringLn(BragLineIntro + ' ' + BragLine);

   If AreaType = EchoMail then begin
     { Alltid tearline i echomail, f”rutom i PID-l„ge }
     If Not ForcePID and (BragLineIntro <> '---') then
       Msg^.DoStringLn('---');
     { Origin i echomail om ej i PID-l„ge, dock alltid i PKT }
     If PktMode or Not ForcePID then begin
       If Origin <> '' then begin
         TmpStr := Origin + ' (' + AddrStr(Orig) + ')';
         If Length(TmpStr) > 68 then
           TmpStr := Copy(TmpStr, Length(TmpStr) - 67, 68);
       end else
         TmpStr := '(' + AddrStr(Orig) + ')';
       Msg^.DoStringLn(' * Origin: ' + TmpStr);
     end;

     If PktMode then begin { PATH & SEEN-BY }
       If Orig.Point = 0 then
         Msg^.DoStringLn('SEEN-BY: ' + Long2Str(Orig.Net) + '/' +
                         Long2Str(Orig.Node));
       Msg^.DoKludgeLn(#1'PATH: ' + Long2Str(Orig.Net) + '/' +
                       Long2Str(Orig.Node));
     end;
   end;

   If AreaType = NetMail then
     Msg^.DoKludgeLn(#1'Via ' + AddrStr(Orig) +
                     FormattedDate(idag, ' @YYYYMMDD.HHIISS ') + BragLine);
 end;
{************************************************************************}
begin

  If (Charset <> Pc8) and Not (Charset in [FromISO, FromSjuBit]) then begin
    mFrom := Convert(mFrom, Charset);
    mTo := Convert(mTo, Charset);
    Subj := Convert(Subj, Charset);
    Origin := Convert(Origin, Charset);
    TagLine := Convert(TagLine, Charset);
  end;

  DidPost := False;

  IDString := '';
  If Parts = 0 then
    Parts := 1;

  MoreNames := True;
  DoneOne := False;

  MailingList := mTo[1] = '@';

  If MailingList then begin
    ListNames.Init;
    ListName := copy(mTo, 2, length(mTo) - 1);
    If not ListNames.OpenTextFile(ListName) then begin
      MailingList := False;
      ListNames.Done;
    end; { if not opentextfile }
  end else
    ListName := '';

  While MoreNames do begin
    if MailingList then begin
      If not DoneOne then begin
        TmpStr := ListNames.GetString;
        if TmpStr[1] = ';' then begin
          ListName := Copy(TmpStr, 2, 75);
          TmpStr := ListNames.GetString;
        end;
      end;
      i := Pos(' ', TmpStr);
      TmpStr2 := Copy(TmpStr, 1, i - 1);
      ParseAddr(TmpStr2, TempAddr, Dest);
      mTo := Copy(TmpStr, i + 1, 36);
    end; { If MailingList }

    TF.Init;                                    { Initiera textfilsobjekt   }

    If HeaderFile <> '' then
      Head.Init;                                { Initiera headerfilsobjekt }

    If FooterFile <> '' then
      Foot.Init;                                { Initiera footerfilsbjekt  }

    If TF.OpenTextFile(FName) then begin        { ™ppna textfilen           }
      TextSize := FileSize(TF.TF^.BufferFile);          { Storlek av texten }

      Current := TF;            { B”rja med texten }
      CurrentIndicator := MainText;

      If HeaderFile <> '' then begin
        If Head.OpenTextFile(HeaderFile) then begin
          Inc(TextSize, FileSize(Head.TF^.BufferFile)); { plus storlek av   }
          Current := Head;      { Nej, med huvudet }    { headerfilen       }
          CurrentIndicator := Header;
        end else begin
          HeaderFile := '';     { Fanns inte }
          Head.Done;
        end;
      end;

      If FooterFile <> '' then begin
        If Foot.OpenTextFile(FooterFile) then begin
          Inc(TextSize, FileSize(Foot.TF^.BufferFile)); { plus storlek av   }
        end else begin                                  { footerfilen       }
          FooterFile := '';     { Fanns inte }
          Foot.Done;
        end;
      end;

      AccumulatedSize := 0;

      If Size <> 0 then                         { R„kna ut antalet delar     }
        Parts := (TextSize div Size) + 1;

      NextSplit := TextSize div Parts + 1;      { Var ska n„sta del b”rja?   }

      If ((MsgBas[1] = 's') or (MsgBas[1] = 'S')) and (NextSplit > 32800) then begin
        Parts := (TextSize div 33000) + 1;   { utvecklingspaketet klarar 33k }
        NextSplit := TextSize div Parts + 1; { max i Squishdatabaser         }
      end;

      If NextSplit < 160 then begin             { Minsta storlek = ca. 2 rader }
        Parts := (TextSize div 160) + 1;
        NextSplit := TextSize div Parts + 1;
      end;

      If Parts > 1 then begin                   { Initiera ev. SPLIT-kludge }
        SplitKludge := #1'SPLIT:                    @                  01/   +++++++++++';
        SplitKludge[50] := Char(48 + Parts div 10);
        SplitKludge[51] := Char(48 + Parts mod 10);
        TmpStr := LogTime;
        TmpStr := Copy(TmpStr, 1, 7) + Char(48 + (Idag.Year div 10) mod 10) +
                  Char(48 + Idag.Year mod 10) + Copy(TmpStr, 7, 9);
        Move(TmpStr[1], SplitKludge[9], 18);
        Str(Orig.Net, TmpStr);
        Str(Orig.Node, TmpStr2);
        TmpStr := TmpStr + '/' + TmpStr2;
        Move(TmpStr[1], SplitKludge[29], Length(TmpStr));
        Str(MsgWritten, TmpStr);
        Move(TmpStr[1], SplitKludge[41], Length(TmpStr));
      end else
        SplitKludge := '';

      If OpenMsgArea(Msg, MsgBas) then begin

        If AreaType = Local then
          IDString := MsgIdString
        else
          IDString := AddrStr(Orig);

        If IDString <> '' then
          EffectiveMsgIDString := IDString + ' ' + LongWord(MsgIdNum)
        else
          EffectiveMsgIDString := '';

        ReplyIDString := '';
        ReplyString := CurrentRec.MsgIdString;
        ReplyNum := CurrentRec.MsgIdNum;
        If ReplyKludge and not MailingList and (ReplyString <> '') then
          ReplyIDString := ReplyString + ' ' + LongWord(ReplyNum);

        If not DoneOne then begin
          CurrentRec.MsgIdString := IDString;
          CurrentRec.MsgIdNum := MsgIdNum;
        end;

        Inc(MsgIdNum);
        DoHeader(Subj);

        { L„s in texten }

        While CurrentIndicator <> Finished do begin
          TmpStr := Current.GetString;

          While Current.Stringfound do begin
            If Current.GetTextPos + AccumulatedSize > NextSplit then begin
              { Dags att dela av }
              Inc(NextSplit, TextSize div Parts + 1);
              SplitKludge[48] := Char(Byte(SplitKludge[48]) + 1); { ™ka r„knaren }
              If SplitKludge[48] = ':' then begin
                SplitKludge[47] := Char(Byte(SplitKludge[47]) + 1);
                SplitKludge[48] := '0';
              end;
              If TmpStr = '' then
                TmpStr := Current.GetString;

              DoFooter;

              { Skriv det, logga om det inte lyckades }
              if Msg^.WriteMsg <> 0 then begin
                Writeln(StrErrSav, Subj, '"');
                If LogToFile then Writeln(LogFile, '! ', LogTime, LogName,
                                          StrLogSav, Ctr);
              end else begin
                MsgNum := Msg^.GetMsgNum;
                Writeln(StrDidSav, MsgNum, StrDidSv2, MsgBas, StrDidSv3, Ctr,
                        ')');
                If LogToFile then begin
                  Write(LogFile, '  ', LogTime, LogName, StrDidSav, MsgNum,
                        StrDidSv2);
                  If (AreaType = EchoMail) and (EchoTag <> '') then
                    Write(LogFile, EchoTag)
                  else
                    Write(LogFile, MsgBas);
                  Writeln(LogFile, StrDidSv3, Ctr, ')');
                end;
              end;

              { P†b”rja n„sta meddelande }
              If IDString <> '' then
                EffectiveMsgIDString := IDString + ' ' + LongWord(MsgIDNum);
              Inc(MsgIdNum);

              DoHeader(Subj + Copy(SplitKludge, 46, 6));
            end; { If splithere }

            TmpStr2 := '';
            For i := 1 to Length(TmpStr) do
              If (TmpStr[i] >= #32) then
                TmpStr2 := TmpStr2 + TmpStr[i];
            If Charset <> Pc8 then
              TmpStr2 := Convert(TmpStr2, Charset);
            Msg^.DoStringLn(TmpStr2);
            TmpStr := Current.GetString;
          end; { While }
          Inc(AccumulatedSize, FileSize(Current.TF^.BufferFile));

          If Current.CloseTextFile then;

          { Klar med denna textfil, ta nu ev. n„sta }
          If CurrentIndicator = Header then begin { om nu header, ta kropp }
            CurrentIndicator := MainText;
            Current := TF;
          end else If (CurrentIndicator = MainText) and (FooterFile <> '') then begin
            CurrentIndicator := Footer; { om nu kropp, och finns fot, ta fot }
            Current := Foot;
          end else begin
            CurrentIndicator := Finished; { annars avsluta }
          end; { If }

        end; { While }

        { Avsluta }
        If TagLine <> '' then begin
          If TmpStr2 <> '' then
            Msg^.DoStringLn(''); { Tomrad f”re tagline }
          Msg^.DoStringLn(TagLineIntro + ' ' + TagLine);
        end;

        DoFooter;

        { Skriv det, logga om det inte lyckades }
        If Msg^.WriteMsg <> 0 then begin
          Writeln(StrErrSav, Subj, '"');
          If LogToFile then Writeln(LogFile, '! ', LogTime, LogName, StrLogSav,
                                    Ctr);
        end else begin
          Inc(MsgWritten);
          DidPost := True;
          MsgNum := Msg^.GetMsgNum;
          Writeln(StrDidSav, MsgNum, StrDidSv2, MsgBas, StrDidSv3, Ctr, ')');
          If LogToFile then begin
            Write(LogFile, '  ', LogTime, LogName, StrDidSav, MsgNum,
                  StrDidSv2);
            If (AreaType = EchoMail) and (EchoTag <> '') then
              Write(LogFile, EchoTag)
            else
              Write(LogFile, MsgBas);
            Writeln(LogFile, StrDidSv3, Ctr, ')');
          end;

          { Skriv post i Echotoss.log-filen }
          If (EchoTag <> '') and (EchoTossLogFile <> '') and
             (PktMode = False) then begin
            WriteEchoToss := True;
            FileMode := fmReadWrite or fmDenyAll;
            Assign(EchoToss, EchoTossLogFile);
            {$I-}
            Reset(EchoToss);
            If IOResult = 0 then begin
              While (not eof(EchoToss)) do begin
                Readln(EchoToss, TmpStr);
                If UpStr(TmpStr) = EchoTag then
                  WriteEchoToss := False;
              end; { While }
              Close(EchoToss);
            end else begin
              Rewrite(EchoToss);
              If IOResult <> 0 then begin
                Writeln(StdErr, StrErrTos, EchoTossLogFile);
                If LogToFile then Writeln(LogFile, '! ', LogTime, LogName,
                                          StrLogTos, EchoTossLogFile);
              end else begin
                Writeln(EchoToss, EchoTag);
                Close(EchoToss);
              end; { If IOResult }
              WriteEchoToss := False;
            end; { If IOResult }

            If WriteEchoToss = True then begin
              Append(EchoToss);
              If IOResult <> 0 then begin
                Writeln(StdErr, StrErrTo2, EchoTossLogFile);
                If LogToFile then Writeln(LogFile, '! ', LogTime, LogName,
                                          StrLogTo2, EchoTossLogFile);
              end else begin
                Writeln(EchoToss, EchoTag);
                Close(EchoToss);
              end; { If IOResult }
            end; { If WriteEchoToss }

            FileMode := fmReadOnly or fmDenyNone;
            {$I+}
          end; { If ska skriva till echotosslog }

          If CreateFile <> '' then begin { Skapa semaforfil }
            Assign(EchoToss, CreateFile);
            {$I-}
            Rewrite(EchoToss);
            If IOResult <> 0 then begin
              Writeln(StdErr, StrLogCrf, CreateFile);
              If LogToFile then Writeln(LogFile, '! ', LogTime, LogName,
                                        StrLogCrf, CreateFile);
            end else begin
              Close(EchoToss);
              Writeln(StdErr, StrLogCrs, CreateFile);
              If LogToFile then Writeln(LogFile, '  ', LogTime, LogName,
                                        StrLogCrs, CreateFile);
            end; { If IOResult }
          end; { If CreateFile }
        end; { If Msg^.WriteMsg }
        If CloseMsgArea(Msg) then;
      end else begin
        Writeln(StrErrBas, MsgBas);
        If LogToFile then Writeln(LogFile, '! ', LogTime, LogName, StrLogBas,
                                  MsgBas);
      end;
    end else begin
      Writeln(StrErrFil, FName);
      If LogToFile then Writeln(LogFile, '! ', LogTime, LogName, StrLogFil,
                                FName);
    end; { If OpenTextFile }

    TF.Done;
    If HeaderFile <> '' then
      Head.Done;
    If FooterFile <> '' then
      Foot.Done;

    If MailingList then begin
      Repeat
        TmpStr := ListNames.GetString;
        MoreNames := ListNames.StringFound;
      Until (TmpStr <> '') or (MoreNames = False);
    end else
      MoreNames := False;

    DoneOne := True;
  end; { While MoreNames }

  If MailingList then begin
    If ListNames.CloseTextFile then;
    ListNames.Done;
  end;

  DoMessage := DidPost;
end;

{************************************************************************}
{* Rutin:       DisplayInfo                                             *}
{************************************************************************}
{* Inneh†ll:    Visar information om postning                           *}
{* Definition:  Procedure DisplayInfo(IniFile: String);                 *}
{************************************************************************}

Procedure DisplayInfo(IniFile: String; Maint: Boolean);
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
      Write(StrInfMsg, Counter, StrInfLst, NLS.DateStr(CurrentRec.LastWritten),
            StrInfClk, NLS.TimeStr(CurrentRec.LastWritten), ' (');
      DaysSince := check_date(FormattedDate(Idag, 'MM-DD-YY'),
                              FormattedDate(CurrentRec.LastWritten, 'MM-DD-YY'));
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
             DTToUnixDate(CurrentRec.LastWritten) then
            Write(StrInfUno);
        end;
        Writeln(StrInfUp2);
      end;
      If Maint then Write(NewDataFile, CurrentRec);
    end else begin { If found }
      If PlaceHolder then begin
        Writeln(StrInfPlc);
        If Maint then Write(NewDataFile, CurrentRec);
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

{************************************************************************}
{* Rutin:       BuildPacket                                             *}
{************************************************************************}
{* Inneh†ll:    Bygger ihop MSG-filer till en PKT-fil                   *}
{* Definition:  Procedure BuildPacket(PktSpec, MsgSpec: String;         *}
{*              PktFrom, PktTo: AddrType; PktPwd: String);              *}
{************************************************************************}

Procedure BuildPacket(PktSpec, MsgSpec: String; PktFrom, PktTo: AddrType;
                      PktPwd: String);
Var
  PktHead_p:                    ^PKTheader;
  PktMsg_p:                     ^PkdMSG;
  MsgHead_p:                    ^MsgHeader;
  Buff_p:                       ^Buffer;
  Temp, NumWritten, NumRead:    Word;
  PktFile, MsgFile:             File;
  FileSearch:                   SearchRec;
  i:                            Byte;
  LeftToWrite:                  LongInt;
  PktDidExist:                  Boolean;
Begin
  New(PktHead_p);
  New(PktMsg_p);
  New(MsgHead_p);
  New(Buff_p);
  If (PktHead_p <> nil) and (PktMsg_p <> nil) and (MsgHead_p <> nil) and
     (Buff_p <> nil) then begin
    FileMode := fmReadWrite or fmDenyAll;
    Assign(PktFile, PktSpec);
    {$I-}
    PktDidExist := True;
    Reset(PktFile, 1);
    If IOResult <> 0 then begin
      Rewrite(PktFile, 1);
      PktDidExist := False;
    end; { If }
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrPOp, PktSpec);
      If LogToFile then
        Writeln(LogFile, '- ', LogTime, LogName, StrErrPOp, PktSpec);
    end else begin
      {$I+}
      If PktDidExist then begin
        Seek(PktFile, FileSize(PktFile) - 2);
      end else begin
        FillChar(PktHead_p^, SizeOf(PKTHeader), #0);
        With PktHead_p^ do begin
          QOrgZone := PktFrom.Zone;
          OrgZone := PktFrom.Zone;
          If Fsc0048 and (PktFrom.Point <> 0) then begin
            OrgNet := $ffff;
            Filler := PktFrom.Net;
            ProdData := '0048';
          end else
            OrgNet := PktFrom.Net;
          OrgNode := PktFrom.Node;
          OrgPoint := PktFrom.Point;
          QDstZone := PktTo.Zone;
          DstZone := PktTo.Zone;
          DstNet := PktTo.Net;
          DstNode := PktTo.Node;
          DstPoint := PktTo.Point;
          GetDate(Year, Month, Day, Temp);
          Dec(Month); { Justera m†nadsnummer till 0-11 }
          GetTime(Hour, Min, Sec, Temp);
          PktVer := 2;
          PrdCodL := $fe; { No product ID allocated }
          CapValid := $100;
          CapWord := $1;
          PVMinor := VerMin; { Version }
          PVMajor := VerMaj;
          For i := 0 to 7 do
            If i < Length(PktPwd) then
              Password[i] := PktPwd[i+1];
        end; { With PktHead_p^ }
        BlockWrite(PktFile, PktHead_p^, SizeOf(PKTheader), NumWritten);
        Dispose(PktHead_p);
        If NumWritten <> SizeOf(PKTheader) then begin
          Writeln(StdErr, StrErrWri);
          If LogToFile then
            Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
        end; { If }
      end; { If }

      FindFirst(MsgSpec + '*.MSG', AnyFile - VolumeId, FileSearch);
      While DosError = 0 do begin
        {$I-}
        Assign(MsgFile, MsgSpec + FileSearch.Name);
        Reset(MsgFile, 1);
        If IOResult = 0 then begin
          {$I+}
          BlockRead(MsgFile, MsgHead_p^, SizeOf(MsgHeader), NumRead);
          If NumRead = SizeOf(MsgHeader) then begin
            FillChar(PktMsg_p^, SizeOf(PkdMSG), #0);
            With PktMsg_p^ do begin
              PktVer := $2;
              OrgNode := MsgHead_p^.OrigNode;
              DstNode := MsgHead_p^.DestNode;
              OrgNet := MsgHead_p^.OrigNet;
              DstNet := MsgHead_p^.DestNet;
              If (DstNet = 0) and (DstNode = 0) then begin
                DstNet := PktTo.Net;
                DstNode := PktTo.Node;
              end;
              Attribute := MsgHead_p^.Attribute and 2059;
              For i := 0 to 19 do
                DateTime[i] := MsgHead_p^.DateTime[i];
            end; { With PktMsg_p^ }
            BlockWrite(PktFile, PktMsg_p^, SizeOf(PkdMsg), NumWritten);
            If NumWritten <> SizeOf(PkdMsg) then begin
              Writeln(StdErr, StrErrWri);
              If LogToFile then
                Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
            end; { If NumWritten }
            i := 0;
            While (i < 36) and (MsgHead_p^.ToName[i] <> #0) do
              Inc(i); { Ta reda p† l„ngd p† namnf„ltet }
            BlockWrite(PktFile, MsgHead_p^.ToName, i + 1, NumWritten);
            If NumWritten <> (i + 1) then begin
              Writeln(StdErr, StrErrWri);
              If LogToFile then
                Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
            end; { If NumWritten }
            i := 0;
            While (i < 36) and (MsgHead_p^.FromName[i] <> #0) do
              Inc(i); { Ta reda p† l„ngd p† namnf„ltet }
            BlockWrite(PktFile, MsgHead_p^.FromName, i + 1, NumWritten);
            If NumWritten <> (i + 1) then begin
              Writeln(StdErr, StrErrWri);
              If LogToFile then
                Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
            end; { If NumWritten }
            i := 0;
            While (i < 72) and (MsgHead_p^.Subject[i] <> #0) do
              Inc(i); { Ta reda p† l„ngd p† „mnesf„ltet }
            BlockWrite(PktFile, MsgHead_p^.Subject, i + 1, NumWritten);
            If NumWritten <> (i + 1) then begin
              Writeln(StdErr, StrErrWri);
              If LogToFile then
                Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
            end; { If NumWritten }
            LeftToWrite := FileSize(MsgFile) - SizeOf(MsgHeader);
            While LeftToWrite > SizeOf(Buffer) do begin
              BlockRead(MsgFile, Buff_p^, SizeOf(Buffer){, NumRead});
              BlockWrite(PktFile, Buff_p^, SizeOf(Buffer), NumWritten);
              If NumWritten <> SizeOf(Buffer) then begin
                Writeln(StdErr, StrErrWri);
                If LogToFile then
                  Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
              end; { If NumWritten }
              Dec(LeftToWrite, SizeOf(Buffer));
            end; { While }
            BlockRead(MsgFile, Buff_p^, LeftToWrite{, NumRead});
            BlockWrite(PktFile, Buff_p^, LeftToWrite, NumWritten);
            If NumWritten <> LeftToWrite then begin
              Writeln(StdErr, StrErrWri);
              If LogToFile then
                Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
            end;
          end else begin
            Writeln(StdErr, StrErrRea);
            If LogToFile then
              Writeln(LogFile, '- ', LogTime, LogName, StrErrRea);
          end; { If NumRead }
          Close(MsgFile);
          Erase(MsgFile);
        end else begin
          Writeln(StdErr, StrErrMOp, MsgSpec + FileSearch.Name);
          If LogToFile then
            Writeln(LogFile, '- ', LogTime, LogName, StrErrMOp,
                    MsgSpec + FileSearch.Name);
        end; { If gick att ”ppna MSG-fil }

        FindNext(FileSearch);
      end; { While not DosError }
      Buff_p^[0] := #0;
      Buff_p^[1] := #0;
      BlockWrite(PktFile, Buff_p^, 2, NumWritten);
      If NumWritten <> 2 then begin
        Writeln(StdErr, StrErrWri);
        If LogToFile then
          Writeln(LogFile, '- ', LogTime, LogName, StrErrWri);
      end;
      Close(PktFile);
      Writeln(StrLogPkt, PktSpec);
      If LogToFile then
        Writeln(LogFile, '  ', LogTime, LogName, StrLogPkt, PktSpec);
    end; { If gick att skapa PktFile }
    Dispose(PktMsg_p);
    Dispose(MsgHead_p);
    Dispose(Buff_p);
    filemode := fmReadOnly or fmDenyNone;
  end else begin
    Writeln(StdErr, StrErrAll);
    If LogToFile then
      Writeln(LogFile, '- ', LogTime, LogName, StrErrAll);
  end;
End;

{************************************************************************}
{* Rutin:       Initialize                                              *}
{************************************************************************}
{* Inneh†ll:    Initialiserar globala variabler                         *}
{* Definition:  Procedure Initialize;                                   *}
{************************************************************************}

Procedure Initialize;
Var
  Temp:         Word;
Begin
  With Idag do begin
    GetDate(Year, Month, Day, Temp);
    GetTime(Hour, Min, Sec, Temp);
  end;

  MsgIdNum := ((DTToUnixDate(Idag) and $7fffffff) shl 4) + (byte(Temp) shr 3);
  Registration := StrNotReg;
  BragLineIntro := '---';
  TagLineIntro := '...';
  MsgIdString := '';
  LogToFile := False;
  EchoTossLogFile := '';
  Ctr := 0;                     { R„kna mallnummer }
  MsgWritten := 0;              { R„kna antalet skrivna }
  ReplyKludge := True;
  ForcePID := False;
  Fsc0048 := False;
End;

{************************************************************************}
{* Rutin:       main                                                    *}
{************************************************************************}
{* Inneh†ll:    Huvudrutin                                              *}
{* Definition:  -                                                       *}
{************************************************************************}

Var
  Ini:                                                          Text;
  IniFile, Rad, Name1, Name2, mFrom, mTo, Subj, FName, MsgBas,
  Keyword, Data, TagLine, Env, Origin, EchoTag, TagFile,
  HeaderFile, FooterFile, SemaphorFile, PktPath, PktPwd,
  CreateFile:                                                   String;
  PktName:                                                      String[12];
  Maint, SemaphorExist, TooSmall, UpdatedSend, Updated,
  BinkleyName, FixedWidth, IntervalDate, PostResult:            Boolean;
  Position, NumTagLines, i, Interval, DaysSince,
  MsgCount, Temp:                                               Word;
  SplitParts:                                                   Byte;
  RegCode, MinSize, FDate, SplitSize:                           LongInt;
  Test:                                                         Integer;
  Distribution:                                                 MsgType;
  OrigAddr, DestAddr, TempAddr, PktFrom, PktTo:                 AddrType;
  Charset:                                                      CharsetType;
  DataFile:                                                File of DataFileRec;
  Semaphor:                                                     File;
  WhatToDo:                                                     RunMode;
  CurrentRec:                                                   DataFileRec;
  FileDate:                                                     DateTime;
  MsgAttributes:                                                Attributes;
Begin
  { Initiera variabler }
  ExitSave := ExitProc;         { Critical error handler }
  ExitProc := @Leave;
  MsgCount := 0;                { R„kna offset i datafilen }
  NumTagLines := 0;
  Origin := StrStdOri;
  TagFile := '';

  Randomize;
  Initialize;

  Assign(Output, '');           { Till†t omdirigering }
  Rewrite(Output);

  Assign(StdErr, '');           { ™ppna StdErr-handtaget }
  Rewrite(StdErr);
  TextRec(StdErr).Handle := 2;

  FileMode := fmReadOnly or fmDenyNone;

  { Kolla registreringen }
  Env := GetEnv('ANNOUNCER');
  If Env <> '' then begin
    Val(Copy(Env, 1, 5), RegCode, Test);
    If (Test = 0) and (RegCode = RegiCode(Copy(Env, 6, Length(Env)-5))) then
    begin
      Registration := Copy(Env, 6, Length(Env) - 5);
      BragLine := BragLine + '+';       { Identifiera registrerad version }
    end;
  end; { If Env }

  { ** F”r begr„nsad betatest ** }
  {$IFDEF BETA}
  If Registration = StrNotReg then begin
    Writeln(StdErr, 'To use this beta version, you need a valid registration key.');
    Halt(255);
  end; { If Registration }
  {$ENDIF}

  { ** Tidsbegr„nsad gammaversion ** }
  {$IFDEF GAMMA}
  If Registration = StrNotReg then begin
    If ((Idag.Year <> 1997) or (Idag.Month > 3)) and (Idag.Year <> 1996) then begin
      Writeln(StdErr, 'This unregistered GAMMA version expired April 1st, 1997');
      Writeln(StdErr, 'Please contact the author to get an updated version.');
      Halt(255);
    end else begin
      Writeln(StdErr, 'This unregistered GAMMA version will expire April 1st, 1997');
    end;
  end;
  {$ENDIF}

  If ParamStr(1) = '/?' then
    HelpScreen(BragLine, Registration);

  If Registration = StrNotReg then
    BragLine := BragLine + '-';

  { Kolla kommandoradsv„xlar }
  WhatToDo := CommandLine(StdErr, IniFile, Maint, ForcePid, Name1, Name2);

  If WhatToDo = DisplayData then begin
    DisplayInfo(IniFile, Maint);
    Halt;
  end;

  Assign(Ini, IniFile);
  {$I-}
  Reset(Ini);
  If IOResult <> 0 then begin
    Assign(Ini, IniFile + '.INI');
    Reset(Ini);
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrOp1, IniFile, StrErrOp2);
      Writeln(StdErr, IniFile, '.INI');
      Halt(1);
    end; { If IOResult }
    IniFile := IniFile + '.INI';
  end; { If IOResult }

  Assign(DataFile, Copy(IniFile, 1, length(IniFile) - 4) + '.DAT');
  FileMode := fmReadWrite or fmDenyWrite;
  Reset(DataFile);
  If IOResult <> 0 then begin
    Rewrite(DataFile);
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrDat, Copy(IniFile, 1, length(IniFile) - 4) +
              '.DAT');
      Halt(1);
    end; { If IOResult }
  end; { If IOResult }
  {$I+}

  If WhatToDo = Simulate then begin
    Assign(LogFile, '');
    Rewrite(LogFile);
    Writeln(LogFile, '+ ', LogTime, LogName, StrLogBeg, BragLine);
    Writeln(LogFile, '  ', LogTime, LogName, StrLogIni, IniFile);
  end;

  FileMode := fmReadOnly or fmDenyNone;

  PktPwd := '';
  PktMode := False;
  BinkleyName := False;
  FillChar(TempAddr, SizeOf(TempAddr), #0);
  FillChar(PktFrom, SizeOf(PktFrom), #0);
  FillChar(PktTo, SizeOf(PktTo), #0);

  Repeat { Until EOF }
    Repeat { Until 'MSG' or 'PLACEHOLDER' or EOF }
      Readln(Ini, Rad);
      RemoveJunk(Rad);

      If (Rad[1]<>';') and (UpStr(Rad)<>'.END') then begin
        Position := Pos(' ', Rad);
        If Position <> 0 then begin
          Keyword := UpStr(Copy(Rad, 1, Position - 1));
          Data := Copy(Rad, Position + 1, Length(Rad) - Position);
          If (Data[1] = '"') and (Data[Byte(Data[0])] = '"') then
            Data := Copy(Data, 2, Length(Data) - 2);
          If Data = '%1' then Data := Name1;
          If Data = '%2' then Data := Name2;
          If Keyword = 'TAGLINEFILE' then begin
            TagFile := Data
          end else if Keyword = 'BRAGLINEINTRO' then
            BragLineIntro := Copy(Data + '   ', 1, 3)
          else if Keyword = 'TAGLINEINTRO' then
            TagLineIntro := Copy(Data + '   ', 1, 3)
          else if Keyword = 'ECHOTOSSLOG' then
            EchoTossLogFile := Data
          else if Keyword = 'REPLYKLUDGE' then
            Case UpCase(Data[1]) of
              'Y': ReplyKludge := True;
              'N': ReplyKludge := False;
            end
          else if Keyword = 'LOGFILE' then begin
            If LogToFile = True then begin
              Writeln(StdErr, StrErrIni, IniFile, ':');
              Writeln(StdErr, StrErrLog);
              Close(Ini);
              Halt(2);
            end else begin
              If WhatToDo <> Simulate then begin
                FileMode := fmReadWrite or fmDenyWrite;
                Assign(LogFile, Data);
                {$I-}
                Append(LogFile);
                If IOResult <> 0 then begin
                  Rewrite(LogFile);
                  If IOResult <> 0 then begin
                    Writeln(StdErr, StrErrLo2);
                    Close(Ini);
                    Halt(2);
                  end; { If IOResult }
                end; { If IOResult }
                {$I+}
                Writeln(LogFile);
                Writeln(LogFile, '+ ', LogTime, LogName, StrLogBeg, BragLine);
                Writeln(LogFile, '  ', LogTime, LogName, StrLogIni, IniFile);
                FileMode := fmReadOnly or fmDenyNone;
              end;
              LogToFile := True;
            end;
          end else if Keyword = 'MSGID' then
            MsgIdString := Data
          else if Keyword = 'PKTMODE' then begin
            PktMode := True;
            MsgBas := 'F' + Data;
            If MsgBas[Length(MsgBas)] <> '\' then
              MsgBas := MsgBas + '\';
          end else if Keyword = 'PKTPATH' then begin
            PktPath := Data;
            If PktPath[Length(PktPath)] <> '\' then
              PktPath := PktPath + '\';
          end else if Keyword = 'PKTFROM' then begin
            If (not ParseAddr(Data, TempAddr, PktFrom)) or (PktFrom.Zone =
                0) then begin
              Writeln(StdErr, StrErrIni, IniFile, ':');
              Writeln(StdErr, StrErrOrg, Data);
            end;
          end else if Keyword = 'PKTTO' then begin
            If (not ParseAddr(Data, TempAddr, PktTo)) or (PktTo.Zone =
                0) then begin
              Writeln(StdErr, StrErrIni, IniFile, ':');
              Writeln(StdErr, StrErrDst, Data);
            end;
          end else if Keyword = 'PKTPWD' then
            PktPwd := Data
          else if Keyword = 'BINKLEYNAME' then begin
            Case UpCase(Data[1]) of
              'Y': BinkleyName := True;
              'N': BinkleyName := False;
            end;
          end else if Keyword = 'FSC-0048' then begin
            Case UpCase(Data[1]) of
              'Y': Fsc0048 := True;
              'N': Fsc0048 := False;
            end;
          end; { If Keyword }
        end; { If Position }
      end; { If ';' }
    Until (UpStr(Rad) = 'MSG') or (UpStr(Rad) = 'PLACEHOLDER') or EOF(Ini);

    If not EOF(Ini) then begin
      If UpStr(Rad) <> 'PLACEHOLDER' then begin
        Inc(Ctr);
        mFrom := '';
        mTo := '';
        Subj := '';
        FName := '';
        If Not PktMode then MsgBas := '';
        HeaderFile := '';
        FooterFile := '';
        SemaphorFile := '';
        TagLine := '';
        Distribution := Local;
        EchoTag := '';
        Interval := 0;
        IntervalDate := False;
        DaysSince := 0;
        MinSize := -1;
        SplitParts := 1;
        SplitSize := 0;
        Charset := Pc8;
        UpdatedSend := False;
        CreateFile := '';
        MsgAttributes := [];
        FixedWidth := False;
        FillChar(TempAddr, SizeOf(TempAddr), #0);
        FillChar(OrigAddr, SizeOf(OrigAddr), #0);
        FillChar(DestAddr, SizeOf(DestAddr), #0);

        Repeat { Until '.END' }
          {$I-}
          Seek(DataFile, MsgCount);
          Read(DataFile, CurrentRec);
          If IOResult <> 0 then
            FillChar(CurrentRec, SizeOf(CurrentRec), #0);
          {$I+}
          Readln(Ini, Rad);
          If (Rad[1]<>';') and (UpStr(Rad)<>'.END') then begin
            Position := Pos(' ', Rad);
            If Position <> 0 then begin
              Keyword := UpStr(Copy(Rad, 1, Position-1));
              Data := Copy(Rad, Position+1, Length(Rad)-Position);
              If (Data[1] = '"') and (Data[Byte(Data[0])] = '"') then
                Data := Copy(Data, 2, Length(Data) - 2);
              If Data = '%1' then Data := Name1;
              If Data = '%2' then Data := Name2;
  {$IFDEF MY} Writeln(Keyword, ': ', Data); {$ENDIF}
              If Keyword = 'FROM' then
                mFrom := Data
              else if Keyword = 'TO' then
                mTo := Data
              else if Keyword = 'SUBJECT' then
                Subj := Data
              else if Keyword = 'FILE' then
                FName := Data
              else if (Keyword = 'PATH') and Not PktMode then
                MsgBas := Data
              else if Keyword = 'PRIVATE' then
                Case UpCase(Data[1]) of
                  'Y': MsgAttributes := MsgAttributes + [Private];
                  'N': MsgAttributes := MsgAttributes - [Private];
                end
              else if Keyword = 'DISTRIBUTION' then begin
                Data := UpStr(Data);
                If Data = 'NETMAIL' then
                  Distribution := NetMail
                else if Data = 'ECHOMAIL' then
                  Distribution := EchoMail
                else if Data = 'LOCAL' then begin
                  Distribution := Local;
                  If PktMode = True then begin
                    Writeln(StdErr, StrErrIni, IniFile, ':');
                    Writeln(StdErr, StrErrLoc);
                    Close(Ini);
                    Halt(2);
                  end;
                end;
              end else if Keyword = 'ORIG' then begin
                If (not ParseAddr(Data, TempAddr, OrigAddr)) or (OrigAddr.Zone =
                    0) then begin
                  Writeln(StdErr, StrErrIni, IniFile, ':');
                  Writeln(StdErr, StrErrOrg, Data);
                  Close(Ini);
                  Halt(2);
                end; { If Addr }
              end else if Keyword = 'DEST' then begin
                If (not ParseAddr(Data, TempAddr, DestAddr)) or (DestAddr.Zone =
                    0) then begin
                  Writeln(StdErr, StrErrIni, IniFile, ':');
                  Writeln(StdErr, StrErrDst, Data);
                  Close(Ini);
                  Halt(2);
                end; { If Addr }
              end else if Keyword = 'ORIGIN' then
                Origin := Data
              else if Keyword = 'ECHO' then
                EchoTag := UpStr(Data)
              else if Keyword = 'INTERVAL' then begin
                If Data[1] = '@' then begin
                  Val(Copy(Data, 2, 3), Interval, Temp);
                  IntervalDate := True;
                end else begin
                  Val(Data, Interval, Temp);
                  IntervalDate := False;
                end;
              end else if Keyword = 'HEADER' then
                HeaderFile := Data
              else if Keyword = 'FOOTER' then
                FooterFile := Data
              else if Keyword = 'SEMAPHORE' then
                SemaphorFile := Data
              else if Keyword = 'SPLIT' then
                If Data[1] = '@' then begin
                  Val(Copy(Data, 2, 10), SplitSize, Temp);
                  SplitParts := 1;
                end else begin
                  Val(Data, SplitParts, Temp);
                  SplitSize := 0;
                end
              else if Keyword = 'MINSIZE' then
                Val(Data, MinSize, Temp)
              else if Keyword = 'CHARSET' then begin
                Data := UpStr(Data);
                If Data = 'PC8' then
                  Charset := Pc8
                else if Data = 'SV7' then
                  Charset := Sv7
                else if Data = 'ISO' then
                  Charset := Iso
                else if Data = 'ASCII' then
                  Charset := Ascii
                else if Data = '-ISO' then
                  Charset := FromIso
                else if Data = '-SV7' then
                  Charset := FromSjuBit
                else begin
                  Writeln(StdErr, StrErrIn2, IniFile, ':');
                  Writeln(StdErr, Rad);
                  Close(Ini);
                  Halt(2);
                end
              end else if Keyword = 'UPDATEDSEND' then
                Case UpCase(Data[1]) of
                  'Y': UpdatedSend := True;
                  'N': UpdatedSend := False;
                end
              else if Keyword = 'CREATE' then
                CreateFile := Data
              else if Keyword = 'ATTRIBUTES' then begin
                For i := 1 To Length(Data) do begin
                  Case UpCase(Data[i]) of
                  'C': MsgAttributes := MsgAttributes + [CrashMail];
                  'K': MsgAttributes := MsgAttributes + [KillSent];
                  'A': MsgAttributes := MsgAttributes + [FAttach];
                  'R': MsgAttributes := MsgAttributes + [FileReq];
                  'P': MsgAttributes := MsgAttributes + [Private];
                  'H': MsgAttributes := MsgAttributes + [Hold];
                  ' ': else
                         begin
                          Writeln(StdErr, StrErrIn2, IniFile, ':');
                          Writeln(StdErr, Rad);
                          Close(Ini);
                          Halt(2);
                       end;
                  end; { Case }
                end; { For }
              end else if Keyword = 'FIXEDWIDTH' then
                Case UpCase(Data[1]) of
                  'Y': FixedWidth := True;
                  'N': FixedWidth := False;
                end
              else if Keyword = 'TAGLINE' then begin
                If Data = '@' then begin
                  If TagFile = '' then begin
                    Writeln(StdErr, StrErrIni, IniFile, ':');
                    Writeln(StdErr, StrErrTag);
                    Close(Ini);
                    Halt(2);
                  end; { If NumTagLines }
                  Repeat
                    TagLine := ReadRandomLine(TagFile);
                  Until ((TagLine[1] <> ';') and (TagLine[1] <> '%'))
                end else
                  TagLine := Data;
              end else begin
                Writeln(StdErr, StrErrIn2, IniFile, ':');
                Writeln(StdErr, Rad);
                Close(Ini);
                Halt(2);
              end; { If Keyword }
            end; { If Position }
          end; { If Rad }
        Until UpStr(Rad) = '.END';

        If (FName = '') or (mFrom = '') or (Subj = '') or (MsgBas = '') or
           (PktMode and (Distribution = EchoMail) and (EchoTag = '')) or
           (PktMode and (Distribution = Local)) then begin
          If logtofile then Writeln(LogFile, '! ', LogTime, LogName, StrLogMis,
                                    Ctr);
        end else begin

          FDate := 0; { Nolla fildatum }

          If IntervalDate then begin { Posta bara speciellt datum? }
            If Idag.Day <> Interval then { Fel datum? }
              DaysSince := 0 { posta inte }
            else begin
              If Idag.Month <> CurrentRec.LastWritten.Month then
                DaysSince := 65535; { posta }
            end;
          end else begin
            If CurrentRec.LastWritten.Day = 0 then
              DaysSince := 65535
            else
              DaysSince := check_date(FormattedDate(Idag, 'MM-DD-YY'),
                                      FormattedDate(CurrentRec.LastWritten, 'MM-DD-YY'));
          end;

          SemaphorExist := True;
          If SemaphorFile <> '' then
            SemaphorExist := FileExist(SemaphorFile);

          TooSmall := False;
          If MinSize <> -1 then begin
            Assign(Semaphor, FName);
            {$I-}
            Reset(Semaphor, 1);
            If IOResult = 0 then begin
              TooSmall := FileSize(Semaphor) < MinSize;
              GetFTime(Semaphor, FDate); { Ta reda p† fildatum s† vi slipper ”ppna }
              Close(Semaphor);           { filen tv† g†nger p† direkten            }
            end else
              TooSmall := True;
          end; { If MinSize }

          Updated := True;
          If (UpdatedSend = True) and (CurrentRec.LastWritten.Day <> 0) then begin
            If FDate = 0 then begin { Ingen undansparad filtid }
              Assign(Semaphor, FName);
              {$I-}
              Reset(Semaphor);
              If IOResult = 0 then begin
                GetFTime(Semaphor, FDate);
                Close(Semaphor);
              end else
                Updated := False;
              {$I+}
            end; { If FDate = 0 }
            If FDate <> 0 then begin
              UnpackTime(FDate, FileDate);
              Updated := DTToUnixDate(FileDate) >
                         DTToUnixDate(CurrentRec.LastWritten);
            end;
          end; { If UpdatedSend }

          If DaysSince >= Interval then begin
            If SemaphorExist = True then begin
              If not TooSmall then begin
                If Updated then begin
                  If WhatToDo = Simulate then begin
                    Write(LogFile, '  ', LogTime, LogName, StrDidSav, StrDidSim,
                          StrDidSv2);
                    If (Distribution = EchoMail) and (EchoTag <> '') then
                      Write(LogFile, EchoTag)
                    else
                      Write(LogFile, MsgBas);
                    Writeln(LogFile, StrDidSv3, Ctr, ')');
                    Inc(MsgWritten);
                  end else begin { not Simulate }
                    PostResult := DoMessage(mFrom, mTo, Subj, FName, MsgBas,
                                  TagLine, Origin, Distribution, OrigAddr,
                                  DestAddr, EchoTag, CurrentRec, HeaderFile,
                                  FooterFile, SplitParts, SplitSize, Charset,
                                  CreateFile, MsgAttributes, FixedWidth);
                    If PostResult = True then begin
                      CurrentRec.LastWritten := Idag;
                      {$I-}
                      Seek(DataFile, MsgCount);
                      Write(DataFile, CurrentRec);
                      If IOResult <> 0 then;
                      {$I+}
                    end; { If PostResult }
                  end;
                end else begin { not Updated }
                  If LogToFile then begin
                    Write(LogFile, '- ', LogTime, LogName, StrNotUpd, Ctr);
                    If EchoTag <> '' then
                      Writeln(LogFile, StrDidSv2, EchoTag)
                    else
                      Writeln(LogFile);
                  end; { If LogToFile }
                end; { If Updated }
              end else begin { TooSmall }
                If LogToFile then begin
                  Write(LogFile, '- ', LogTime, LogName, StrTooSml, Ctr);
                  If EchoTag <> '' then
                    Writeln(LogFile, StrDidSv2, EchoTag)
                  else
                    Writeln(LogFile);
                end; { If LogToFile }
              end; { If TooSmall }
            end else begin { not SemaphorExist }
              If LogToFile then begin
                Writeln(LogFile, '- ', LogTime, LogName, StrNotSem, Ctr);
                If EchoTag <> '' then
                  Writeln(LogFile, StrDidSv2, EchoTag)
                else
                  Writeln(LogFile);
              end; { If LogToFile }
            end; { If SemaphorExist }
          end else begin { not DaysSince }
            If LogToFile then begin
              Write(LogFile, '- ', LogTime, LogName, StrNotInt, Ctr);
              If EchoTag <> '' then
                Write(LogFile, StrDidSv2, EchoTag);
              Writeln(LogFile, StrNotIn2);
              Write(LogFile, '  ', LogTime, LogName, '  (');
              If IntervalDate then
                If Interval <> Idag.Day then
                  Writeln(LogFile, StrNotIn4, Interval, '.)')
                else
                  Writeln(LogFile, StrNotIn5, ')')
              else
                Writeln(LogFile, DaysSince, StrNotIn3, Interval, ')');
            end; { If LogToFile }
          end; { If DaysSince }
          Inc(MsgCount);
        end; { If "kr„vda delar ifyllda" }
      end else begin { PlaceHolder }
        Inc(Ctr);
        Inc(MsgCount);
      end;
    end; { If EOF }
  Until EOF(Ini);

  Close(Ini);
  Close(DataFile);

  { Bygg PKT-fil }

  If PktMode and (MsgWritten <> 0) then begin
    If BinkleyName then
      PktName := LongWord(LongInt(PktTo.Net) shl 16 + PktTo.Node) + '.OUT'
    else
      PktName := LongWord(msgidnum) + '.PKT';
    If WhatToDo = Simulate then
      Writeln(LogFile, '  ', LogTime, LogName, StrLogPkt, StrDidSim, ' ',
              PktName)
    else
      buildpacket(PktPath + PktName, Copy(MsgBas, 2, Length(MsgBas) - 1),
                  PktFrom, PktTo, PktPwd);
  end;
End.
