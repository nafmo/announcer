{************************************************************************}
{* Modul:       Config.Pas                                              *}
{************************************************************************}
{* Inneh†ll:    Objekt f”r inl„sning av tosserkonfigurationer           *}
{************************************************************************}
{* Funktion:    L„ser in konfigurationsfil fr†n SquishMail              *}
{************************************************************************}
{* Klasser:     Tosser (abstrakt ”verklass)                             *}
{*              +- TosserSquishMail                                     *}
{*              +- TosserFMail                                          *}
{*              +- TosserGEcho                                          *}
{*              +- TosserTerMail                                        *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.0  - 1997-07-18 - F”rsta versionen (SquishMail)                  *}
{*        - 1997-07-21 - FMail, GEcho                                   *}
{*        - 1997-08-09 - TerMail                                        *}
{************************************************************************}

{$X+,D-}

Unit
  Config;

Interface

Uses
  Globals, MkGlobT;

Type
  AreaDefinitionPointer = ^AreaDefinition;

  AreaDefinition = Record
    AreaType: MsgType;
    Path: String[100];
    EchoTag: String[80];
    Address: AddrType;
    Next: AreaDefinitionPointer;
  End;

  SquishMailData = Record
    MainAKA: AddrType;
  End;

  TerMailGroupData = Record
    GroupName: String[8];
    User: Byte;
  End;

  TerMailData = Record
    UserAddress: Array[1..16] of AddrType;
    Group: Array[1..23] of TerMailGroupData;
  End;

{************************************************************************}
{* Klass:       Tosser                                                  *}
{* Beskrivning: Abstrakt ”verklass f”r tosserhanteringsklasserna        *}
{* Metoder:     Init        (konstrukt”r)                               *}
{*              Done        (destrukt”r)                                *}
{*              Import      (dummy)                                     *}
{*              GetAreaInfo                                             *}
{************************************************************************}
  Tosser = object
    Areas: AreaDefinitionPointer;
    Constructor Init        ;
    Destructor  Done        ;
    Procedure   Import      (ConfigFile: String); Virtual;
    Function    GetAreaInfo (EchoTag: String; Var Path: String;
                             Var AKA: AddrType;
                             Var AreaType: MsgType): Boolean; Virtual;
  end;

  TosserPointer = ^Tosser;

{************************************************************************}
{* Klass:       TosserSquishMail                                        *}
{* Beskrivning: Anv„ndning av konfigurationsfil f”r SquishMail          *}
{* Metoder:     Init        (konstrukt”r)                               *}
{*              Done        (destrukt”r)                                *}
{*              Import                                                  *}
{*              GetAreaInfo („rvd enbart)                               *}
{************************************************************************}
  TosserSquishMail = object(Tosser)
    Data: SquishMailData;

    Constructor Init        ;
    Destructor  Done        ;
    Procedure   Import      (ConfigFile: String); virtual;
  end;

  TosserSquishMailPointer = ^TosserSquishMail;

{$IFNDEF OS2}
{************************************************************************}
{* Klass:       TosserFMail                                             *}
{* Beskrivning: Anv„ndning av konfigurationsfil f”r FMail               *}
{* Metoder:     Init        (konstrukt”r)                               *}
{*              Done        (destrukt”r)                                *}
{*              Import                                                  *}
{*              GetAreaInfo („rvd enbart)                               *}
{************************************************************************}
  TosserFMail = object(Tosser)
    Constructor Init        ;
    Destructor  Done        ;
    Procedure   Import      (ConfigFile: String); virtual;
  end;

  TosserFMailPointer = ^TosserFMail;

