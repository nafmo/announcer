{************************************************************************}
{* Modul:       crypt.pas                                               *}
{************************************************************************}
{* Inneh†ll:    Announcer-kodgenererare                                 *}
{************************************************************************}
{* Funktion:    Genererar registreringskod f”r Announcer                *}
{************************************************************************}
{* Rutiner:     RegiCode                                                *}
{*              CheckRegistration                                       *}
{************************************************************************}
{* Revision:                                                            *}
{*        - 1995-10-29 - F”rsta versionen                               *}
{*  v2.0  - 1997-08-10 - Nytt registeringsformat                        *}
{************************************************************************}

Unit Crypt;

Interface

Function  CheckRegistration(FileName: String): String;
Procedure RegiCode         (RegiName: String; Serial: LongInt;
                            Var RegCode: String);

Implementation

Const
  Adder = 14;
  Filler = 72;
  Seed: LongInt = 1;
  CharBase = 48;

{************************************************************************}
{* Rutin:       Rand                                                    *}
{************************************************************************}
{* Inneh†ll:    Framst„ller ett pseudoslumpv„rde                        *}
{* Definition:  Function Rand(max: Byte): Byte;                         *}
{************************************************************************}
Function Rand(max: Byte): Byte;
Begin
  Seed := Seed * 72195 + 5;
  Rand := (Seed shr 16) mod max;
end;

{************************************************************************}
{* Rutin:       RegiCode                                                *}
{************************************************************************}
{* Inneh†ll:    Skapar/kollar registreringskod f”r Announcer            *}
{* Definition:  Procedure RegiCode(RegiName: String;                    *}
{*              Serial: LongInt; Var RegiCode: String);                 *}
{************************************************************************}
Procedure RegiCode(RegiName: String; Serial: LongInt; Var RegCode: String);
Var
  i, c, p: byte;
  ch: char;
  Buf, BufBit: Word;
  WasThere: Boolean;
Begin
  WasThere := True;
  If Length(RegCode) = 0 then begin
    WasThere := False;
    RegCode[0] := #79;
  end;
  If Length(RegCode) <> 79 then begin
    RegCode := ''; { Felaktig l„ngd p† koden }
  end else begin
    Seed := Serial;
    c := Adder;
    p := 1; { Str„ngindex }
    Buf := 0;
    BufBit := 0;
    For i := 0 to 59 do begin
      If i >= Length(RegiName) then
        c := byte(c shl 4) + byte(Rand(5) * (Filler - Length(RegiName)))
      else
        c := byte(c shl 3) or ((c and $e0) shl 5) + byte(RegiName[i]) + Rand(5);
      Buf := (Buf shl 8) or c;
      BufBit := (BufBit shl 8) or $ff;
      While BufBit > $3f do begin
        ch := Char(CharBase + Buf and $3f);
        If not WasThere then
          RegCode[p] := ch
        else If Regcode[p] <> ch then
          RegCode := '';
        Buf := Buf shr 6;
        BufBit := BufBit shr 6;
        Inc(p);
      end;
      Inc(c, adder);
    end;
  end;
end;

{************************************************************************}
{* Rutin:       CheckRegistration                                       *}
{************************************************************************}
{* Inneh†ll:    Se om registreringskoden st„mmer                        *}
{* Definition:  Function CheckRegistration(RegiName, Code: String;      *}
{*              Serial: LongInt): Boolean;                              *}
{************************************************************************}
Function CheckRegistration(FileName: String): String;
Var
  RegiName, Code: String;
  Serial: LongInt;
  T: Text;
Begin
  Assign(T, FileName);
  {$I-}
  Reset(T);
  If IOResult <> 0 then
    CheckRegistration := ''
  else begin
    Readln(T, RegiName);
    Readln(T, Serial);
    Readln(T, Code);
    Close(T);
    If Serial = 0 then
      Code := ''
    else
      RegiCode(RegiName, Serial, Code);
    If Code = '' then
      CheckRegistration := ''
    else
      CheckRegistration := RegiName;
  end;
  {$I+}
end;

end.
