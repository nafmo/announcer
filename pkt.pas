{************************************************************************}
{* Modul:       Pkt.Pas                                                 *}
{************************************************************************}
{* Inneh†ll:    Rutiner f”r att hantera PKT-filer                       *}
{************************************************************************}
{* Funktion:    Brp†kar med PKT-filer                                   *}
{************************************************************************}
{* Rutiner:     BuildPacket                                             *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.2  - 1997-06-25 - F”rsta versionen                               *}
{************************************************************************}
Unit Pkt;

{$D-,G+,X+}

Interface

Uses Globals, PktHead;

Procedure BuildPacket(var Global: GlobalDataType;
                      var This: PacketConfigType);

Implementation

Uses AnStr, Dos, StdErrU;

{************************************************************************}
{* Rutin:       BuildPacket                                             *}
{************************************************************************}
{* Inneh†ll:    Bygger ihop MSG-filer till en PKT-fil                   *}
{* Definition: Procedure BuildPacket(var Global: GlobalDataType;        *}
{*                    var This: PacketConfigType);                      *}
{************************************************************************}

Procedure BuildPacket(var Global: GlobalDataType;
                      var This: PacketConfigType);
Var
  PktHead_p:                    ^PKTheader;
  PktMsg_p:                     ^PkdMSG;
  MsgHead_p:                    ^MsgHeader;
  Buff_p:                       ^Buffer;
  Temp:                         Word;
  {$IFDEF MSDOS}
  NumWritten, NumRead:          Word;
  {$ENDIF}{$IFDEF OS2}
  NumWritten, NumRead:          LongWord;
  {$ENDIF}
  PktFile, MsgFile:             File;
  FileSearch:                   SearchRec;
  i:                            Byte;
  LeftToWrite:                  LongInt;
  PktDidExist, ErrorOccured:    Boolean;
