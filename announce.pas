{************************************************************************}
{* Program:     Announcer                                               *}
{************************************************************************}
{* Fîrfattare:  Peter Karlsson                                          *}
{* Datum:       1996-04-27                                              *}
{* Version:     1.00                                                    *}
{************************************************************************}
{* Moduler:                                                             *}
{************************************************************************}
{************************************************************************}
{* Modul:       Announce.Pas                                            *}
{************************************************************************}
{* InnehÜll:    Announcers huvudprogram                                 *}
{************************************************************************}
{* Funktion:    Postar filer i lokala brevareor                         *}
{************************************************************************}
{* Rutiner:                                                             *}
{************************************************************************}
{* Revision:                                                            *}
{*  v0.10 - 1995-03-08 - Fîrsta versionen                               *}
{*  v0.11 - 1995-07-19 - Strippar tecken under #32 (ej CRLF)            *}
{*  v0.20 - 1995-08-01 - Kan ta annan konf.fil och namn pÜ kommandorad  *}
{*  v0.21 - 1995-08-19 - Kollar om konfigurationsfilen existerar.       *}
{*  v0.22 - 1995-10-28 - Taglines + lite annat skoj                     *}
{*  v0.23 - 1995-10-31 - Registreringskod ska fungera                   *}
{*  v0.25 - 1995-11-09 - Loggfil                                        *}
{*  v0.30 - 1996-01-07 - MSGID igen, netmail, echomail, slumptaglinefil *}
{*  v0.31 - 1996-02-03 - ReadRandomLine fîrbÑttrat, intervall           *}
{*  v1.00 - 1996-04-27 - Mîjlighet att visa data, /Q, /M                *}
{************************************************************************}
Program Announcer;

{$I MKB.Def}
{$D+,G+}

Uses Dos, MKFile, MKString, MKMsgAbs, MKOpen, MKGlobT, MKDos, MKMisc, NLS,
     Crypt, AnHelp, AnStr, ChekDate;

const
  version  = 'v1.00';
  (*{ $ DEFINE BETA}*)
  logname  = ' ANNO ';
  MonthStr: array[1..12] of string[3] = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  HexChars: array[0..15] of char = '0123456789abcdef';

  bragline: string = 'Announcer ' + version;

var
  registration,
  echotosslogfile:      string;
  braglineintro,
  taglineintro:         string[3];
  logfile, stderr:      text;
  logtofile:            boolean;
  msgidstring:          string[32];
  msgidnum:             longint;
  idag:                 datetime;
  ctr:                  word;
  exitsave:             pointer;

type
  MsgType = (Local, Netmail, Echomail);
  RunMode = (DoPost, DisplayData, Simulate);
  FindPosType = record
                  case byte of
                    0: (low, high: word;);
                    1: (long: longint;);
                  end;
  DataFileRec = record
                  lastwritten: DateTime;
                  msgidstring: string[32];
                  msgidnum: longint;
                end;
  FileOfDataFileRec = File Of DataFileRec;

{************************************************************************}
{* Rutin:       LogTime                                                 *}
{************************************************************************}
{* InnehÜll:    Skapar en Squishstyle lograd                            *}
{* Definition:  Function LogTime: String;                               *}
{************************************************************************}

Function LogTime: String;
Var
  Year, Month, Day, Hour, Min, Sec, Dummy: Word;
Begin
  GetTime(Hour, Min, Sec, Dummy);
  GetDate(Year, Month, Day, Dummy);
  LogTime := NumStr(Day, 2) + ' ' + MonthStr[Month] + ' ' + NumStr(Hour, 2) +
             ':' + NumStr(Min, 2) + ':' + NumStr(Sec, 2)
End;

{************************************************************************}
{* Rutin:       Leave                                                   *}
{************************************************************************}
{* InnehÜll:    Avslutar Announcer vid kîrtidsfel                       *}
{* Definition:  Procedure Leave;                                        *}
{************************************************************************}

{$F+}
Procedure Leave;
Begin
  ExitProc := ExitSave;
  If logtofile then begin
    If ErrorAddr <> nil then begin
      Writeln(logfile, '! ', LogTime, logname, StrLogRun, ExitCode);
    end;
    Writeln(logfile, '+ ', LogTime, logname, StrLogEnd, bragline);
    Close(logfile);
    logtofile := false;
  end;
End;
{$F-}

{************************************************************************}
{* Rutin:       DateString                                              *}
{************************************************************************}
{* InnehÜll:    FramstÑller en datumstrÑng MM-DD-èè                     *}
{* Definition:  Function DateString(Date: DateTime): String;            *}
{************************************************************************}

Function DateString(Date: DateTime): String;
Var
  OutStr: String[8];
  TempStr: String[8];

Begin
  Str(Date.Month:2, TempStr);
  If TempStr[1] = ' ' Then
    OutStr[1] := '0'
  Else
    OutStr[1] := TempStr[1];
  OutStr[2] := TempStr[2];
  OutStr[3] := '-';
  Str(Date.Day:2, TempStr);
  If TempStr[1] = ' ' Then
    OutStr[4] := '0'
  Else
    OutStr[4] := TempStr[1];
  OutStr[5] := TempStr[2];
  OutStr[6] := '-';
  Str(Date.Year:4, TempStr);
  If TempStr[3] = ' ' Then
    OutStr[7] := '0'
  Else
    OutStr[7] := TempStr[3];
  OutStr[8] := TempStr[4];
  OutStr[0] := #8;
  DateString := OutStr;
End;

{************************************************************************}
{* Rutin:       Longword                                                *}
{************************************************************************}
{* InnehÜll:    FramstÑller en hexadecimalstrÑng                        *}
{* Copyright:   Eddy Jansson <2:206/408>                                *}
{* Definition:  Function LongWord(dwrd: Longint): String; Assembler;    *}
{************************************************************************}

Function LongWord(dwrd: Longint): String; Assembler;
asm
 push ds
 push cs
 pop  ds
 lea bx,@tabel
 les di,@result
 cld
 mov al,8
 stosb
 mov ax,word ptr dwrd+2
 mov cx,ax
 mov dx,ax
 and dx,0f0f0h
 and cx,0f0fh
 shr dx,1
 shr dx,1
 shr dx,1
 shr dx,1
 mov al,dh
 xlat
 stosb
 mov al,ch
 xlat
 stosb
 mov al,dl
 xlat
 stosb
 mov al,cl
 xlat
 stosb
 mov ax,word ptr dwrd
 mov cx,ax
 mov dx,ax
 and dx,0f0f0h
 and cx,00f0fh
 shr dx,1
 shr dx,1
 shr dx,1
 shr dx,1
 mov al,dh
 xlat
 stosb
 mov al,ch
 xlat
 stosb
 mov al,dl
 xlat
 stosb
 mov al,cl
 xlat
 stosb
 pop ds
 jmp @yt
@tabel:
 db '0123456789abcdef'
@yt:
end;

{************************************************************************}
{* Rutin:       ReadRandomLine                                          *}
{************************************************************************}
{* InnehÜll:    LÑser en slumpmÑssig rad ur en textfil                  *}
{* Copyright:   SlÑppt som Public Domain av Peter Karlsson <2:204/137.5>*}
{* Definition:  Function ReadRandomLine(filename: string): string;      *}
{************************************************************************}

Function ReadRandomLine(filename: string): string;
var
  findpos: findpostype;
  readfile: file of char;
  mypos: longint;
  ch: char;
  line: string;
begin
  {$I-}
  Assign(readfile, filename);
  Reset(readfile);
  If IOResult = 0 then begin
    findpos.low := Random(65535);
    findpos.high := Random(32768); { Fîr att undvika negativa tal }
    mypos := findpos.long mod FileSize(readfile);
    Seek(readfile, mypos);
    Read(readfile, ch);
    While ((mypos > 0) and (ch <> #13) and (ch <> #10)) do begin
      Dec(mypos);               { Sîk till fîregÜende radslut el. BOF }
      Seek(readfile, mypos);
      Read(readfile, ch);
    end;
    If (mypos = 0) or (eof(readfile)) then Seek(readfile, 0);
    line := '';
    Read(readfile, ch);
    While (ch = #10) or (ch = #13) do begin   { Om vi Ñr i ett radslut }
      Read(readfile, ch);
      If eof(readfile) then Seek(readfile, 0);
    end;
    While ((not eof(readfile)) and (ch <> #13) and (ch <> #10)) do begin
      line := line + ch;
      Read(readfile, ch);
    end;
    Close(readfile);
    ReadRandomLine := line;
  end else
    ReadRandomLine := 'Could not open ' + filename;
  {$I+}
end;


{************************************************************************}
{* Rutin:       RemoveJunk                                              *}
{************************************************************************}
{* InnehÜll:    Tar bort îverflîdiga mellanslag i en textrad            *}
{* Definition:  Procedure RemoveJunk(var s: string);                    *}
{************************************************************************}

Procedure RemoveJunk(var s: string);
var
  tmp:          string;
  wasspace:     boolean;
  i:            integer;
  c:            char;
Begin
  tmp := '';
  If (Copy(s, 1, 1) <> '%') and (Copy(s, 1, 1) <> ';') then
  begin
    While s[1] = ' ' do
      s := Copy(s, 2, Length(s)-1);
    For i:=1 to Length(s) do
    begin
      c := s[i];
      If ((c = #9) or  (c = ' ')) then
        Case wasspace of
          FALSE: begin
            tmp := tmp + ' ';
            wasspace := TRUE;
          end;
        end; { Case }
      If not ((c = #9) or (c = ' ')) then
      begin
        wasspace := false;
        tmp := tmp + c;
      end; { If tab/space }
    end; { For }
  end; { If '%' ';' }
  s := tmp;
End;

{************************************************************************}
{* Rutin:       RmUnderline                                             *}
{************************************************************************}
{* InnehÜll:    ôversÑtter _ i en strÑng till mellanslag                *}
{* Definition:  Function RmUnderline(instring: string): string;         *}
{************************************************************************}

Function RmUnderline(instring: string): string;
Begin
  while Pos('_', instring) > 0 do
    instring[Pos('_', instring)] := ' ';
  RmUnderline := instring;
End;

{************************************************************************}
{* Rutin:       domessage                                               *}
{************************************************************************}
{* InnehÜll:    FramstÑller ett meddelande enligt angivna parametrar    *}
{* Definition:  Procedure domessage(mfrom, mto, subj, fname, msgbas:    *}
{*              string; priv: boolean; tagline, origin: string;         *}
{*              areatype: msgtype; orig, dest: addrtype; echotag: string;}
{*              var currentrec: datafilerec; headerfile, footerfile:    *}
{*              string);                                                *}
{************************************************************************}

Procedure domessage(mfrom, mto, subj, fname, msgbas: string; priv: boolean;
                    tagline, origin: string; areatype: msgtype; orig, dest:
                    addrtype; echotag: string; var currentrec: datafilerec;
                    headerfile, footerfile: string);
var
  tf, head, foot:  TFile;
  tmpStr, tmpStr2: string;
  msg:             absmsgptr;
  i:               byte;
  EchoToss:        text;
  writeEchoToss:   boolean;
  msgnum:          longint;
  idstring:        string;
begin
  idstring := '';

  TF.Init; { Initiera textfilsobjektet }
  If TF.OpenTextFile(fname) then begin
    If OpenMsgArea(msg, msgbas) then begin
      Case areatype of
        local: begin
          msg^.setmailtype(mmtNormal);  { Mîtestyp }
          msg^.startnewmsg;
          msg^.setecho(false);          { Ska ej ekas }
          msg^.setpriv(priv);
          msg^.setrefer(0);             { Ingen lÑnkning }
          idstring := Msgidstring;
        end;
        netmail: begin
          msg^.setmailtype(mmtNetmail);
          msg^.startnewmsg;
          msg^.setorig(orig);           { AvsÑndaradress }
          msg^.setdest(dest);
          msg^.setecho(true);           { Ska ekas }
          msg^.setpriv(true);
          msg^.setrefer(0);
          idstring := AddrStr(Orig);    { AdresstrÑng fîr MSGID }
          { FMPT och TOPT krÑvs ibland fîr att fÜ adresserna rÑtt,
            de skrivs automatiskt i MSG och Hudson. I JAM ignoreras de ÑndÜ }
          If (UpCase(msgbas[1]) <> 'F') and (UpCase(msgbas[1]) <> 'H') then
          begin
            If orig.point <> 0 then
              msg^.DoKludgeLn(#1'FMPT ' + Long2Str(orig.point));
            If dest.point <> 0 then
              msg^.DoKludgeLn(#1'TOPT ' + Long2Str(dest.point));
          end;
        end;
        echomail: begin
          msg^.setmailtype(mmtEchomail);
          msg^.startnewmsg;
          msg^.setorig(orig);
          msg^.setecho(true);
          msg^.setpriv(false);
          msg^.setrefer(0);
          idstring := AddrStr(Orig);
        end;
      end; { Case }

      { Meddelandeheader }
      msg^.setfrom(mfrom);
      msg^.setto(mto);
      msg^.setsubj(subj);
      msg^.setdate(mkstring.datestr(getdosdate));
      msg^.settime(mkstring.timestr(getdosdate));
      msg^.setlocal(true);

      If idstring <> '' then
        msg^.DoKludgeLn(#1'MSGID: ' + idstring + ' ' + LongWord(MsgIdNum));
      If currentrec.msgidstring <> '' then
        msg^.DoKludgeLn(#1'REPLY: ' + currentrec.msgidstring + ' ' +
                        LongWord(currentrec.msgidnum));
      currentrec.msgidstring := idstring;
      currentrec.msgidnum := MsgIdNum;
      Inc(MsgIdNum);

      msg^.DoKludgeLn(#1'CHRS: IBMPC 2');

      If areatype = local then
        msg^.DoKludgeLn(#1'MOOD: Mechanic [:]');

      If Registration = StrNotReg then
        msg^.DoKludgeLn(#1'NOTE: Evaluation version');

      { LÑgg till ev. headerfil }
      If headerfile <> '' then begin
        head.Init;
        If head.OpenTextFile(headerfile) then begin
          tmpstr := head.GetString;
          While head.StringFound do begin
            tmpstr2 := '';
            For i := 1 to Length(tmpstr) do
              If (tmpstr[i] >= #32) or ((tmpstr[i] = #1) and (i = 1)) then
                tmpstr2 := tmpstr2 + tmpstr[i];
            If length(tmpstr2) > 0 then
              Case tmpstr2[1] of
                #1: msg^.dokludgeln(tmpstr2);
                else msg^.dostringln(tmpstr2)
              end { Case }
            else
              msg^.dostringln('');
            tmpstr := head.GetString;
          end; { While }
          If head.CloseTextFile then;
        end; { If head.OpenTextFile }
      end; { If headerfile }

      { LÑs in textfilen }
      tmpstr := TF.GetString;
      while TF.Stringfound do begin
        tmpstr2 := '';
        for i := 1 to Length(tmpstr) do
          if (tmpstr[i] >= #32) or ((tmpstr[i] = #1) and (i = 1)) then
            tmpstr2 := tmpstr2 + tmpstr[i];
        if length(tmpstr2) > 0 then
          case tmpstr2[1] of
            #1: msg^.dokludgeln(tmpstr2);
            else msg^.dostringln(tmpstr2)
          end { Case }
        else
          msg^.dostringln('');
        tmpstr := TF.GetString;
      end; { While }
      If TF.CloseTextFile then;

      { LÑgg till ev. fotfil }
      If footerfile <> '' then begin
        foot.Init;
        If foot.OpenTextFile(footerfile) then begin
          tmpstr := foot.GetString;
          While foot.StringFound do begin
            tmpstr2 := '';
            For i := 1 to Length(tmpstr) do
              If (tmpstr[i] >= #32) or ((tmpstr[i] = #1) and (i = 1)) then
                tmpstr2 := tmpstr2 + tmpstr[i];
            If length(tmpstr2) > 0 then
              Case tmpstr2[1] of
                #1: msg^.dokludgeln(tmpstr2);
                else msg^.dostringln(tmpstr2)
              end { Case }
            else
              msg^.dostringln('');
            tmpstr := foot.GetString;
          end; { While }
          If foot.CloseTextFile then;
        end; { If foot.OpenTextFile }
      end; { If footerfile }

      { Avsluta }
      msg^.dostringln('');
      If tagline <> '' then
        msg^.dostringln(taglineintro + ' ' + tagline);
      msg^.dostringln(braglineintro + ' ' + bragline);

      { Alltid tearline i echomail }
      If (areatype = echomail) then begin
        If braglineintro <> '---' then
          msg^.dostringln('---');
        tmpstr := origin + ' (' + AddrStr(orig) + ')';
        If Length(tmpstr) > 68 then tmpstr := Copy(tmpstr, Length(tmpstr)
                                                   - 67, 68);
        msg^.dostringln(' * Origin: ' + tmpstr);
      end;

      { Skriv det, logga om det inte lyckades }
      if msg^.writemsg <> 0 then begin
        writeln(StrErrSav, subj, '"');
        If logtofile then Writeln(logfile, '! ', LogTime, logname, StrLogSav,
                                  ctr);
      end else begin
        msgnum := msg^.getmsgnum;
        writeln(StrDidSav, msgnum, StrDidSv2, msgbas, StrDidSv3, ctr, ')');
        If logtofile then Writeln(logfile, '  ', LogTime, logname, StrDidSav,
                                  msgnum, StrDidSv2, msgbas, StrDidSv3, ctr,
                                  ')');
        { Skriv post i Echotoss.log-filen }
        If (echotag <> '') and (echotosslogfile <> '') then begin
          writeEchoToss := true;
          Assign(EchoToss, echotosslogfile);
          {$I-}
          Reset(EchoToss);
          If IOResult = 0 then begin
            While (not eof(EchoToss)) do begin
              Readln(EchoToss, tmpStr);
              If UpStr(tmpStr) = echotag then
                writeEchoToss := false;
            end; { While }
            Close(EchoToss);
          end else begin
            Rewrite(EchoToss);
            If IOResult <> 0 then begin
              Writeln(StrErrTos, echotosslogfile);
              If logtofile then Writeln(logfile, '! ', LogTime, logname,
                                        StrLogTos, echotosslogfile);
            end else begin
              Writeln(EchoToss, echotag);
              Close(EchoToss);
            end; { If IOResult }
            writeEchoToss := false;
          end; { If IOResult }
          If writeEchoToss = true then begin
            Append(EchoToss);
            If IOResult <> 0 then begin
              Writeln(StrErrTo2, echotosslogfile);
              If logtofile then Writeln(logfile, '! ', LogTime, logname,
                                        StrLogTo2, echotosslogfile);
            end else begin
              Writeln(EchoToss, echotag);
              Close(EchoToss);
            end; { If IOResult }
          end; { If writeEchoToss }
          {$I+}
        end;
      end;
      If CloseMsgArea(msg) then;
    end else begin
      writeln(StrErrBas, msgbas);
      If logtofile then Writeln(logfile, '! ', LogTime, logname, StrLogBas,
                                msgbas);
    end;
  end else begin
    writeln(StrErrFil, fname);
    If logtofile then Writeln(logfile, '! ', LogTime, logname, StrLogFil,
                              fname);
  end;
  TF.Done;
end;

{************************************************************************}
{* Rutin:       DisplayInfo                                             *}
{************************************************************************}
{* InnehÜll:    Visar information om postning                           *}
{* Definition:  Procedure DisplayInfo(IniFile: String);                 *}
{************************************************************************}

Procedure DisplayInfo(IniFile: String; Maint: Boolean);
Var
  ini:                                          text;
  datafile, newdatafile:                        file of datafilerec;
  currentrec:                                   datafilerec;
  counter, dayssince, interval, temp:           word;
  rad, data:                                    string;
  found:                                        boolean;
Begin
  Assign(ini, inifile);
  {$I-}
  Reset(ini);
  If IOResult <> 0 then begin
    { Kolla om filen finns med tillÑgget .INI }
    Assign(ini, inifile + '.INI');
    Reset(ini);
    If IOResult <> 0 then begin
      Writeln(stderr, StrErrOp1, inifile, StrErrOp2);
      Writeln(stderr, inifile, '.INI');
      Halt(1);
    end; { If IOResult }
    inifile := inifile + '.INI';
    Writeln(#254#32, inifile);
  end else { If IOResult }
    Writeln(#254#32, inifile);

  { ôppna datafilen }
  Assign(datafile, Copy(inifile, 1, length(inifile) - 4) + '.DAT');
  Reset(datafile);
  If IOResult <> 0 then begin
    Writeln(stderr, StrErrDaf, Copy(inifile, 1, length(inifile) - 4) + '.DAT');
    Halt(1);
  end; { If IOResult }

  { NamnÑndra datafilen om vi kîr i maintanence-lÑge, och îppna en ny }
  If Maint = True then begin
    Close(datafile);
    Rename(datafile, Copy(inifile, 1, length(inifile) - 4) + '.OLD');
    If IOResult <> 0 then begin
      Writeln(stderr, StrErrDar);
      Halt(1);
    end; { If IOResult }
    Reset(datafile);
    Assign(newdatafile, Copy(inifile, 1, length(inifile) - 4) + '.DAT');
    Rewrite(newdatafile);
    If IOResult <> 0 then begin
      Writeln(stderr, StrErrDat, Copy(inifile, 1, length(inifile) - 4), '.DAT');
      Halt(1);
    end; { If IOResult }
  end; { If Maint }
  {$I+}

  counter := 0;
  While not eof(datafile) do begin
    Read(datafile, currentrec);
    Inc(counter);
    found := false;

    If not eof(ini) then begin
      { Leta efter mallen }
      Repeat
        Readln(ini, rad);
      Until (UpStr(rad) = 'MSG') or (Eof(ini));

      If not eof(ini) then begin
        found := true;
        interval := 0;
        Repeat
          Readln(ini, rad);
          rad := UpStr(rad);
          If Copy(rad, 1, 8) = 'INTERVAL' then begin
            data := Copy(rad, 10, Length(rad)-9);
            Val(data, interval, temp)
          end;
        Until rad = '.END';
      end; { If not eof }
    end; { If not eof }

    If currentrec.lastwritten.day <> 0 then begin
      Write(StrInfMsg, counter, StrInfLst, NLS.DateStr(currentrec.lastwritten),
            StrInfClk, NLS.TimeStr(currentrec.lastwritten), ' (');
      dayssince := check_date(DateString(idag),
                              DateString(currentrec.lastwritten));
      Case dayssince of
      0: Writeln(StrInfTod);
      1: Writeln(StrInfYst);
      else
        Writeln(dayssince, StrInfAgo);
      end; { Case }
    end else begin
      Writeln(StrInfNop);
    end; { If day <> 0 }

    If found then begin
      If interval = 0 then
        Writeln(StrInfNoi)
      else begin
        Write(StrInfInt, interval, StrInfDag);
        If dayssince < interval then
          Writeln(StrInfLes)
        else
          Writeln(StrInfMor);
      end; { If interval }
      If Maint then Write(newdatafile, currentrec);
    end else begin
      Writeln(StrInfFnn);
      If Maint then Writeln(StrInfRem);
    end; { If found }

    If currentrec.msgidstring <> '' then
      Writeln(' MSGID: ', currentrec.msgidstring, ' ',
              LongWord(currentrec.msgidnum));
  end; { While not eof }

  If Maint then begin
    Close(datafile);
    Erase(datafile);
    Close(newdatafile);
  end; { If Maint }
end;

{************************************************************************}
{* Rutin:       Initialize                                              *}
{************************************************************************}
{* InnehÜll:    Initialiserar globala variabler                         *}
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

  MsgIdNum := DTToUnixDate(idag);
  Registration := StrNotReg;
  Braglineintro := '---';
  Taglineintro := '...';
  Msgidstring := '';
  logtofile := false;
  echotosslogfile := '';
  ctr := 0;
End;

{************************************************************************}
{* Rutin:       main                                                    *}
{************************************************************************}
{* InnehÜll:    Huvudrutin                                              *}
{* Definition:  -                                                       *}
{************************************************************************}

Var
  ini:                                          text;
  inifile, rad, name1, name2, mfrom, mto, subj,
  fname, msgbas, keyword, data, tagline, env,
  origin, echotag, tagfile, headerfile,
  footerfile:                                   string;
  priv, maint:                                  boolean;
  position, numtaglines, i, namecount, interval,
  dayssince:                                    word;
  RegCode:                                      longint;
  test:                                         integer;
  Distribution:                                 MsgType;
  OrigAddr, DestAddr, TempAddr:                 AddrType;
  msgcount, temp:                               Word;
  datafile:                                     File of datafilerec;
  WhatToDo:                                     RunMode;
  currentrec:                                   datafilerec;
Begin
  { Initiera variabler }
  ExitSave := ExitProc;         { Critical error handler }
  ExitProc := @Leave;
  msgcount := 0;
  numtaglines := 0;
  Origin := StrStdOri;
  tagfile := '';

  Randomize;
  Initialize;

  Assign(Output, '');           { TillÜt omdirigering }
  Rewrite(Output);

  Assign(stderr, '');           { ôppna stderr-handtaget }
  Rewrite(stderr);
  TextRec(stderr).Handle := 2;

  { Kolla registreringen }
  Env := GetEnv('ANNOUNCER');
  If Env <> '' then begin
    Val(Copy(Env, 1, 5), RegCode, Test);
    If (Test = 0) and (RegCode = RegiCode(Copy(Env, 6, Length(Env)-5))) then
    begin
      Registration := Copy(Env, 6, Length(Env) - 5);
      Bragline := Bragline + '+';       { Identifiera registrerad version }
    end;
  end; { If Env }

  { ** Fîr begrÑnsad betatest ** }
  {$IFDEF BETA}
  If Registration = StrNotReg then begin
    Writeln(stderr, StrErrReg);
    Halt(255);
  end; { If Registration }
  {$ENDIF}

  If ParamStr(1) = '/?' then
    HelpScreen(bragline, registration);

  If Registration = StrNotReg then
    Bragline := Bragline + ' [NR]';

  namecount := 0;
  name1 := 'Announcer';
  name2 := name1;

  inifile := Copy(ParamStr(0), 1, Length(ParamStr(0)) - 4) + '.INI';
  WhatToDo := DoPost;
  Maint := False;

  { Kolla kommandoradsvÑxlar }
  For i := 1 to ParamCount do begin
    data := ParamStr(i);
    if data[1] = '/' then begin
      Case UpCase(data[2]) of
        'I': inifile := FExpand(Copy(ParamStr(i), 3, Length(ParamStr(i)) - 2));
        'D': WhatToDo := DisplayData;
        'M': Maint := True;
{       'S': WhatToDo := Simulate;       }
        'Q': begin
          Assign(Output, 'NUL');
          Rewrite(Output);
        end;
        else begin
          Writeln(stderr, StrErrPar);
          Writeln(stderr, data);
          Halt(3);
        end;
      end; { Case }
    end else begin
      Case namecount of
        0: begin
             name1 := RmUnderline(data);
             namecount := 1;
           end;
        1: begin
             name2 := RmUnderline(data);
             namecount := 2;
           end;
        2: begin
             Writeln(stderr, StrErrPar);
             Writeln(stderr, data);
             Halt(3);
           end;
      end; { Case namecount }
    end; { If '/' }
  end; { For i }

  If WhatToDo = DisplayData then begin
    DisplayInfo(inifile, maint);
    Halt;
  end;

  Assign(ini, inifile);
  {$I-}
  Reset(ini);
  If IOResult <> 0 then begin
    Assign(ini, inifile + '.INI');
    Reset(ini);
    If IOResult <> 0 then begin
      Writeln(stderr, StrErrOp1, inifile, StrErrOp2);
      Writeln(stderr, inifile, '.INI');
      Halt(1);
    end; { If IOResult }
    inifile := inifile + '.INI';
  end; { If IOResult }

  Assign(datafile, Copy(inifile, 1, length(inifile) - 4) + '.DAT');
  Reset(datafile);
  If IOResult <> 0 then begin
    Rewrite(datafile);
    If IOResult <> 0 then begin
      Writeln(stderr, StrErrDat, Copy(inifile, 1, length(inifile) - 4) +
              '.DAT');
      Halt(1);
    end; { If IOResult }
  end; { If IOResult }
  {$I+}

  Repeat { Until EOF }
    Repeat { Until 'MSG' or EOF }
      Readln(ini, rad);
      RemoveJunk(rad);

      If (rad[1]<>';') and (UpStr(rad)<>'.END') then begin
        Position := Pos(' ', rad);
        If Position <> 0 then begin
          keyword := UpStr(Copy(rad, 1, Position-1));
          data := Copy(rad, Position+1, Length(rad)-Position);
          If data = '%1' then data := name1;
          If data = '%2' then data := name2;
{$IFDEF MY} Writeln(keyword, ': ', data); {$ENDIF}
          If keyword = 'TAGLINEFILE' then begin
            tagfile := data
          end else if keyword = 'BRAGLINEINTRO' then
            Braglineintro := Copy(data + '   ', 1, 3)
          else if Keyword = 'TAGLINEINTRO' then
            Taglineintro := Copy(data + '   ', 1, 3)
          else if Keyword = 'ECHOTOSSLOG' then
            EchoTossLogFile := data
          else if Keyword = 'LOGFILE' then begin
            If logtofile = true then begin
              Writeln(stderr, StrErrIni, inifile, ':');
              Writeln(stderr, StrErrLog);
              Close(ini);
              If logtofile then begin
                Writeln(logfile, '+ ', LogTime, logname, StrLogEnd, bragline);
                Close(logfile);
                logtofile := false;
              end; { If logtofile }
              Halt(2);
            end else begin
              Assign(logfile, data);
              {$I-}
              Append(logfile);
              If IOResult <> 0 then begin
                Rewrite(logfile);
                If IOResult <> 0 then begin
                  Writeln(stderr, StrErrLo2);
                  Close(ini);
                  Halt(2);
                end; { If IOResult }
              end; { If IOResult }
              {$I+}
              Writeln(logfile);
              Writeln(logfile, '+ ', LogTime, logname, StrLogBeg, bragline);
              Writeln(logfile, '  ', LogTime, logname, StrLogIni, inifile);
              logtofile := true;
            end;
          end else if Keyword = 'MSGID' then begin
            Msgidstring := data;
          end; { If Keyword }
        end; { If Position }
      end; { If ';' }
    Until (UpStr(rad) = 'MSG') or EOF(ini);

    If not EOF(ini) then begin
      Inc(ctr);
      headerfile := '';
      footerfile := '';
      tagline := '';
      Distribution := Local;
      echotag := '';
      interval := 0;
      dayssince := 0;
      FillChar(TempAddr, SizeOf(TempAddr), #0);

      Repeat { Until '.END' }
        {$I-}
        Seek(datafile, msgcount);
        Read(datafile, currentrec);
        If IOResult <> 0 then
          FillChar(currentrec, SizeOf(currentrec), #0);
        {$I+}
        Readln(ini, rad);
        If (rad[1]<>';') and (UpStr(rad)<>'.END') then begin
          Position := Pos(' ', rad);
          If Position <> 0 then begin
            keyword := UpStr(Copy(rad, 1, Position-1));
            data := Copy(rad, Position+1, Length(rad)-Position);
            if data = '%1' then data := name1;
            if data = '%2' then data := name2;
{$IFDEF MY} Writeln(keyword, ': ', data); {$ENDIF}
            If keyword = 'FROM' then
              mfrom := data
            else if keyword = 'TO' then
              mto := data
            else if keyword = 'SUBJECT' then
              subj := data
            else if keyword = 'FILE' then
              fname := data
            else if keyword = 'PATH' then
              msgbas := data
            else if keyword = 'PRIVATE' then
              case UpCase(data[1]) of
                'Y': priv := true;
                'N': priv := false;
              end
            else if keyword = 'DISTRIBUTION' then begin
              If UpStr(data) = 'NETMAIL' then
                distribution := NetMail
              else If UpStr(data) = 'ECHOMAIL' then
                distribution := EchoMail
              else If UpStr(data) = 'LOCAL' then
                distribution := Local;
            end else if keyword = 'ORIG' then begin
              If (not ParseAddr(data, TempAddr, OrigAddr)) or (OrigAddr.Zone =
                  0) then begin
                Writeln(stderr, StrErrIni, inifile, ':');
                Writeln(stderr, StrErrOrg, data);
                Close(ini);
                If logtofile then begin
                  Writeln(logfile, '+ ', LogTime, logname, StrLogEnd,
                          bragline);
                  Close(logfile);
                  logtofile := false;
                end; { If logtofile }
                Halt(2);
              end; { If Addr }
            end else if keyword = 'DEST' then begin
              If (not ParseAddr(data, TempAddr, DestAddr)) or (DestAddr.Zone =
                  0) then begin
                Writeln(stderr, StrErrIni, inifile, ':');
                Writeln(stderr, StrErrDst, data);
                Close(ini);
                If logtofile then begin
                  Writeln(logfile, '+ ', LogTime, logname, StrLogEnd,
                          bragline);
                  Close(logfile);
                  logtofile := false;
                end; { If logtofile }
                Halt(2);
              end; { If Addr }
            end else if keyword = 'ORIGIN' then
              origin := data
            else if keyword = 'ECHO' then
              echotag := UpStr(data)
            else if keyword = 'INTERVAL' then
              Val(data, interval, temp)
            else if keyword = 'HEADER' then
              headerfile := data
            else if keyword = 'FOOTER' then
              footerfile := data
            else if keyword = 'TAGLINE' then begin
              if data = '@' then begin
                if tagfile = '' then begin
                  Writeln(stderr, StrErrIni, inifile, ':');
                  Writeln(stderr, StrErrTag);
                  Close(ini);
                  If logtofile then begin
                    Writeln(logfile, '+ ', LogTime, logname, StrLogEnd,
                            bragline);
                    Close(logfile);
                    logtofile := false;
                  end; { If logtofile }
                  Halt(2);
                end; { If numtaglines }
                Repeat
                  tagline := ReadRandomLine(tagfile);
                Until ((tagline[1] <> ';') and (tagline[1] <> '%'))
              end else
                tagline := data;
            end else begin
              Writeln(stderr, StrErrIn2, inifile, ':');
              Writeln(stderr, rad);
              Close(ini);
              If logtofile then begin
                Writeln(logfile, '+ ', LogTime, logname, StrLogEnd, bragline);
                Close(logfile);
                logtofile := false;
              end; { If logtofile }
              Halt(2);
            end; { If keyword }
          end; { If Position }
        end; { If rad }
      Until UpStr(rad) = '.END';
      if currentrec.lastwritten.day = 0 then
        dayssince := 65535
      else
        dayssince := check_date(DateString(idag),
                                DateString(currentrec.lastwritten));
      If dayssince >= interval then begin
        domessage(mfrom, mto, subj, fname, msgbas, priv, tagline, origin,
                  distribution, origaddr, destaddr, echotag, currentrec,
                  headerfile, footerfile);
        currentrec.lastwritten := idag;
        {$I-}
        Seek(datafile, msgcount);
        Write(datafile, currentrec);
        If IOResult <> 0 then;
        {$I+}
      end else begin
        If logtofile then Writeln(logfile, '  ', LogTime, logname, StrNotInt,
                                  ctr, StrNotIn2, dayssince, StrNotIn3,
                                  Interval, ')');
      end; { If dayssince }
      Inc(msgcount);
    end; { If EOF }
  Until EOF(ini);

  Close(ini);

  If logtofile then begin
    Writeln(logfile, '+ ', LogTime, logname, StrLogEnd, bragline);
    Close(logfile);
    logtofile := false;
  end;
End.