{************************************************************************}
{* Klass:       TosserGEcho                                             *}
{* Beskrivning: Anv„ndning av konfigurationsfil f”r GEcho               *}
{* Metoder:     Init        (konstrukt”r)                               *}
{*              Done        (destrukt”r)                                *}
{*              Import                                                  *}
{*              GetAreaInfo („rvd enbart)                               *}
{************************************************************************}
  TosserGEcho = object(Tosser)
    Constructor Init        ;
    Destructor  Done        ;
    Procedure   Import      (ConfigFile: String); virtual;
  end;

  TosserGEchoPointer = ^TosserGEcho;
{$ENDIF}

{************************************************************************}
{* Klass:       TosserTerMail                                           *}
{* Beskrivning: Anv„ndning av konfigurationsfil f”r TerMail             *}
{* Metoder:     Init        (konstrukt”r)                               *}
{*              Done        (destrukt”r)                                *}
{*              Import                                                  *}
{*              GetAreaInfo („rvd enbart)                               *}
{************************************************************************}
  TosserTerMail = object(Tosser)
    Constructor Init        ;
    Destructor  Done        ;
    Procedure   Import      (ConfigFile: String); virtual;
  end;

  TosserTerMailPointer = ^TosserTerMail;

{************************************************************************}

Implementation

Uses
  StrUtil, Nls,
{$IFNDEF OS2}
  FmStruct, GeStruct,
{$ENDIF}
  AnStr, MkString;

{************************************************************************}
{* Klass:       Tosser                                                  *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar objektets data                                *}
{* Definition:  Constructor Tosser.Init;                                *}
{************************************************************************}
Constructor Tosser.Init;
Begin
  Areas := Nil;
End;

{************************************************************************}
{* Metod:       Done (destrukt”r)                                       *}
{************************************************************************}
{* Inneh†ll:    Tar bort objektets data                                 *}
{* Definition:  Destructor Tosser.Done;                                 *}
{************************************************************************}
Destructor Tosser.Done;
Var
  Trav_p, Temp_p: AreaDefinitionPointer;
Begin
  { Ta bort m”teslistan }
  Trav_p := Areas;
  While (Trav_p <> Nil) do begin
{$IFDEF DEBUG}
    Writeln('Deallocating ', Trav_p^.EchoTag);
{$ENDIF}
    Temp_p := Trav_p;
    Trav_p := Temp_p^.Next;
    Dispose(Temp_p);
  end;
End;

{************************************************************************}
{* Metod:       Import                                                  *}
{************************************************************************}
{* Inneh†ll:    Dummymetod                                              *}
{* Definition:  Procedure Tosser.Import(ConfigFile: String);            *}
{************************************************************************}
Procedure Tosser.Import(ConfigFile: String);
Begin
End;

{************************************************************************}
{* Metod:       GetAreaInfo                                             *}
{************************************************************************}
{* Inneh†ll:    Letar p† ett m”te om det finns i konfigurationen        *}
{* Definition:  Function Tosser.GetAreaInfo(EchoTag: String;            *}
{*              Var Path: String; Var AKA: AddrType;                    *}
{*              Var AreaType: MsgType): Boolean;                        *}
{************************************************************************}
Function Tosser.GetAreaInfo(EchoTag: String; Var Path: String;
                            Var AKA: AddrType;
                            Var AreaType: MsgType): Boolean;
Var
  Trav_p: AreaDefinitionPointer;
Begin
  Trav_p := Areas;
  EchoTag := UpStr(EchoTag);
  While (Trav_p <> Nil) and (Trav_p^.EchoTag <> EchoTag) do
    Trav_p := Trav_p^.Next;

  If Trav_p = Nil then
    GetAreaInfo := False
  else begin
    GetAreaInfo := True;
    Path := Trav_p^.Path;
    EchoTag := Trav_p^.EchoTag;
    AKA := Trav_p^.Address;
    AreaType := Trav_p^.AreaType;
  end;
End;

