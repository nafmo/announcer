{************************************************************************}
{* Modul:       globals.pas                                             *}
{************************************************************************}
{* Inneh†ll:    Definition av globala datatyper och variabler i         *}
{*              Announcer                                               *}
{************************************************************************}
{* Funktion:    Anv„nds av Announcer                                    *}
{************************************************************************}
{* Rutiner:     inga                                                    *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.2  - 1997-06-25 - F”rsta versionen                               *}
{************************************************************************}

Unit Globals;

Interface

Uses Dos, StrUtil, MkGlobT, LogFileU;
{$IFDEF OS2}
Uses Os2Dt;
{$ENDIF}

Const
{$IFDEF MSDOS}
  Version  = 'v1.2';
  VerMaj   = 1;
  VerMin   = 20;
{$ELSE}{$IFDEF OS2}
  Version  = 'OS/2 Beta';
  VerMaj   = 1;
  VerMin   = 20;
{$ENDIF}{$ENDIF}

  fmReadOnly  = $00;
  fmWriteOnly = $01;
  fmReadWrite = $02;

  fmDenyAll   = $10;
  fmDenyWrite = $20;
  fmDenyRead  = $30;
  fmDenyNone  = $40;

Type
{$IFNDEF OS2}
  CompatDateTime = DateTime;
{$ENDIF}
  DataFileRec = Record
                  LastWritten: CompatDateTime;
                  MsgIdString: String[32];
                  MsgIdNum: LongInt;
                end;
  FileOfDataFileRec = File Of DataFileRec;
  MsgType = (Local, NetMail, EchoMail);
  CurrPartType = (Header, MainText, Footer, Finished);
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
  GlobalDataType = record
                     Registration, EchoTossLogFile,
                     JamTossLogPath:                            String;
                     BragLineIntro, TagLineIntro:               String[3];
                     ReplyKludge, PktMode, ForcePID, Fsc0048,
                     NetMailTearline:                           Boolean;
                     MsgIdString:                               String[32];
                     MsgWritten, Ctr:                           Word;
                     Idag:                                      CompatDateTime;
                   end;
  MessageConfigType = record
                        mFrom, mTo, Subj, FName, MsgBas,
                        TagLine, Origin, HeaderFile,
                        FooterFile, CreateFile, EchoTag:        String;
                        AreaType:                               MsgType;
                        CurrentRec:                             DataFileRec;
                        Parts:                                  Byte;
                        Size:                                   LongInt;
                        Charset:                                CharsetType;
                        MsgAttr:                                Attributes;
                        FixedWidth:                             Boolean;
                        Orig, Dest:                             AddrType;
                      end;
  PacketConfigType = record
                        PktSpec, MsgSpec:                       String;
                        PktPwd:                                 String[8];
                        PktFrom, PktTo:                         AddrType;
                     end;

Var
  Log:                  LogFilePointer;
  LogInitialized:       Boolean;
  Name:                 Array[1..10] of string;

Implementation

end.

