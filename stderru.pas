{************************************************************************}
{* Modul:       StdErrU.Pas                                             *}
{************************************************************************}
{* Inneh�ll:    Deklaration av stderr                                   *}
{************************************************************************}
{* Funktion:    Skapar en fil med namn StdErr kopplad till stderr-      *}
{*              handtaget                                               *}
{************************************************************************}
{* Rutiner:     (inga)                                                  *}
{************************************************************************}
{* Revision:                                                            *}
{*  v1.2  - 1997-04-18 - Utflyttat fr�n Announce.Pas                    *}
{************************************************************************}
Unit StdErrU;

Interface

Var
  StdErr:       Text;

{************************************************************************}

Implementation

Uses
  Dos;

{************************************************************************}
{* Rutin:       main                                                    *}
{************************************************************************}
{* Inneh�ll:    �ppnar StdErr och kopplar det till stderr-handtaget     *}
{* Definition:  -                                                       *}
{************************************************************************}

Begin
  Assign(StdErr, '');           { �ppna StdErr-handtaget }
  Rewrite(StdErr);
  TextRec(StdErr).Handle := 2;
End.