{************************************************************************}
{* Klass:       TosserSquishMail                                        *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar objektets data                                *}
{* Definition:  Constructor TosserSquishMail.Init;                      *}
{************************************************************************}
Constructor TosserSquishMail.Init;
Begin
  Tosser.Init;
  FillChar(Data.MainAKA, SizeOf(AddrType), #0);
End;

{************************************************************************}
{* Metod:       Done (destrukt”r)                                       *}
{************************************************************************}
{* Inneh†ll:    Tar bort objektets data                                 *}
{* Definition:  Destructor TosserSquishMail.Done;                       *}
{************************************************************************}
Destructor TosserSquishMail.Done;
Begin
  Tosser.Done;
End;

{************************************************************************}
{* Metod:       Import                                                  *}
{************************************************************************}
{* Inneh†ll:    Importerar en konfigurationsfil                         *}
{* Definition:  Procedure TosserSquishMail.Import(ConfigFile: String);  *}
{************************************************************************}
Procedure TosserSquishMail.Import(ConfigFile: String);
Var
  Conf: Text;
  Line, Keyword, ConfData, Pt1, Pt2: String;
  TempAddr: AddrType;
  Temp_p: AreaDefinitionPointer;
  ParseSuccess: Boolean;
Begin
  Assign(Conf, ConfigFile);
  {$I-}
  Reset(Conf);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + ConfigFile)^.LogLn;
    Exit;
  end;

{$IFDEF DEBUG}
  Writeln('BEGIN IMPORT OF ', ConfigFile);
{$ENDIF}

  FillChar(TempAddr, SizeOf(TempAddr), #0);

  While not eof(Conf) do begin
    Readln(Conf, Line);
    If (Line[1] <> ';') and ParseINI(Line, Keyword, ConfData) then begin
      If (Data.MainAKA.Zone = 0) and (Keyword = 'ADDRESS') then begin
        ParseAddr(ConfData, TempAddr, Data.MainAKA);
{$IFDEF DEBUG}
        Writeln('MAINAKA ', AddrStr(Data.MainAKA));
{$ENDIF}
      end else If Keyword = 'INCLUDE' then begin
{$IFDEF DEBUG}
        Writeln('IMPORT ', ConfData);
{$ENDIF}
        Import(ConfData);
      end else If (Keyword = 'NETAREA') or (Keyword = 'ECHOAREA') or
                  (Keyword = 'LOCALAREA') then begin
{$IFDEF DEBUG}
        Writeln('Areadef: ', Line);
{$ENDIF}
        New(Temp_p);
        Temp_p^.Next := Areas;
        Areas := Temp_p;

        Case Keyword[1] of
          'N': Temp_p^.AreaType := NetMail;
          'E': Temp_p^.AreaType := EchoMail;
          'L': Temp_p^.AreaType := Local;
        end;

        ParseINI(ConfData, Pt1, Pt2);
        Temp_p^.EchoTag := Pt1;
        ParseINI(Pt2, Pt1, ConfData);
        Temp_p^.Path := 'F' + Pt1;
        Temp_p^.Address := Data.MainAKA;

        Repeat { Until not ParseSuccess }
          ParseSuccess := ParseINI(ConfData, Pt1, Pt2);
          If Not ParseSuccess then
            Pt1 := UpStr(ConfData);
          If (Length(Pt1) >= 2) and (Pt1[1] = '-') then begin
            Case Pt1[2] of
              '$': Temp_p^.Path[1] := 'S';
              'F': Temp_p^.Path[1] := 'F';
              'P': ParseAddr(Copy(Pt1, 3, Length(Pt1) - 2), Data.MainAKA, Temp_p^.Address);
            end; { Case }
          end; { If }

          ConfData := Pt2;
        Until not ParseSuccess;

{$IFDEF DEBUG}
        Writeln('TAG ', Temp_p^.EchoTag, ' PATH ', Temp_p^.Path,
                ' ADDRESS ', AddrStr(Temp_p^.Address),
                ' TYPE ', Byte(Temp_p^.AreaType));
{$ENDIF}

      end;
    end;
  end;

  Close(Conf);

{$IFDEF DEBUG}
  Writeln('END IMPORT OF ', ConfigFile);
{$ENDIF}

End;

{$IFNDEF OS2}
{************************************************************************}
{* Klass:       TosserFMail                                             *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar objektets data                                *}
{* Definition:  Constructor TosserFMail.Init;                           *}
{************************************************************************}
Constructor TosserFMail.Init;
Begin
  Tosser.Init;
End;

{************************************************************************}
{* Metod:       Done (destrukt”r)                                       *}
{************************************************************************}
{* Inneh†ll:    Tar bort objektets data                                 *}
{* Definition:  Destructor TosserFMail.Done;                            *}
{************************************************************************}
Destructor TosserFMail.Done;
Begin
  Tosser.Done;
End;

{************************************************************************}
{* Metod:       Import                                                  *}
{************************************************************************}
{* Inneh†ll:    Importerar FMails konfigruationsfiler                   *}
{* Definition:  Procedure TosserFMail.Import(ConfigFile: String);       *}
{************************************************************************}
Procedure TosserFMail.Import(ConfigFile: String);
Var
  FmailCFG:     File of FMailConfigType;
  FMailAR:      File;
  CFG_p:        ^FMailConfigType;
  Header_p:     ^FMailHeaderType;
  Echo_p:       ^FMailRawEchoType;
  i, NumRead:   Word;
  HudsonPath:   String;
  Temp_p:       AreaDefinitionPointer;
Begin
  New(CFG_p);

  { L„s in FMAIL.CFG (huvudkonfiguration) }
{$IFDEF DEBUG}
  Writeln('OPENING: ', ConfigFile);
{$ENDIF}
  Assign(FMailCFG, ConfigFile);
  {$I-}
  Reset(FMailCFG);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + ConfigFile)^.LogLn;
    Dispose(CFG_p);
    Exit;
  end;
  {$I+}
  Read(FMailCFG, CFG_p^);
  Close(FMailCFG);

  HudsonPath := ASCIZ(@CFG_p^.BBSPath);

  { l„s in FMAIL.AR (m”tesinst„llningar) }
{$IFDEF DEBUG}
  Writeln('OPENING: ', InSameDir(ConfigFile, 'FMAIL.AR'));
{$ENDIF}
  Assign(FMailAR, InSameDir(ConfigFile, 'FMAIL.AR'));
  {$I-}
  Reset(FMailAR, 1);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + InSameDir(ConfigFile, 'FMAIL.AR'))^.
         LogLn;
    Dispose(CFG_p);
    Exit;
  end;
  {$I+}

