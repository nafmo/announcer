{************************************************************************}
{* Program:     Announcer                                               *}
{************************************************************************}
{* F”rfattare:  Peter Karlsson                                          *}
{* Datum:       (se nedan)                                              *}
{* Version:     1.2                                                     *}
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
{* Rutiner:     Leave                                                   *}
{*              DoMessage                                               *}
{*                DoHeader                                              *}
{*                DoFooter                                              *}
{*              Initialize                                              *}
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
{*  v1.2  - 1997-11-22 - (se changelog)                                 *}
{************************************************************************}
Program Announcer;

{$I MKB.Def}
{$D-,G+,X+}

Uses Dos, MKFile, MKString, MKMsgAbs, MKOpen, MKGlobT, MKDos, MKMisc, NLS,
     Crypt, AnHelp, AnStr, ChekDate, PktHead, StrUtil, CmdLine, Info,
     StdErrU, LogFileU, Globals, Pkt, MsgIdU, Title, Config
     {$IFDEF MSDOS}, Zerberus{$ENDIF}
     {$IFDEF OS2}, OS2DT{$ENDIF}
     ;

Const
  {*$*DEFINE BETA}
  {*$*DEFINE GAMMA}
  LogName  = 'ANNO';
  BragLine: string = 'Announcer ' + Version;

  {$IFDEF MSDOS}
  Virustest: ChkTwoLong = (0,0);
  {$ENDIF}

Type
  MsgIdTypeType =       (Standard, IDServer);

Var
  ExitSave:             Pointer;
  MsgId_p:              MsgidAbsPointer;
  MsgIdType:            MsgIdTypeType;

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
  {$IFDEF MSDOS}
  If ErrorAddr <> nil then begin
    RunTime := HexLong(Seg(ErrorAddr^) * $10000 + Ofs(ErrorAddr^));
    RunTime := Copy(RunTime, 1, 4) + ':' + Copy(RunTime, 5, 4);
    Writeln(StrLogRun, ExitCode, StrLogRn2, RunTime);
    If LogInitialized and Log^.isOpen then
      Log^.LogLine('!')^.LogStr(StrLogRun)^.LogInt(ExitCode)^.LogStr(StrLogRn2)^.
           LogStr(RunTime)^.LogLn;
  end;
  {$ENDIF}
  If LogInitialized then
    Dispose(Log, Done);
  {$IFDEF MSDOS}
  ErrorAddr := nil;
  {$ENDIF}
End;
{$F-}

{************************************************************************}
{* Rutin:       DoMessage                                               *}
{************************************************************************}
{* Inneh†ll:    Framst„ller ett meddelande enligt angivna parametrar    *}
{* Definition:  Function DoMessage(var Global: GlobalDataType;          *}
{*              var This: MessageConfigType;                            *}
{*              Pkt: PacketConfigType): Boolean;                        *}
{************************************************************************}

