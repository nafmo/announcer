{************************************************************************}
{* Modul:       Title.Pas                                               *}
{************************************************************************}
{* Inneh†ll:    Titel„ndring                                            *}
{************************************************************************}
{* Funktion:    Rutin f”r att „ndra programtitel under OS/2             *}
{************************************************************************}
{* Rutiner:     SetTitle                                                *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.0  - 1997-07-21 - F”rsta versionen                               *}
{************************************************************************}

Unit Title;

Interface

Procedure SetTitle      (Title: String);

Implementation

Uses
  Dos;

Var
  ProgTitle: String[13];

{************************************************************************}
{* Rutin:       SetTitle                                                *}
{************************************************************************}
{* Inneh†ll:    S„tter sessionstitel till valfri str„ng                 *}
{* Definition:  Procedure SetTitle(Title: String);                      *}
{************************************************************************}

Procedure SetTitle(Title: String);
begin
{$IFDEF MSDOS}
  If Lo(DosVersion) >= 20 then begin
    ProgTitle := Copy(Title, 1, 12) + #0;
    asm
      mov ax, seg ProgTitle
      mov es, ax
      mov di, 1 + offset ProgTitle { skip the Pascal length byte }
      mov ah, 64h
      xor bx,bx
      mov cx, 636ch
      mov dx, 1
      int 21h
    end;
  end;
{$ELSE}{$IFNDEF MSDOS}

{$ENDIF}{$ENDIF}
end;

end.