Begin
  New(PktHead_p);
  New(PktMsg_p);
  New(MsgHead_p);
  New(Buff_p);
  If (PktHead_p <> nil) and (PktMsg_p <> nil) and (MsgHead_p <> nil) and
     (Buff_p <> nil) then begin
    FileMode := fmReadWrite or fmDenyAll;
    Assign(PktFile, This.PktSpec);
    {$I-}
    PktDidExist := True;
    Reset(PktFile, 1);
    If IOResult <> 0 then begin
      Rewrite(PktFile, 1);
      PktDidExist := False;
    end; { If }
    If IOResult <> 0 then begin
      Writeln(StdErr, StrErrPOp, This.PktSpec);
      Log^.LogLine('-')^.LogStr(StrErrPOp + This.PktSpec)^.LogLn;
    end else begin
      {$I+}
      If PktDidExist then begin
        Seek(PktFile, FileSize(PktFile) - 2);
      end else begin
        FillChar(PktHead_p^, SizeOf(PKTHeader), #0);
        With PktHead_p^ do begin
          QOrgZone := This.PktFrom.Zone;
          OrgZone := This.PktFrom.Zone;
          If Global.Fsc0048 and (This.PktFrom.Point <> 0) then begin
            OrgNet := $ffff;
            Filler := This.PktFrom.Net;
            ProdData := '0048';
          end else
            OrgNet := This.PktFrom.Net;
          OrgNode := This.PktFrom.Node;
          OrgPoint := This.PktFrom.Point;
          QDstZone := This.PktTo.Zone;
          DstZone := This.PktTo.Zone;
          DstNet := This.PktTo.Net;
          DstNode := This.PktTo.Node;
          DstPoint := This.PktTo.Point;
          GetDate(Year, Month, Day, Temp);
          Dec(Month); { Justera m†nadsnummer till 0-11 }
          GetTime(Hour, Min, Sec, Temp);
          PktVer := 2;
          PrdCodL := $fe; { No product ID allocated }
          CapValid := $100;
          CapWord := $1;
          PVMinor := VerMin; { Version }
          PVMajor := VerMaj;
          If Length(This.PktPwd) > 0 then
            For i := 0 to Length(This.PktPwd) - 1 do
              Password[i] := This.PktPwd[i + 1];
{         For i := 0 to 7 do
            If i < Length(This.PktPwd) then
              Password[i] := This.PktPwd[i+1];}
        end; { With PktHead_p^ }
        BlockWrite(PktFile, PktHead_p^, SizeOf(PKTheader), NumWritten);
        Dispose(PktHead_p);
        If NumWritten <> SizeOf(PKTheader) then begin
          Writeln(StdErr, StrErrWri);
          Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
        end; { If }
      end; { If }

      ErrorOccured := False;
      FindFirst(This.MsgSpec + '*.MSG', AnyFile - VolumeId, FileSearch);
      While (DosError = 0) and (Not ErrorOccured) do begin
        {$I-}
        Assign(MsgFile, This.MsgSpec + FileSearch.Name);
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
                DstNet := This.PktTo.Net;
                DstNode := This.PktTo.Node;
              end;
              Attribute := MsgHead_p^.Attribute and 2059;
              For i := 0 to 19 do
                DateTime[i] := MsgHead_p^.DateTime[i];
            end; { With PktMsg_p^ }
            BlockWrite(PktFile, PktMsg_p^, SizeOf(PkdMsg), NumWritten);
            If NumWritten <> SizeOf(PkdMsg) then begin
              Writeln(StdErr, StrErrWri);
              ErrorOccured := True;
              Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
            end; { If NumWritten }
            i := 0;
            While (i < 36) and (MsgHead_p^.ToName[i] <> #0) do
              Inc(i); { Ta reda p† l„ngd p† namnf„ltet }
            BlockWrite(PktFile, MsgHead_p^.ToName, i + 1, NumWritten);
            If NumWritten <> (i + 1) then begin
              Writeln(StdErr, StrErrWri);
              ErrorOccured := True;
              Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
            end; { If NumWritten }
            i := 0;
            While (i < 36) and (MsgHead_p^.FromName[i] <> #0) do
              Inc(i); { Ta reda p† l„ngd p† namnf„ltet }
            BlockWrite(PktFile, MsgHead_p^.FromName, i + 1, NumWritten);
            If NumWritten <> (i + 1) then begin
              Writeln(StdErr, StrErrWri);
              ErrorOccured := True;
              Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
            end; { If NumWritten }
            i := 0;
            While (i < 72) and (MsgHead_p^.Subject[i] <> #0) do
              Inc(i); { Ta reda p† l„ngd p† „mnesf„ltet }
            BlockWrite(PktFile, MsgHead_p^.Subject, i + 1, NumWritten);
            If NumWritten <> (i + 1) then begin
              Writeln(StdErr, StrErrWri);
              ErrorOccured := True;
              Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
            end; { If NumWritten }
            LeftToWrite := FileSize(MsgFile) - SizeOf(MsgHeader);
            While LeftToWrite > SizeOf(Buffer) do begin
              BlockRead(MsgFile, Buff_p^, SizeOf(Buffer){, NumRead});
              BlockWrite(PktFile, Buff_p^, SizeOf(Buffer), NumWritten);
              If NumWritten <> SizeOf(Buffer) then begin
                Writeln(StdErr, StrErrWri);
                ErrorOccured := True;
                Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
              end; { If NumWritten }
              Dec(LeftToWrite, SizeOf(Buffer));
            end; { While }
            BlockRead(MsgFile, Buff_p^, LeftToWrite{, NumRead});
            BlockWrite(PktFile, Buff_p^, LeftToWrite, NumWritten);
            If NumWritten <> LeftToWrite then begin
              Writeln(StdErr, StrErrWri);
              ErrorOccured := True;
              Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
            end;
          end else begin
            Writeln(StdErr, StrErrRea);
            ErrorOccured := True;
            Log^.LogLine('-')^.LogStr(StrErrRea)^.LogLn;
          end; { If NumRead }
          Close(MsgFile);
          If Not ErrorOccured then
            Erase(MsgFile);
        end else begin
          Writeln(StdErr, StrErrMOp, This.MsgSpec + FileSearch.Name);
          Log^.LogLine('-')^.LogStr(StrErrMOp + This.MsgSpec + FileSearch.Name)^.
               LogLn;
        end; { If gick att ”ppna MSG-fil }

        FindNext(FileSearch);
      end; { While not DosError }
      Buff_p^[0] := #0;
      Buff_p^[1] := #0;
      BlockWrite(PktFile, Buff_p^, 2, NumWritten);
      If NumWritten <> 2 then begin
        Writeln(StdErr, StrErrWri);
        Log^.LogLine('-')^.LogStr(StrErrWri)^.LogLn;
      end;
      Close(PktFile);
      Writeln(StrLogPkt, This.PktSpec);
      Log^.LogLine(' ')^.LogStr(StrLogPkt + This.PktSpec)^.LogLn;
    end; { If gick att skapa PktFile }
    Dispose(PktMsg_p);
    Dispose(MsgHead_p);
    Dispose(Buff_p);
    filemode := fmReadOnly or fmDenyNone;
  end else begin { kunde inte allokera }
    Writeln(StdErr, StrErrAll);
    Log^.LogLine('-')^.LogStr(StrErrAll)^.LogLn;
  end;
End;


End.