Function DoMessage(var Global: GlobalDataType;
                   var This: MessageConfigType;
                   Pkt: PacketConfigType): Boolean;
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
  AccumulatedSize, CurrMsgIdNum:                        LongInt;
  TempAddr:                                             AddrType;

 {************************************************************************}
 {* Rutin:       DoHeader                                                *}
 {************************************************************************}
 Procedure DoHeader(Subj: String);
 begin
   Case This.AreaType of
     Local: begin
       Msg^.SetMailType(mmtNormal);  { M”testyp }
       Msg^.StartNewMsg;
       Msg^.SetEcho(False);          { Ska ej ekas }
       Msg^.SetPriv(Private in This.MsgAttr);
     end;
     NetMail: begin
       Msg^.SetMailType(mmtNetmail);
       Msg^.StartNewMsg;
       Msg^.SetOrig(This.Orig);      { Avs„ndaradress }
       Msg^.SetDest(This.Dest);
       Msg^.SetEcho(True);           { Ska ekas }
       Msg^.SetPriv(True);
       { FMPT och TOPT kr„vs ibland f”r att f† adresserna r„tt,
         de skrivs automatiskt i MSG och Hudson, och ignoreras i JAM. }
       If Pos(This.MsgBas[1], 'FfHhJj') = 0 then begin
         If This.Orig.point <> 0 then
           Msg^.DoKludgeLn(#1'FMPT ' + Long2Str(This.Orig.point));
         If This.Dest.point <> 0 then
           Msg^.DoKludgeLn(#1'TOPT ' + Long2Str(This.Dest.point));
       end;
     end;
     EchoMail: begin
       Msg^.SetMailType(mmtEchomail);
       Msg^.StartNewMsg;
       Msg^.SetOrig(This.Orig);
       Msg^.SetEcho(True);
       Msg^.SetPriv(False);
       If Global.PktMode then
         Msg^.DoStringLn('AREA:' + This.EchoTag);
     end;
   end; { Case }

   Msg^.SetRefer(0);

   { Meddelandeheader }
   Msg^.SetFrom(This.mFrom);
   Msg^.SetTo(This.mTo);
   Msg^.SetSubj(Subj);
   Msg^.SetDate(mkstring.DateStr(GetDosDate));
   Msg^.SetTime(mkstring.TimeStr(GetDosDate));
   Msg^.SetLocal(True);

   { Attribut }
   If This.AreaType <> EchoMail then begin
     Msg^.SetCrash(CrashMail in This.MsgAttr);
     Msg^.SetKillSent(KillSent in This.MsgAttr);
     Msg^.SetFAttach(FAttach in This.MsgAttr);
     Msg^.SetFileReq(FileReq in This.MsgAttr);
     If (Pos(This.MsgBas[1], 'Hh') = 0) or Not This.FixedWidth then
       Msg^.SetHold(Hold in This.MsgAttr);
   end;

   { Skapa MSGID, REPLY, SPLIT-kludgar }
   If EffectiveMsgIDString <> '' then begin
     Msg^.DoKludgeLn(#1'MSGID: ' + EffectiveMsgIDString);
     If ReplyIDString <> '' then
       Msg^.DoKludgeLn(#1'REPLY: ' + ReplyIDString);
   end;
   If SplitKludge <> '' then
     Msg^.DoKludgeLn(SplitKludge);

   { Undvik dubbla FLAGS-rader i Hudson (Hudson har inget HOLD-attribut) }
   If This.FixedWidth then begin
     If (Pos(This.MsgBas[1], 'Hh') <> 0) and (Hold in This.MsgAttr) then
       Msg^.DoKludgeLn(#1'FLAGS NPD HLD')
     else
       Msg^.DoKludgeLn(#1'FLAGS NPD');
   end;

   { NOTE }
   If MailingList then
     Msg^.DoKludgeLn(#1'NOTE: Mailing list "' + ListName + '"');
   If Global.Registration = StrNotReg then
     Msg^.DoKludgeLn(#1'NOTE: Unregistered evaluation version');

   { CHRS-kludge }
   Case This.Charset of
     Pc8, FromIso, FromSjuBit:  Msg^.DoKludgeLn(#1'CHRS: IBMPC 2');
     Sv7, IsSjuBit:             Msg^.DoKludgeLn(#1'CHRS: SWEDISH 1');
     Iso, IsIso:                Msg^.DoKludgeLn(#1'CHRS: LATIN-1 2');
   end; { Case } { ASCII ger ingen kludge }

   { PID-kludge }
   If Global.ForcePID or
      (Not Global.NetMailTearline and (This.AreaType = Netmail)) then
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
   If Not Global.ForcePID and
      (Global.NetMailTearline or (This.AreaType <> Netmail)) then
     Msg^.DoStringLn(Global.BragLineIntro + ' ' + BragLine);

   If This.AreaType = EchoMail then begin
     { Alltid tearline i echomail, f”rutom i PID-l„ge eller Netmailtearline av }
     If (Global.BragLineIntro <> '---') and
        Not Global.ForcePID and
        (Global.NetMailTearline or (This.AreaType <> Netmail)) then
       Msg^.DoStringLn('---');
     { Origin i echomail om ej i PID-l„ge, dock alltid i PKT }
     If Global.PktMode or Not Global.ForcePID then begin
       If This.Origin <> '' then begin
         TmpStr := This.Origin + ' (' + AddrStr(This.Orig) + ')';
         If Length(TmpStr) > 68 then
           TmpStr := Copy(TmpStr, Length(TmpStr) - 67, 68);
       end else
         TmpStr := '(' + AddrStr(This.Orig) + ')';
       Msg^.DoStringLn(' * Origin: ' + TmpStr);
     end;

     If Global.PktMode then begin { PATH & SEEN-BY }
       If This.Orig.Point = 0 then
         Msg^.DoStringLn('SEEN-BY: ' + Long2Str(This.Orig.Net) + '/' +
                         Long2Str(This.Orig.Node));
       Msg^.DoStringLn('SEEN-BY: ' + Long2Str(Pkt.PktTo.Net) + '/' +
                       Long2Str(Pkt.PktTo.Node));
       Msg^.DoKludgeLn(#1'PATH: ' + Long2Str(This.Orig.Net) + '/' +
                       Long2Str(This.Orig.Node));
     end;
   end;

   If This.AreaType = NetMail then
     {$IFDEF OS2}
     Msg^.DoKludgeLn(#1'Via ' + AddrStr(This.Orig) +
                     FormattedDate(DosDateTime2OS2DateTime(Global.Idag),
                     ' @YYYYMMDD.HHIISS ') + BragLine);
     {$ELSE}
     Msg^.DoKludgeLn(#1'Via ' + AddrStr(This.Orig) +
                     FormattedDate(Global.Idag, ' @YYYYMMDD.HHIISS ') +
                     BragLine);
     {$ENDIF}
 end;
{************************************************************************}
begin

  If Not (This.Charset in [FromISO, FromSjuBit, Pc8]) then
  begin
    This.mFrom :=   Convert(This.mFrom, This.Charset);
    This.mTo :=     Convert(This.mTo, This.Charset);
    This.Subj :=    Convert(This.Subj, This.Charset);
    This.Origin :=  Convert(This.Origin, This.Charset);
    This.TagLine := Convert(This.TagLine, This.Charset);
  end;

  DidPost := False;

  IDString := '';
  If This.Parts = 0 then
    This.Parts := 1;

  MoreNames := True;
  DoneOne := False;

  MailingList := This.mTo[1] = '@';

  If MailingList then begin
    ListNames.Init;
    ListName := copy(This.mTo, 2, length(This.mTo) - 1);
    If not ListNames.OpenTextFile(ListName) then begin
      MailingList := False;
      ListNames.Done;
      Log^.LogLine('!')^.LogStr(StrLogFil + ListName)^.LogLn;
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
      ParseINI(TmpStr, TmpStr2, This.mTo);      { Dela i adress och namn    }
      ParseAddr(TmpStr2, TempAddr, This.Dest);
    end; { If MailingList }

    TF.Init;                                    { Initiera textfilsobjekt   }

    If This.HeaderFile <> '' then
      Head.Init;                                { Initiera headerfilsobjekt }

    If This.FooterFile <> '' then
      Foot.Init;                                { Initiera footerfilsbjekt  }

    If TF.OpenTextFile(This.FName) then begin           { ™ppna textfilen   }
      TextSize := FileSize(TF.TF^.BufferFile);          { Storlek av texten }

      Current := TF;            { B”rja med texten }
      CurrentIndicator := MainText;

      If This.HeaderFile <> '' then begin
        If Head.OpenTextFile(This.HeaderFile) then begin
          Inc(TextSize, FileSize(Head.TF^.BufferFile)); { plus storlek av   }
          Current := Head;      { Nej, med huvudet }    { headerfilen       }
          CurrentIndicator := Header;
        end else begin
          This.HeaderFile := '';     { Fanns inte }
          Head.Done;
        end;
      end;

      If This.FooterFile <> '' then begin
        If Foot.OpenTextFile(This.FooterFile) then begin
          Inc(TextSize, FileSize(Foot.TF^.BufferFile)); { plus storlek av   }
        end else begin                                  { footerfilen       }
          This.FooterFile := '';     { Fanns inte }
          Foot.Done;
        end;
      end;

      AccumulatedSize := 0;

      If This.Size <> 0 then                    { R„kna ut antalet delar     }
        This.Parts := (TextSize div This.Size) + 1;

      NextSplit := TextSize div This.Parts + 1; { Var ska n„sta del b”rja?   }

      If (Pos(This.MsgBas[1], 'Ss') <> 0) and (NextSplit > 32800) then
      begin
        This.Parts := (TextSize div 33000) + 1;{ utvecklingspaketet klarar 33k}
        NextSplit := TextSize div This.Parts + 1; { max i Squishdatabaser     }
      end;

      If NextSplit < 160 then begin             { Minsta storlek = ca. 2 rader }
        This.Parts := (TextSize div 160) + 1;
        NextSplit := TextSize div This.Parts + 1;
      end;

      If This.Parts > 1 then begin              { Initiera ev. SPLIT-kludge }
        SplitKludge := #1'SPLIT:                    @                  01/   +++++++++++';
        SplitKludge[50] := Char(48 + This.Parts div 10);
        SplitKludge[51] := Char(48 + This.Parts mod 10);

        {$IFDEF OS2}
        TmpStr := FormattedDate(DosDateTime2OS2DateTime(Global.Idag),
                                'DD NNN YY HH:II:SS');
        {$ELSE}
        TmpStr := FormattedDate(Global.Idag, 'DD NNN YY HH:II:SS');
        {$ENDIF}
        Move(TmpStr[1], SplitKludge[9], 18);
        TmpStr := Long2Str(This.Orig.Net) + '/' + Long2Str(This.Orig.Net);
        Move(TmpStr[1], SplitKludge[29], Length(TmpStr));
        Str(Global.MsgWritten, TmpStr);
        Move(TmpStr[1], SplitKludge[41], Length(TmpStr));
      end else
        SplitKludge := '';

      If This.AreaType = Local then
        IDString := Global.MsgIdString
      else
        IDString := AddrStr(This.Orig);

      If IDString <> '' then
        CurrMsgIdNum := MsgId_p^.GetSerial(This.Parts)
      else
        CurrMsgIdNum := 0;

      If OpenMsgArea(Msg, This.MsgBas) then begin

        If IDString <> '' then begin
          EffectiveMsgIDString := IDString + ' ' + LongWord(CurrMsgIdNum)
        end else begin
          EffectiveMsgIDString := '';
        end;

        ReplyString := This.CurrentRec.MsgIdString;
        ReplyNum := This.CurrentRec.MsgIdNum;
        If Global.ReplyKludge and not MailingList and (ReplyString <> '') then
          ReplyIDString := ReplyString + ' ' + LongWord(ReplyNum)
        else
          ReplyIDString := '';

        If not DoneOne then begin
          This.CurrentRec.MsgIdString := IDString;
          This.CurrentRec.MsgIdNum := CurrMsgIdNum;
        end;

        If SplitKludge = '' then
          DoHeader(This.Subj)
        else
          DoHeader(This.Subj + Copy(SplitKludge, 46, 6));

        { L„s in texten }

        While CurrentIndicator <> Finished do begin
          TmpStr := Current.GetString;

          While Current.StringFound do begin
            If ((Current.GetTextPos + AccumulatedSize) > NextSplit) and
               Current.TF^.IsEol then begin
              { Dags att dela av }
              DoFooter;

              { Skriv det, logga om det inte lyckades }
              if Msg^.WriteMsg <> 0 then begin
                Writeln(StrErrSav, This.Subj, '"');
                Log^.LogLine('!')^.LogStr(StrLogSav)^.LogInt(Global.Ctr)^.LogLn;
              end else begin
                MsgNum := Msg^.GetMsgNum;
                Writeln(StrDidSav, MsgNum, StrDidSv2, This.MsgBas, StrDidSv3,
                        Global.Ctr, ')');
                Log^.LogLine(' ')^.LogStr(StrDidSAv)^.LogInt(MsgNum)^.
                     LogStr(StrDidSv2);
                If (This.AreaType = EchoMail) and (This.EchoTag <> '') then
                  Log^.LogStr(This.EchoTag)
                else
                  Log^.LogStr(This.MsgBas);
                Log^.LogStr(StrDidSv3)^.LogInt(Global.Ctr)^.LogStr(')')^.LogLn;
              end;

              { ™ka textdelsr„knare }
              Inc(NextSplit, TextSize div This.Parts + 1);
              { ™ka delr„knaren }
              SplitKludge[48] := Char(Byte(SplitKludge[48]) + 1);
              If SplitKludge[48] = ':' then begin
                SplitKludge[47] := Char(Byte(SplitKludge[47]) + 1);
                SplitKludge[48] := '0';
              end;
              If TmpStr = '' then
                TmpStr := Current.GetString;

              { P†b”rja n„sta meddelande }
              If IDString <> '' then begin
                Inc(CurrMsgIdNum); { Har allokerat This.Parts stycken }
                EffectiveMsgIDString := IDString + ' ' +
                                        LongWord(CurrMsgIdNum);
              end;

              DoHeader(This.Subj + Copy(SplitKludge, 46, 6));
            end; { If splithere }

            TmpStr2 := '';
            For i := 1 to Length(TmpStr) do
              If (TmpStr[i] >= #32) then
                TmpStr2 := TmpStr2 + TmpStr[i];
            If Not (This.Charset in [FromISO, FromSjuBit, Pc8, IsIso, IsSjuBit]) then
              TmpStr2 := Convert(TmpStr2, This.Charset);
            If Current.TF^.IsEol then
              Msg^.DoStringLn(TmpStr2)
            else
              Msg^.DoString(TmpStr2);
            TmpStr := Current.GetString;
          end; { While }
          Inc(AccumulatedSize, FileSize(Current.TF^.BufferFile));

          Current.CloseTextFile;

          { Klar med denna textfil, ta nu ev. n„sta }
          If CurrentIndicator = Header then begin { om nu header, ta kropp }
            CurrentIndicator := MainText;
            Current := TF;
          end else If (CurrentIndicator = MainText) and
                      (This.FooterFile <> '') then begin
            CurrentIndicator := Footer; { om nu kropp, och finns fot, ta fot }
            Current := Foot;
          end else begin
            CurrentIndicator := Finished; { annars avsluta }
          end; { If }

        end; { While }

        { Avsluta }
        If This.TagLine <> '' then begin
          If TmpStr2 <> '' then
            Msg^.DoStringLn(''); { Tomrad f”re tagline }
          Msg^.DoStringLn(Global.TagLineIntro + ' ' + This.TagLine);
        end;

        DoFooter;

        { Skriv det, logga om det inte lyckades }
        If Msg^.WriteMsg <> 0 then begin
          Writeln(StrErrSav, This.Subj, '"');
          Log^.LogLine('!')^.LogStr(StrLogSav)^.LogInt(Global.Ctr)^.LogLn;
        end else begin
          Inc(Global.MsgWritten);
          DidPost := True;
          MsgNum := Msg^.GetMsgNum;
          Writeln(StrDidSav, MsgNum, StrDidSv2, This.MsgBas, StrDidSv3,
                  Global.Ctr, ')');
          Log^.LogLine(' ')^.LogStr(StrDidSav)^.LogInt(MsgNum)^.
               LogStr(StrDidSv2);
          If (This.AreaType = EchoMail) and (This.EchoTag <> '') then
            Log^.LogStr(This.EchoTag)
          else
            Log^.LogStr(This.MsgBas);
          Log^.LogStr(StrDidSv3)^.LogInt(Global.Ctr)^.LogStr(')')^.LogLn;

          { Skriv post i Echotoss.log- eller Echomail.Jam/Netmail.Jam-fil }
          If (Pos(This.MsgBas[1], 'Jj') <> 0) and (Global.JamTossLogPath <> '')
             and (not Global.PktMode) and (This.AreaType <> Local)
             then
          begin
            FileMode := fmReadWrite or fmDenyAll;
            If This.AreaType = EchoMail then { Loggfilsnamn }
              TmpStr := Global.JamTossLogPath + 'EchoMail.jam'
            else
              TmpStr := Global.JamTossLogPath + 'NetMail.Jam';
            TmpStr2 := Copy(This.MsgBas, 2, Length(This.MsgBas) - 1) + ' ' +
                       Long2Str(MsgNum); { V„rde som ska skrivas }
            Assign(EchoToss, TmpStr);
            {$I-}
            Reset(EchoToss);
            Append(EchoToss);
            If IOResult <> 0 then begin
              Rewrite(EchoToss);
              If IOResult <> 0 then begin
                Writeln(StdErr, StrErrTos, Global.EchoTossLogFile);
                Log^.LogLine('!')^.LogStr(StrLogTos + Global.EchoTossLogFile)^.LogLn;
              end else begin
                Writeln(EchoToss, TmpStr2);
                Close(EchoToss);
              end; { If IOResult }
            end else begin
              Writeln(EchoToss, TmpStr2);
              Close(EchoToss);
            end; { If IOResult }

            FileMode := fmReadOnly or fmDenyNone;
            {$I+}

          end else If (This.EchoTag <> '') and (Global.EchoTossLogFile <> '') and
             (not Global.PktMode) and (This.AreaType = EchoMail) then begin
            WriteEchoToss := True;
            FileMode := fmReadWrite or fmDenyAll;
            Assign(EchoToss, Global.EchoTossLogFile);
            {$I-}
            Reset(EchoToss);
            If IOResult = 0 then begin
              While (not eof(EchoToss)) do begin
                Readln(EchoToss, TmpStr);
                If UpStr(TmpStr) = This.EchoTag then
                  WriteEchoToss := False;
              end; { While }
              Close(EchoToss);
            end else begin
              Rewrite(EchoToss);
              If IOResult <> 0 then begin
                Writeln(StdErr, StrErrTos, Global.EchoTossLogFile);
                Log^.LogLine('!')^.LogStr(StrLogTos + Global.EchoTossLogFile)^.LogLn;
              end else begin
                Writeln(EchoToss, This.EchoTag);
                Close(EchoToss);
              end; { If IOResult }
              WriteEchoToss := False;
            end; { If IOResult }

            If WriteEchoToss = True then begin
              Append(EchoToss);
              If IOResult <> 0 then begin
                Writeln(StdErr, StrErrTo2, Global.EchoTossLogFile);
                Log^.LogLine('!')^.LogStr(StrLogTo2 + Global.EchoTossLogFile)^.
                     LogLn;
              end else begin
                Writeln(EchoToss, This.EchoTag);
                Close(EchoToss);
              end; { If IOResult }
            end; { If WriteEchoToss }

            FileMode := fmReadOnly or fmDenyNone;
            {$I+}
          end; { If ska skriva till echotosslog }

          If This.CreateFile <> '' then begin { Skapa semaforfil }
            Assign(EchoToss, This.CreateFile);
            {$I-}
            Rewrite(EchoToss);
            If IOResult <> 0 then begin
              Writeln(StdErr, StrLogCrf, This.CreateFile);
              Log^.LogLine('!')^.LogStr(StrLogCrf + This.CreateFile)^.LogLn;
            end else begin
              Close(EchoToss);
              Writeln(StdErr, StrLogCrs, This.CreateFile);
              Log^.LogLine(' ')^.LogStr(StrLogCrs + This.CreateFile)^.LogLn;
            end; { If IOResult }
          end; { If CreateFile }
        end; { If Msg^.WriteMsg }
        CloseMsgArea(Msg);
      end else begin
        Writeln(StrErrBas, This.MsgBas);
        Log^.LogLine('!')^.LogStr(StrLogBas + This.MsgBas)^.LogLn;
      end;
    end else begin
      Writeln(StrErrFil, This.FName);
      Log^.LogLine('!')^.LogStr(StrLogFil + This.FName)^.LogLn;
    end; { If OpenTextFile }

    TF.Done;
    If This.HeaderFile <> '' then
      Head.Done;
    If This.FooterFile <> '' then
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
    ListNames.CloseTextFile;
    ListNames.Done;
  end;

  DoMessage := DidPost;
end;

{************************************************************************}
{* Rutin:       Initialize                                              *}
{************************************************************************}
{* Inneh†ll:    Initialiserar globala variabler                         *}
{* Definition:  Procedure Initialize;                                   *}
{************************************************************************}

Procedure Initialize(var Global: GlobalDataType);
Var
  Temp:         Word;
  Env:          String;
Begin
  With Global.Idag do begin
    GetDate(Year, Month, Day, Temp);
    GetTime(Hour, Min, Sec, Temp);
  end;

  With Global do begin
    Registration := StrNotReg;
    BragLineIntro := '---';
    TagLineIntro := '...';
    MsgIdString := '';
    EchoTossLogFile := '';
    JamTossLogPath := '';
    Ctr := 0;                   { R„kna mallnummer }
    MsgWritten := 0;            { R„kna antalet skrivna }
    ReplyKludge := True;
    ForcePID := False;
    Fsc0048 := False;
    NetMailTearline := True;
  end; { With Global }

  Env := GetEnv('IDSERVER');
  If Env = '' then begin
    MsgId_p := New(MsgIdStdPointer, Init);
    MsgIdType := Standard;
  end else begin
    MsgId_p := New(MsgIdServPointer, Init(Env));
    MsgIdType := IDServer;
  end;
End;

{************************************************************************}
{* Rutin:       main                                                    *}
{************************************************************************}
{* Inneh†ll:    Huvudrutin                                              *}
{* Definition:  -                                                       *}
{************************************************************************}

Var
  GlobalInfo:                                           GlobalDataType;
  MessageInfo:                                          MessageConfigType;
  PacketInfo:                                           PacketConfigType;
  Ini:                                                  Text;
  IniFile, Rad, Keyword, Data, Env, TagFile,
  SemaphorFile, PktPath:                                String;
  Maint, SemaphorExist, TooSmall, UpdatedSend, Updated,
  BinkleyName, IntervalDate, PostResult, PostThis,
  LeaveDates, DoSimulate:                               Boolean;
  i, Interval, DaysSince, MsgCount, Temp:               Word;
  RegCode, MinSize, FDate:                              LongInt;
  Test:                                                 Integer;
  TempAddr:                                             AddrType;
  DataFile:                                             File of DataFileRec;
  Semaphor:                                             File;
  WhatToDo:                                             RunMode;
  FileDate:                                             DateTime;
  AskPostAnswer:                                        Char;
  TosserConfig_p:                                       TosserPointer;

Begin
  {$IFDEF MSDOS}
  If not SelfTest(Virustest) then begin
    Writeln(StrErrVir);
    Halt(255);
  end;
  {$ENDIF}

  { Initiera variabler }
  LogInitialized := False;
  ExitSave := ExitProc;         { Critical error handler }
  ExitProc := @Leave;
  SetTitle('Announcer');
  MsgCount := 0;                { R„kna offset i datafilen }
  TagFile := '';
  TosserConfig_p := Nil;

  Randomize;
  Initialize(GlobalInfo);

  StdoutOn(True);               { Till†t omdirigering }

  FileMode := fmReadOnly or fmDenyNone;

  { Kolla registreringen }
  Env := CheckRegistration(InSameDir(ParamStr(0), 'ANNOUNCE.KEY'));
  If Env <> '' then begin
    GlobalInfo.Registration := Env;
    BragLine := BragLine + '+';       { Identifiera registrerad version }
  end; { If Env }

  { ** F”r begr„nsad betatest ** }
  {$IFDEF BETA}
  If GlobalInfo.Registration = StrNotReg then begin
    Writeln(StdErr, 'To use this beta version, you need a valid registration key.');
    Halt(255);
  end; { If Registration }
  {$ENDIF}

  { ** Tidsbegr„nsad gammaversion ** }
  {$IFDEF GAMMA}
  If GlobalInfo.Registration = StrNotReg then begin
    If (GlobalInfo.Idag.Year <> 1997) then begin
      Writeln(StdErr, 'This unregistered GAMMA version expired January 1st, 1998');
      Writeln(StdErr, 'Please contact the author to get an updated version.');
      Halt(255);
    end else begin
      Writeln(StdErr, 'This unregistered GAMMA version will expire January 1st, 1998');
    end;
  end;
  {$ENDIF}

{ Writeln(StdErr, 'This SPECIAL version may not be used by any other person than Johan');
  Writeln(StdErr, 'Segern„s.');}

  If ParamStr(1) = '/?' then
    HelpScreen(BragLine, GlobalInfo.Registration);

  {$IFNDEF BETA}
  If GlobalInfo.Registration = StrNotReg then begin
    BragLine := BragLine + '-';
    Writeln(StrNotReg);
  end;
  {$ENDIF}

  New(Log, Init(BragLine, LogName, StrLogBeg, StrLogEnd));
  LogInitialized := True;

  { Kolla kommandoradsv„xlar }
  WhatToDo := CommandLine(StdErr, IniFile, Maint, GlobalInfo.ForcePid,
                          LeaveDates, DoSimulate);

  If WhatToDo = DisplayData then begin
    DisplayInfo(IniFile, Maint, GlobalInfo.Idag);
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

  If DoSimulate then begin
    Log^.OpenLog('');
    Log^.LogLine(' ')^.LogStr(StrLogIni + IniFile)^.LogLn;
  end; { If DoSimulate }

  FileMode := fmReadOnly or fmDenyNone;

  PacketInfo.PktPwd := '';
  GlobalInfo.PktMode := False;
  BinkleyName := False;
  FillChar(TempAddr, SizeOf(TempAddr), #0);
  FillChar(PacketInfo.PktFrom, SizeOf(PacketInfo.PktFrom), #0);
  FillChar(PacketInfo.PktTo, SizeOf(PacketInfo.PktTo), #0);

  Repeat { Until EOF }
    Repeat { Until 'MSG' or 'PLACEHOLDER' or EOF }
      Readln(Ini, Rad);
{     RemoveJunk(Rad);}

      If (Rad[1]<>';') and (UpStr(Rad)<>'.END') then begin
        If ParseINI(Rad, Keyword, Data) then begin
          If Data[1] = '%' then begin
            Temp := Str2Long(Copy(Data, 2, 2));
            If (Temp >= 1) and (Temp <= 10) then
              Data := Name[Temp];
          end;
          If Keyword = 'TAGLINEFILE' then begin
            TagFile := Data
          end else if Keyword = 'BRAGLINEINTRO' then
            GlobalInfo.BragLineIntro := Copy(Data + '   ', 1, 3)
          else if Keyword = 'TAGLINEINTRO' then
            GlobalInfo.TagLineIntro := Copy(Data + '   ', 1, 3)
          else if Keyword = 'ECHOTOSSLOG' then
            GlobalInfo.EchoTossLogFile := Data
          else if Keyword = 'JAMTOSSLOG' then begin
            GlobalInfo.JamTossLogPath := Data;
            If GlobalInfo.JamTossLogPath[Length(GlobalInfo.JamTossLogPath)] <> '\'
               then
              GlobalInfo.JamTossLogPath := GlobalInfo.JamTossLogPath + '\';
          end else if Keyword = 'REPLYKLUDGE' then
            GlobalInfo.ReplyKludge := YesNo(Data)
          else if Keyword = 'LOGFILE' then begin
            If Not DoSimulate then begin
              If Log^.isOpen = True then begin
                Writeln(StdErr, StrErrIni, IniFile, ':');
                Writeln(StdErr, StrErrLog);
                Close(Ini);
                Halt(2);
              end else begin
                FileMode := fmReadWrite or fmDenyWrite;
                If Not Log^.OpenLog(Data) then begin
                  Writeln(StdErr, StrErrLo2);
                  Halt(2);
                end; { If Log }
                Log^.LogLine(' ')^.LogStr(StrLogIni + IniFile)^.LogLn;
                FileMode := fmReadOnly or fmDenyNone;
              end;
            end;
          end else if Keyword = 'MSGID' then
            GlobalInfo.MsgIdString := Data
          else if Keyword = 'PKTMODE' then begin
            GlobalInfo.PktMode := True;
            MessageInfo.MsgBas := 'F' + Data;
            PacketInfo.MsgSpec := Data;
            If PacketInfo.MsgSpec[Length(PacketInfo.MsgSpec)] <> '\' then
              PacketInfo.MsgSpec := PacketInfo.MsgSpec + '\';
          end else if Keyword = 'PKTPATH' then begin
            PktPath := Data;
            If PktPath[Length(PktPath)] <> '\' then
              PktPath := PktPath + '\';
          end else if Keyword = 'PKTFROM' then begin
            If (not ParseAddr(Data, TempAddr, PacketInfo.PktFrom)) or
               (PacketInfo.PktFrom.Zone = 0) then begin
              Writeln(StdErr, StrErrIni, IniFile, ':');
              Writeln(StdErr, StrErrOrg, Data);
            end;
          end else if Keyword = 'PKTTO' then begin
            If (not ParseAddr(Data, TempAddr, PacketInfo.PktTo)) or
               (PacketInfo.PktTo.Zone = 0) then begin
              Writeln(StdErr, StrErrIni, IniFile, ':');
              Writeln(StdErr, StrErrDst, Data);
            end;
          end else if Keyword = 'PKTPWD' then
            PacketInfo.PktPwd := Data
          else if Keyword = 'BINKLEYNAME' then
            BinkleyName := YesNo(Data)
          else if Keyword = 'FSC-0048' then
            GlobalInfo.Fsc0048 := YesNo(Data)
          else if Keyword = 'IDSERVER' then begin
            If UpStr(Data) = 'NO' then begin
              If MsgIdType = IDServer then begin
                Dispose(MsgId_p);
                MsgId_p := New(MsgIdStdPointer, Init);
                MsgIdType := Standard;
              end;
            end else begin
              Dispose(MsgId_p);
              MsgId_p := New(MsgIdServPointer, Init(Data));
              MsgIdType := IDServer;
            end;
          end else if (Keyword = 'SQUISHCFG') or (Keyword = 'FMAILCFG') or
                      (Keyword = 'GECHOCFG') or (Keyword = 'TERMAILCFG')
                      then begin
            If TosserConfig_p = Nil then begin
              Case Keyword[1] of
                'S': TosserConfig_p := New(TosserSquishMailPointer, Init);
                'T': TosserConfig_p := New(TosserTerMailPointer, Init);
                {$IFDEF OS2}
                else Writeln('Not implemented yet:- ', Keyword);
                {$ELSE}
                'F': TosserConfig_p := New(TosserFMailPointer, Init);
                'G': TosserConfig_p := New(TosserGEchoPointer, Init);
                {$ENDIF}
              end;
              TosserConfig_p^.Import(Data);
            end else begin
              Writeln(StrErrTor);
              Log^.LogLine('!')^.LogStr(StrErrTor)^.LogLn;
            end;
          end else If Keyword = 'NETMAILTEARLINE' then begin
            GlobalInfo.NetMailTearLine := YesNo(Data);
          end; { If Keyword }
        end; { If ParseINI }
      end; { If ';' }
    Until (UpStr(Rad) = 'MSG') or (UpStr(Rad) = 'PLACEHOLDER') or EOF(Ini);

    If not EOF(Ini) then begin
      If UpStr(Rad) <> 'PLACEHOLDER' then begin
        Inc(GlobalInfo.Ctr);
        With MessageInfo do begin
          mFrom := '';
          mTo := '';
          Subj := '';
          FName := '';
          If Not GlobalInfo.PktMode then MsgBas := '';
          HeaderFile := '';
          FooterFile := '';
          CreateFile := '';
          TagLine := '';
          AreaType := Local;
          EchoTag := '';
          Charset := Pc8;
          MsgAttr := [];
          FixedWidth := False;
          FillChar(Orig, SizeOf(Orig), #0);
          FillChar(Dest, SizeOf(Dest), #0);
          Parts := 1;
          Size := 0;
          Origin := StrStdOri;
        end; { With }
        FillChar(TempAddr, SizeOf(TempAddr), #0);
        SemaphorFile := '';
        Interval := 0;
        IntervalDate := False;
        DaysSince := 0;
        MinSize := -1;
        UpdatedSend := False;

        Repeat { Until '.END' }
          {$I-}
          Seek(DataFile, MsgCount);
          Read(DataFile, MessageInfo.CurrentRec);
          If IOResult <> 0 then
            FillChar(MessageInfo.CurrentRec, SizeOf(MessageInfo.CurrentRec), #0);
          {$I+}
          Readln(Ini, Rad);
          If (Rad[1] <> ';') and (UpStr(Rad) <> '.END') then begin
            If ParseINI(Rad, Keyword, Data) then begin
              If Data[1] = '%' then begin
                Temp := Str2Long(Copy(Data, 2, 2));
                If (Temp >= 1) and (Temp <= 10) then
                  Data := Name[Temp];
              end;
              Temp := Pos('%d%', Data);
              If Temp > 0 then
                {$IFDEF OS2}
                Data := Copy(Data, 1, Temp - 1) +
                        DateStr(DosDateTime2OS2DateTime(GlobalInfo.Idag)) +
                        Copy(Data, Temp + 3, Length(Data) - Temp - 2);
                {$ELSE}
                Data := Copy(Data, 1, Temp - 1) + DateStr(GlobalInfo.Idag) +
                        Copy(Data, Temp + 3, Length(Data) - Temp - 2);
                {$ENDIF}
              Temp := Pos('%t%', Data);
              If Temp > 0 then
                {$IFDEF OS2}
                Data := Copy(Data, 1, Temp - 1) +
                        TimeStr(DosDateTime2OS2DateTime(GlobalInfo.Idag)) +
                        Copy(Data, Temp + 3, Length(Data) - Temp - 2);
                {$ELSE}
                Data := Copy(Data, 1, Temp - 1) + TimeStr(GlobalInfo.Idag) +
                        Copy(Data, Temp + 3, Length(Data) - Temp - 2);
                {$ENDIF}
              If Keyword = 'FROM' then
                MessageInfo.mFrom := Data
              else if Keyword = 'TO' then
                MessageInfo.mTo := Data
              else if Keyword = 'SUBJECT' then
                MessageInfo.Subj := Data
              else if Keyword = 'FILE' then
                MessageInfo.FName := Data
              else if (Keyword = 'PATH') and Not GlobalInfo.PktMode then
                MessageInfo.MsgBas := Data
              else if Keyword = 'PRIVATE' then
                Case YesNo(Data) of
                  True:  MessageInfo.MsgAttr := MessageInfo.MsgAttr + [Private];
                  False: MessageInfo.MsgAttr := MessageInfo.MsgAttr - [Private];
                end
              else if Keyword = 'DISTRIBUTION' then begin
                Data := UpStr(Data);
                If Data = 'NETMAIL' then
                  MessageInfo.AreaType := NetMail
                else if Data = 'ECHOMAIL' then
                  MessageInfo.AreaType := EchoMail
                else if Data = 'LOCAL' then begin
                  If GlobalInfo.PktMode = True then begin
                    Writeln(StdErr, StrErrIni, IniFile, ':');
                    Writeln(StdErr, StrErrLoc);
                    Close(Ini);
                    Halt(2);
                  end;
                  MessageInfo.AreaType := Local;
                end;
              end else if Keyword = 'ORIG' then begin
                If (not ParseAddr(Data, TempAddr, MessageInfo.Orig)) or
                   (MessageInfo.Orig.Zone = 0) then begin
                  Writeln(StdErr, StrErrIni, IniFile, ':');
                  Writeln(StdErr, StrErrOrg, Data);
                  Close(Ini);
                  Halt(2);
                end; { If Addr }
              end else if Keyword = 'DEST' then begin
                If (not ParseAddr(Data, TempAddr, MessageInfo.Dest)) or
                   (MessageInfo.Dest.Zone = 0) then begin
                  Writeln(StdErr, StrErrIni, IniFile, ':');
                  Writeln(StdErr, StrErrDst, Data);
                  Close(Ini);
                  Halt(2);
                end; { If Addr }
              end else if Keyword = 'ORIGIN' then
                MessageInfo.Origin := Data
              else if Keyword = 'ECHO' then
                MessageInfo.EchoTag := UpStr(Data)
              else if Keyword = 'INTERVAL' then begin
                If Data[1] = '@' then begin
                  Val(Copy(Data, 2, 3), Interval, Temp);
                  IntervalDate := True;
                end else begin
                  Val(Data, Interval, Temp);
                  IntervalDate := False;
                end;
              end else if Keyword = 'HEADER' then
                MessageInfo.HeaderFile := Data
              else if Keyword = 'FOOTER' then
                MessageInfo.FooterFile := Data
              else if Keyword = 'SEMAPHORE' then
                SemaphorFile := Data
              else if Keyword = 'SPLIT' then
                If Data[1] = '@' then begin
                  Val(Copy(Data, 2, 10), MessageInfo.Size, Temp);
                  MessageInfo.Parts := 1;
                end else begin
                  Val(Data, MessageInfo.Parts, Temp);
                  MessageInfo.Size := 0;
                end
              else if Keyword = 'MINSIZE' then
                Val(Data, MinSize, Temp)
              else if Keyword = 'CHARSET' then begin
                Data := UpStr(Data);
                If Data = 'PC8' then
                  MessageInfo.Charset := Pc8
                else if Data = 'SV7' then
                  MessageInfo.Charset := Sv7
                else if Data = 'ISO' then
                  MessageInfo.Charset := Iso
                else if Data = 'ASCII' then
                  MessageInfo.Charset := Ascii
                else if Data = '-ISO' then
                  MessageInfo.Charset := FromIso
                else if Data = '-SV7' then
                  MessageInfo.Charset := FromSjuBit
                else if Data = '-ASCII' then
                  MessageInfo.Charset := FromASCII
                else if Data = '+SV7' then
                  MessageInfo.Charset := IsSjuBit
                else if Data = '+ISO' then
                  MessageInfo.Charset := IsIso
                else begin
                  Writeln(StdErr, StrErrIn2, IniFile, ':');
                  Writeln(StdErr, Rad);
                  Close(Ini);
                  Halt(2);
                end
              end else if Keyword = 'UPDATEDSEND' then
                UpdatedSend := YesNo(Data)
              else if Keyword = 'CREATE' then
                MessageInfo.CreateFile := Data
              else if Keyword = 'ATTRIBUTES' then begin
                For i := 1 To Length(Data) do begin
                  Case UpCase(Data[i]) of
                    'A': MessageInfo.MsgAttr := MessageInfo.MsgAttr + [FAttach];
                    'C': MessageInfo.MsgAttr := MessageInfo.MsgAttr + [CrashMail];
                    'H': MessageInfo.MsgAttr := MessageInfo.MsgAttr + [Hold];
                    'K': MessageInfo.MsgAttr := MessageInfo.MsgAttr + [KillSent];
                    'P': MessageInfo.MsgAttr := MessageInfo.MsgAttr + [Private];
                    'R': MessageInfo.MsgAttr := MessageInfo.MsgAttr + [FileReq];
                    ' ': ;
                    else begin
                       Writeln(StdErr, StrErrIn2, IniFile, ':');
                       Writeln(StdErr, Rad);
                       Close(Ini);
                       Halt(2);
                    end; { else }
                  end; { Case }
                end; { For }
              end else if Keyword = 'FIXEDWIDTH' then
                MessageInfo.FixedWidth := YesNo(Data)
              else if Keyword = 'TAGLINE' then begin
                If Data = '@' then begin
                  If TagFile = '' then begin
                    Writeln(StdErr, StrErrIni, IniFile, ':');
                    Writeln(StdErr, StrErrTag);
                    Close(Ini);
                    Halt(2);
                  end; { If TagFile }
                  Repeat
                    MessageInfo.TagLine := ReadRandomLine(TagFile);
                  Until Pos(MessageInfo.TagLine[1], '%;') = 0;
                end else
                  MessageInfo.TagLine := Data;
              end else begin
                Writeln(StdErr, StrErrIn2, IniFile, ':');
                Writeln(StdErr, Rad);
                Close(Ini);
                Halt(2);
              end; { If Keyword }
            end; { If ParseINI }
          end; { If Rad }
        Until UpStr(Rad) = '.END';

        If Not GlobalInfo.PktMode and (MessageInfo.MsgBas = '') and
           (TosserConfig_p <> Nil) and (MessageInfo.EchoTag <> '') then
          If not TosserConfig_p^.GetAreaInfo(MessageInfo.EchoTag,
                                             MessageInfo.MsgBas,
                                             MessageInfo.Orig,
                                             MessageInfo.AreaType) then
            Log^.LogLine('!')^.LogStr(StrLogTor + Messageinfo.EchoTag +
                                      StrLogTr2)^.LogLn;

        If (MessageInfo.FName = '') or (MessageInfo.mFrom = '') or
           (MessageInfo.Subj = '') or (MessageInfo.MsgBas = '') or
           (GlobalInfo.PktMode and (MessageInfo.AreaType = EchoMail) and
           (MessageInfo.EchoTag = '')) or (GlobalInfo.PktMode and
           (MessageInfo.AreaType = Local)) then begin
          Log^.LogLine('!')^.LogStr(StrLogMis)^.LogInt(GlobalInfo.Ctr)^.LogLn;
        end else begin
          FDate := 0; { Nolla fildatum }

          If IntervalDate then begin { Posta bara speciellt datum? }
            If GlobalInfo.Idag.Day <> Interval then { Fel datum? }
              DaysSince := 0 { posta inte }
            else begin
              If GlobalInfo.Idag.Month <> MessageInfo.CurrentRec.LastWritten.Month then
                DaysSince := 65535; { posta }
            end;
          end else begin
            If MessageInfo.CurrentRec.LastWritten.Day = 0 then
              DaysSince := 65535
            else
              {$IFDEF OS2}
              DaysSince := check_date(FormattedDate(DosDateTime2OS2DateTime(GlobalInfo.Idag),
                                                    'MM-DD-YY'),
                                      FormattedDate(DosDateTime2OS2DateTime(MessageInfo.CurrentRec.LastWritten),
                                                    'MM-DD-YY'));
              {$ELSE}
              DaysSince := check_date(FormattedDate(GlobalInfo.Idag, 'MM-DD-YY'),
                                      FormattedDate(MessageInfo.CurrentRec.LastWritten, 'MM-DD-YY'));
              {$ENDIF}
          end;

          SemaphorExist := True;
          If SemaphorFile <> '' then
            SemaphorExist := FileExist(SemaphorFile);

          TooSmall := False;
          If MinSize <> -1 then begin
            Assign(Semaphor, MessageInfo.FName);
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
          If (UpdatedSend = True) and (MessageInfo.CurrentRec.LastWritten.Day <> 0) then begin
            If FDate = 0 then begin { Ingen undansparad filtid }
              Assign(Semaphor, MessageInfo.FName);
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
                         {$IFDEF OS2}
                         DTToUnixDate(DosDateTime2OS2DateTime(MessageInfo.CurrentRec.LastWritten));
                         {$ELSE}
                         DTToUnixDate(MessageInfo.CurrentRec.LastWritten);
                         {$ENDIF}
            end;
          end; { If UpdatedSend }

          PostThis := False;                    { Flagga om postning }

          If WhatToDo = PostForce then begin
            PostThis := True;                   { Posta alltid }
            Log^.LogLine('!')^.LogStr(StrLogFor)^.LogInt(GlobalInfo.Ctr)^.LogLn;
          end else If WhatToDo = PostForceAsk then begin
            Write(StrAskPos, MessageInfo.Subj, StrAskPo2);  { Fr†ga om postning }
            If MessageInfo.EchoTag <> '' then
              Write(MessageInfo.EchoTag)
            else
              Write(MessageInfo.MsgBas);
            Write(StrAskPo3);

            Readln(AskPostAnswer);
            PostThis := UpCase(AskPostAnswer) = ChrYes;

            If PostThis then begin
              Log^.LogLine('!')^.LogStr(StrLogFor)^.LogInt(GlobalInfo.Ctr)^.LogLn;
            end else begin
              Log^.LogLine('!')^.LogStr(StrLogFno)^.LogInt(GlobalInfo.Ctr)^.
                   LogStr(StrLogFn2)^.LogLn;
            end;
          end else begin
            If DaysSince >= Interval then begin { Kolla om ska postas }
              If SemaphorExist = True then begin
                If not TooSmall then begin
                  If Updated then begin
                    PostThis := True;           { Ska postas }
                  end else begin { not Updated }
                    Log^.LogLine('-')^.LogStr(StrNotUpd)^.LogInt(GlobalInfo.Ctr);
                    If MessageInfo.EchoTag <> '' then
                      Log^.LogStr(StrDidSv2 + MessageInfo.EchoTag);
                    Log^.LogLn;
                  end; { If Updated }
                end else begin { TooSmall }
                  Log^.LogLine('-')^.LogStr(StrTooSml)^.LogInt(GlobalInfo.Ctr);
                  If MessageInfo.EchoTag <> '' then
                    Log^.LogStr(StrDidSv2 + MessageInfo.EchoTag);
                  Log^.LogLn;
                end; { If TooSmall }
              end else begin { not SemaphorExist }
                Log^.LogLine('-')^.LogStr(StrNotSem)^.LogInt(GlobalInfo.Ctr);
                If MessageInfo.EchoTag <> '' then
                  Log^.LogStr(StrDidSv2 + MessageInfo.EchoTag);
                Log^.LogLn;
              end; { If SemaphorExist }
            end else begin { not DaysSince }
              Log^.LogLine('-')^.LogStr(StrNotInt)^.LogInt(GlobalInfo.Ctr);
              If MessageInfo.EchoTag <> '' then
                Log^.LogStr(StrDidSv2 + MessageInfo.EchoTag);
              Log^.LogStr(StrNotIn2)^.LogLn;
              Log^.LogLine(' ')^.LogStr('  (');
              If IntervalDate then begin
                If Interval <> GlobalInfo.Idag.Day then begin
                  Log^.LogStr(StrNotIn4)^.LogInt(Interval)^.LogStr('.)')^.LogLn;
                end else begin
                  Log^.LogStr(StrNotIn5 + ')')^.LogLn;
                end;
              end else begin
                Log^.LogInt(DaysSince)^.LogStr(StrNotIn3)^.LogInt(Interval)^.
                     LogStr(')')^.LogLn;
              end;
            end; { If DaysSince }
          end; { If Force }

          If PostThis then begin
            If DoSimulate then begin
              Log^.LogLine(' ')^.LogStr(StrDidSav + StrDidSim + StrDidSv2);
              If (MessageInfo.AreaType = EchoMail) and
                 (MessageInfo.EchoTag <> '') then
                Log^.LogStr(MessageInfo.EchoTag)
              else
                Log^.LogStr(MessageInfo.MsgBas);
              Log^.LogStr(StrDidSv3)^.LogInt(GlobalInfo.Ctr)^.LogStr(')')^.LogLn;
              Inc(GlobalInfo.MsgWritten);
            end else begin { = not DoSimulate }
              PostResult := DoMessage(GlobalInfo, MessageInfo, PacketInfo);
              If PostResult = True then begin
                If Not LeaveDates then
                  MessageInfo.CurrentRec.LastWritten := GlobalInfo.Idag;
                {$I-}
                Seek(DataFile, MsgCount);
                Write(DataFile, MessageInfo.CurrentRec);
                If IOResult <> 0 then;
                {$I+}
              end; { If PostResult }
            end; { If DoSimulate }
          end; { If PostThis }

          Inc(MsgCount);
        end; { If "kr„vda delar ifyllda" }
      end else begin { = PlaceHolder }
        {$I-}
        Seek(DataFile, MsgCount);
        Read(DataFile, MessageInfo.CurrentRec);
        If IOResult <> 0 then begin
          FillChar(MessageInfo.CurrentRec, SizeOf(MessageInfo.CurrentRec), #0);
          Seek(DataFile, MsgCount);     { 0-fyll ickeexisterande poster }
          Write(DataFile, MessageInfo.CurrentRec);
          If IOResult <> 0 then;
        end; { If IOResult }
        {$I+}
        Inc(GlobalInfo.Ctr);
        Inc(MsgCount);
      end; { If PlaceHolder }
    end; { If EOF }
  Until EOF(Ini);

  { St„ng filer }

  Close(Ini);
  Close(DataFile);

  { Avallokera objekt }

  Dispose(MsgId_p);

  If TosserConfig_p <> Nil then
    Dispose(TosserConfig_p, Done);

  { Bygg PKT-fil }

  If GlobalInfo.PktMode and (GlobalInfo.MsgWritten <> 0) then begin
    If BinkleyName then
      PacketInfo.PktSpec := PktPath + LongWord(LongInt(PacketInfo.PktTo.Net)
                                               shl 16 + PacketInfo.PktTo.Node)
                            + '.OUT'
    else begin
      {$IFDEF OS2}
      PacketInfo.PktSpec := PktPath +
                            LongWord(((DTToUnixDate(DosDateTime2OS2DateTime(GlobalInfo.Idag))
                                                    and $7fffffff) shl 4) +
                                     Random(16)) + '.PKT';
      {$ELSE}
      PacketInfo.PktSpec := PktPath + LongWord(((DTToUnixDate(GlobalInfo.Idag)
                                                 and $7fffffff) shl 4) +
                                               Random(16)) + '.PKT';
      {$ENDIF}
    end;
    If DoSimulate then begin
      Log^.LogLine(' ')^.LogStr(StrLogPkt + StrDidSim + ' ' +
                                PacketInfo.PktSpec)^.LogLn;
    end else
      buildpacket(GlobalInfo, PacketInfo);
  end; { If GlobalInfo.PktMode }
End.