{$IFDEF DEBUG}
  Writeln('þ Reading header');
{$ENDIF}

  New(Header_p);
  BlockRead(FmailAR, Header_p^, SizeOf(Header_p^), NumRead);

  If (NumRead <> SizeOf(Header_p^)) or
     (Header_p^.DataType <> DATATYPE_AE) or
     (Header_p^.RecordSize <> SizeOf(Echo_p^)) then begin
    Log^.LogLine('!')^.
         LogStr(StrLogTr4 + Copy(ConfigFile, 1, Length(ConfigFile) - 3) + 'AR')^.
         LogLn;
    Dispose(CFG_p);
    Dispose(Header_p);
    Exit;
  end;

  { L„s m”tesdefinitioner ur FMAIL.AR }
  New(Echo_p);
  For i := 1 to Header_p^.TotalRecords do begin
{$IFDEF DEBUG}
    Writeln('þ Reading area entry ', i);
{$ENDIF}
    BlockRead(FmailAR, Echo_p^, SizeOf(Echo_p^), NumRead);

    If NumRead <> SizeOf(Echo_p^) then begin
      Log^.LogLine('!')^.
           LogStr(StrLogTr4 + Copy(ConfigFile, 1, Length(ConfigFile) - 3) + 'AR')^.
           LogLn;
      Dispose(CFG_p);
      Dispose(Header_p);
      Dispose(Echo_p);
      Exit;
    end;

    If (Echo_p^.MsgBasePath[0] <> #0) or (Echo_p^.Board <> 0) then begin
      { Icke-passthrough }
      New(Temp_p);
      Temp_p^.Next := Areas;
      Areas := Temp_p;

      Case OLocal in Echo_p^.Options of
        False: Temp_p^.AreaType := EchoMail;
        True:  Temp_p^.AreaType := Local;
      end;

      If Echo_p^.Board = 0 then
        Temp_p^.Path := 'J' + ASCIZ(@Echo_p^.MsgBasePath) { JAM }
      else
        Temp_p^.Path := 'H' + NumStr(Echo_p^.Board, 3) + HudsonPath; { Hudson }

      Temp_p^.EchoTag := ASCIZ(@Echo_p^.AreaName);

      Temp_p^.Address := CFG_p^.AkaList[Echo_p^.Address].NodeNum;

{$IFDEF DEBUG}
      Writeln(Temp_p^.EchoTag, ' => ', Temp_p^.Path);
{$ENDIF}
    end; { If }
  end;

  Close(FMailAR);

  Dispose(CFG_p);
  Dispose(Header_p);
  Dispose(Echo_p);
End;

{************************************************************************}
{* Klass:       TosserGEcho                                             *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar objektets data                                *}
{* Definition:  Constructor TosserGEcho.Init;                           *}
{************************************************************************}
Constructor TosserGEcho.Init;
Begin
  Tosser.Init;
End;

{************************************************************************}
{* Metod:       Done (destrukt”r)                                       *}
{************************************************************************}
{* Inneh†ll:    Tar bort objektets data                                 *}
{* Definition:  Destructor TosserGEcho.Done;                            *}
{************************************************************************}
Destructor TosserGEcho.Done;
Begin
  Tosser.Done;
End;

{************************************************************************}
{* Metod:       Import                                                  *}
{************************************************************************}
{* Inneh†ll:    Importerar GEchos konfigruationsfiler                   *}
{* Definition:  Procedure TosserGEcho.Import(ConfigFile: String);       *}
{************************************************************************}
Procedure TosserGEcho.Import(ConfigFile: String);
Var
  SetupGE:      File of SETUP_GE;
  AreaFileGE:   File;
  AreaFileName: String;
  CFG_p:        ^SETUP_GE;
  Header_p:     ^AREAFILE_HDR;
  Echo_p:       ^AREAFILE_GE;
  i, NumRead, HeaderSize:   Word;
  HudsonPath:   String;
  Temp_p:       AreaDefinitionPointer;
  arearecsize:  LongInt;
Begin
  New(CFG_p);

  { L„s in SETUP.GE (huvudkonfiguration) }
{$IFDEF DEBUG}
  Writeln('OPENING: ', ConfigFile);
{$ENDIF}
  Assign(SetupGE, ConfigFile);
  {$I-}
  Reset(SetupGE);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + ConfigFile)^.LogLn;
    Dispose(CFG_p);
    Exit;
  end;
  {$I+}
  Read(SetupGE, CFG_p^);
  Close(SetupGE);

  If (CFG_p^.sysrev <> GE_THISREV) then begin
    Log^.LogLine('!')^.LogStr(StrLogTr4 + Configfile)^.LogLn;
    Dispose(CFG_p);
    Exit;
  end;

  HudsonPath := ASCIZ(@CFG_p^.hmbpath);

  AreaFileName := InSameDir(ConfigFile, 'AREAFILE.GE');

  { l„s in AREAFILE.GE (m”tesinst„llningar) }
{$IFDEF DEBUG}
  Writeln('OPENING: ', AreaFileName);
{$ENDIF}
  Assign(AreaFileGE, AreaFileName);
  {$I-}
  Reset(AreaFileGE, 1);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + ConfigFile)^.LogLn;
    Dispose(CFG_p);
    Exit;
  end;
  {$I+}

{$IFDEF DEBUG}
  Writeln('þ Reading header');
{$ENDIF}

  New(Header_p);
  BlockRead(AreaFileGE, Header_p^, SizeOf(Header_p^), NumRead);

  If (NumRead <> SizeOf(Header_p^)) or
     (Header_p^.HdrSize < SizeOf(Header_p^)) or
     (Header_p^.RecSize < SizeOf(Echo_p^)) then begin
    Log^.LogLine('!')^.LogStr(StrLogTr4 + AreaFileName)^.LogLn;
    Dispose(CFG_p);
    Dispose(Header_p);
    Exit;
  end;

  arearecsize := Header_p^.recsize + Header_p^.maxconnections *
                 SizeOf(connection);
  HeaderSize := Header_p^.hdrsize;

  Dispose(Header_p);

  { L„s m”tesdefinitioner ur FMAIL.AR }
  New(Echo_p);
  Seek(AreaFileGE, HeaderSize);
  BlockRead(AreaFileGE, Echo_p^, SizeOf(Echo_p^), NumRead);
  i := 1;
  While NumRead = SizeOf(Echo_p^) do begin
{$IFDEF DEBUG}
    Writeln('þ Reading area');
{$ENDIF}

    If (Echo_p^.areaformat = FORMAT_HMB) or
       (Echo_p^.areaformat = FORMAT_SDM) or
       (Echo_p^.areaformat = FORMAT_JAM) or
       (Echo_p^.areaformat = FORMAT_SQUISH) then begin { K„nt meddelandebasformat }
      New(Temp_p);
      Temp_p^.Next := Areas;
      Areas := Temp_p;

      Case Echo_p^.areatype of
        geECHOMAIL: Temp_p^.AreaType := EchoMail;
        geNETMAIL:  Temp_p^.AreaType := NetMail;
        else        Temp_p^.AreaType := Local;
      end;

      Case Echo_p^.areaformat of
        FORMAT_HMB:   Temp_p^.Path := 'H' + NumStr(Echo_p^.areanumber, 3) +
                      HudsonPath;
        FORMAT_SDM:   Temp_p^.Path := 'F' + ASCIZ(@Echo_p^.Path);
        FORMAT_JAM:   Temp_p^.Path := 'J' + ASCIZ(@Echo_p^.Path);
        FORMAT_SQUISH:Temp_p^.Path := 'S' + ASCIZ(@Echo_p^.Path);
      end;

      Temp_p^.EchoTag := ASCIZ(@Echo_p^.name);

      Temp_p^.Address := CFG_p^.aka[Echo_p^.pkt_origin];

{$IFDEF DEBUG}
      Writeln(Temp_p^.EchoTag, ' => ', Temp_p^.Path);
{$ENDIF}
    end; { If }

    { N„sta post }
    Seek(AreaFileGE, i * arearecsize + HeaderSize);
    BlockRead(AreaFileGE, Echo_p^, SizeOf(Echo_p^), NumRead);
    Inc(i);
  end;

  Close(AreaFileGE);

  Dispose(CFG_p);
  Dispose(Echo_p);

End;
{$ENDIF}

{************************************************************************}
{* Klass:       TosserTerMail                                           *}
{************************************************************************}

{************************************************************************}
{* Metod:       Init (konstrukt”r)                                      *}
{************************************************************************}
{* Inneh†ll:    Initierar objektets data                                *}
{* Definition:  Constructor TosserTerMail.Init;                         *}
{************************************************************************}
Constructor TosserTerMail.Init;
Begin
  Tosser.Init;
End;

{************************************************************************}
{* Metod:       Done (destrukt”r)                                       *}
{************************************************************************}
{* Inneh†ll:    Tar bort objektets data                                 *}
{* Definition:  Destructor TosserTerMail.Done;                          *}
{************************************************************************}
Destructor TosserTerMail.Done;
Begin
  Tosser.Done;
End;

{************************************************************************}
{* Metod:       Import                                                  *}
{************************************************************************}
{* Inneh†ll:    Importerar en konfigurationsfil                         *}
{* Definition:  Procedure TosserTerMail.Import(ConfigFile: String);     *}
{************************************************************************}
Procedure TosserTerMail.Import(ConfigFile: String);
Var
  Conf: Text;
  Line, Keyword, ConfData, Pt1, Pt2, AreaFileName: String;
  TempAddr: AddrType;
  Trav_p, Temp_p: AreaDefinitionPointer;
  ParseSuccess: Boolean;
  Data: TerMailData;
  CurrentUser, NumGroups, i: Byte;
Begin
  Assign(Conf, ConfigFile);
  {$I-}
  Reset(Conf);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + ConfigFile)^.LogLn;
    Exit;
  end;
  {$I+}

{$IFDEF DEBUG}
  Writeln('BEGIN IMPORT OF ', ConfigFile);
{$ENDIF}

  FillChar(TempAddr, SizeOf(TempAddr), #0);
  FillChar(Data, SizeOf(TerMailData), #0);
  CurrentUser := 0;
  NumGroups := 0;
  AreaFileName := 'TM.BBS';

  While not eof(Conf) do begin
    Readln(Conf, Line);
    If (Line[1] <> ';') and (Line[1] <> '%') and
       ParseINI(Line, Keyword, ConfData) then begin
      If Keyword = 'USER' then begin
        CurrentUser := Str2Long(ConfData);
        If CurrentUser > 16 then CurrentUser := 0;      { Max 16 anv„ndare }
{$IFDEF DEBUG}
        Writeln('USER ', CurrentUser);
{$ENDIF}
      end else If Keyword = 'ADDRESS' then begin
        If CurrentUser > 0 then begin
          ParseAddr(ConfData, TempAddr, Data.UserAddress[CurrentUser]);
{$IFDEF DEBUG}
          Writeln('AKA ', CurrentUser, ' ', AddrStr(Data.UserAddress[CurrentUser]));
{$ENDIF}
        end; { If CurrentUser }
      end else If Keyword = 'GROUP' then begin
        If NumGroups < 23 then begin
          Inc(NumGroups);
          With Data.Group[NumGroups] do begin
            ParseINI(ConfData, Pt1, Pt2); { Pt1 = NAME, Pt2 = Days ... }
            GroupName := Pt1;
            ParseINI(Pt2, Pt1, ConfData); { Pt1 = Days, Cfd = Max ...  }
            ParseINI(ConfData, Pt1, Pt2); { Pt1 = Max,  Pt2 = Clean ...}
            ParseINI(Pt2, Pt1, ConfData); { Pt1 = Clean,Cfd = User ... }
            ParseINI(ConfData, Pt1, Pt2); { Pt1 = User, Pt2 = Templ ...}
            User := Str2Long(Pt1);
            If (User = 0) or (User > 16) then
              User := 1;
{$IFDEF DEBUG}
            Writeln('GROUP "', GroupName, '" USER ', User);
{$ENDIF}
          end; { With }
        end; { If NumGroups }
      end else If Keyword = 'DESC' then begin
        New(Temp_p);
        Temp_p^.Next := Areas;
        Areas := Temp_p;
        Temp_p^.AreaType := EchoMail;
        ParseINI(ConfData, Pt1, Pt2);     { Pt1 = tag,  Pt2 = Desc ... }
        Temp_p^.EchoTag := Pt1;
        ParseINI(Pt2, Pt1, ConfData);     { Pt1 = desc, Cfd = Group    }
        Pt1 := UpStr(ConfData);           { gruppnamn }
        For i := 1 to NumGroups do
          If Pt1 = Data.Group[i].GroupName then
            Temp_p^.Address := Data.UserAddress[Data.Group[i].User];
        If Temp_p^.Address.Zone = 0 then
          Temp_p^.Address := Data.UserAddress[1]; { Fallback }
{$IFDEF DEBUG}
        Writeln('TAG ', Temp_p^.EchoTag,
                ' GROUP "', Pt1, '" ',
                ' ADDRESS ', AddrStr(Temp_p^.Address),
                ' TYPE ', Byte(Temp_p^.AreaType));
{$ENDIF}
      end else If Keyword = 'AREAFILE' then begin
        AreaFileName := ConfData;
      end; { If Keyword }
    end; { If valid configline }
  end; { While }
  Close(Conf);

{$IFDEF DEBUG}
  Writeln('END IMPORT OF ', ConfigFile);
{$ENDIF}

  If (AreaFileName[1] <> '\') and (AreaFileName[2] <> ':') then begin
    { Ej absolut s”kv„g, bygg fr†n tm.cfg-filens s”kv„g }
    AreaFileName := InSameDir(ConfigFile, AreaFileName);
  end; { If }

{$IFDEF DEBUG}
  Writeln('BEGIN IMPORT OF ', AreaFileName);
{$ENDIF}

  Assign(Conf, AreaFileName);
  {$I-}
  Reset(Conf);
  If IoResult <> 0 then begin
    Log^.LogLine('!')^.LogStr(StrLogTr3 + AreaFileName)^.LogLn;
    Trav_p := Areas;
    While (Trav_p <> Nil) do begin
{$IFDEF DEBUG}
      Writeln('Deallocating ', Trav_p^.EchoTag);
{$ENDIF}
      Temp_p := Trav_p;
      Trav_p := Temp_p^.Next;
      Dispose(Temp_p);
    end; { While }
    Areas := Nil;
    Exit;
  end; { If }

  While not eof(Conf) do begin
    Readln(Conf, Line);
    If (Line[1] <> ';') and (Line[1] <> '%') and (Line[1] <> '@') and
       ParseINI(Line, Keyword, ConfData) then begin
      { Keyword = s”kv„g }
      {$IFDEF DEBUG}
      Writeln('Before expansion: ', Keyword);
      {$ENDIF}
      If (Keyword[1] <> '\') and (Keyword[2] <> ':') then { ej absolut }
        Keyword := InSameDir(ConfigFile, Keyword);
      {$IFDEF DEBUG}
      Writeln('Before expansion: ', Keyword);
      {$ENDIF}
      ParseINI(ConfData, Pt1, Pt2); { Pt1 = Tag, Pt2 = flags... }
      { Pt1 = echoId, leta p† m”tet i listan }
      Trav_p := Areas;
      While (Trav_p <> Nil) and (Trav_p^.EchoTag <> Pt1) do
        Trav_p := Trav_p^.Next;
      If Trav_p <> Nil then begin
        Trav_p^.Path := 'F' + Keyword; { S”kv„g }
        { Se om vi k”r JAM, Pt2 inneh†ller alla flaggor }
        Repeat { Until not ParseSuccess }
          ParseSuccess := ParseINI(Pt2, Pt1, ConfData);
          If Not ParseSuccess then
            Pt1 := UpStr(Pt2);
          If Pt1 = 'JAM' then
            Trav_p^.Path[1] := 'J'
          else If Pt1 = 'MSG' then
            Trav_p^.Path[1] := 'F';
          Pt2 := ConfData; { Pt2 inneh†ller resten av flaggorna }
        Until not ParseSuccess;

{$IFDEF DEBUG}
        Writeln('TAG ', Trav_p^.EchoTag, ' PATH ', Trav_p^.Path,
                ' ADDRESS ', AddrStr(Trav_p^.Address),
                ' TYPE ', Byte(Trav_p^.AreaType));
{$ENDIF}
      end; { If }
    end; { If valid configline }
  end; { While }

  Close(Conf);

{$IFDEF DEBUG}
  Writeln('END IMPORT OF ', ConfigFile);
{$ENDIF}

End;

end.
